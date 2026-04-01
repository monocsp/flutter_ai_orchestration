import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/agent_provider.dart';
import '../../core/models/orchestration_preset.dart';
import '../../core/models/orchestration_stage.dart';
import '../../core/models/session_config.dart';
import '../../core/models/template_preset.dart';
import '../../core/services/agent_runner_service.dart';
import '../../core/services/agent_detection_service.dart';
import '../../core/services/file_converter_service.dart';
import '../../providers/session_providers.dart';
import '../../providers/agent_providers.dart';
import '../../core/services/sample_template_service.dart';
import '../documents/documents_panel.dart';

class SessionSetupPanel extends ConsumerStatefulWidget {
  const SessionSetupPanel({super.key});

  @override
  ConsumerState<SessionSetupPanel> createState() => _SessionSetupPanelState();
}

class _SessionSetupPanelState extends ConsumerState<SessionSetupPanel> {
  final _titleController = TextEditingController();
  final _riskController = TextEditingController();
  final _outputFormatController = TextEditingController();
  bool _showAdvanced = false;
  bool _riskManuallyEdited = false;
  String _outputFormatMode = '직접입력';
  String? _fileError;
  bool _isConverting = false;
  bool _autoRecommendEnabled = true;
  bool _isRecommending = false;
  String? _modeRecommendation;
  String? _lastRecommendedDocPath; // 이미 추천한 파일 추적

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _riskController.dispose();
    _outputFormatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final agentStatus = ref.watch(agentStatusProvider);

    // 파일이 변경되면 자동 추천 트리거 (드래그앤드롭 포함)
    if (session.sourceDocumentPath != null &&
        session.sourceDocumentPath != _lastRecommendedDocPath &&
        _autoRecommendEnabled &&
        !_isRecommending) {
      _lastRecommendedDocPath = session.sourceDocumentPath;
      Future.microtask(() => _tryAutoRecommendMode());
    }

    return Column(
      children: [
        // 스크롤 영역: 설정들
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title
              _fieldLabel(context, '오케스트레이션 제목'),
              const SizedBox(height: 4),
              TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: '비워두면 자동 번호 부여',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 16),

              // Document upload
              _sectionTitle(context, '계획서'),
              const SizedBox(height: 8),
              _buildDocArea(context, session),
              if (session.sourceDocumentPath == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final path = await SampleTemplateService.createSampleFile(
                          session.outputRootPath,
                        );
                        ref.read(sessionProvider.notifier).setSourceDocument(path);
                      },
                      icon: Icon(Icons.auto_awesome, size: 16, color: Colors.amber.shade700),
                      label: const Text('기본 템플릿으로 시작'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: BorderSide(color: Colors.amber.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),

              // 변환 중 표시
              if (_isConverting)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('파일 변환 중...', style: TextStyle(fontSize: 12, color: Color(0xFF0D9488))),
                    ],
                  ),
                ),

              // 에러 메시지
              if (_fileError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      _fileError!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), height: 1.4),
                    ),
                  ),
                ),

              // 모드 자동추천 체크박스
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20, height: 20,
                      child: Checkbox(
                        value: _autoRecommendEnabled,
                        onChanged: _isRecommending
                            ? null // 추천 진행 중에는 끌 수 없음
                            : (v) {
                                final enabled = v ?? true;
                                setState(() => _autoRecommendEnabled = enabled);
                                final notifier = ref.read(sessionProvider.notifier);
                                notifier.setAutoRecommendEnabled(enabled);
                                if (!enabled) {
                                  notifier.setAutoPersona('');
                                  notifier.setIsAutoRecommending(false);
                                }
                              },
                        activeColor: const Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '모드 자동추천',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // 추천 진행 중 배너
              if (_isRecommending)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue.shade400)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '문서를 분석하여 최적의 모드를 추천하고 있습니다...\n추천 완료 전에도 오케스트레이션을 시작할 수 있습니다.',
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade700, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 자동추천 결과 배너
              if (_modeRecommendation != null && !_isRecommending)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _modeRecommendation!,
                            style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Analysis Mode (자동추천 시 비활성화)
              IgnorePointer(
                ignoring: _autoRecommendEnabled,
                child: Opacity(
                  opacity: _autoRecommendEnabled ? 0.5 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, _autoRecommendEnabled ? '분석 모드 (자동추천됨)' : '분석 모드'),
                      const SizedBox(height: 8),
                      _buildAnalysisModeSelector(session.analysisMode),

                      const SizedBox(height: 16),

                      _fieldLabel(context, '분석 Agent (${_analysisStepLabel(session.stages)})'),
                      const SizedBox(height: 4),
                      _agentDropdown(
                        context,
                        value: session.analysisAgent,
                        agentStatus: agentStatus,
                        onChanged: (a) {
                          if (a != null) ref.read(sessionProvider.notifier).setAnalysisAgent(a);
                        },
                      ),
                      const SizedBox(height: 12),

                      _fieldLabel(context, '검토 Agent (${_critiqueStepLabel(session.stages)})'),
                      const SizedBox(height: 4),
                      _agentDropdown(
                        context,
                        value: session.criticAgent,
                        agentStatus: agentStatus,
                        onChanged: (a) {
                          if (a != null) ref.read(sessionProvider.notifier).setCriticAgent(a);
                        },
                      ),
                      const SizedBox(height: 12),

                      _fieldLabel(context, '비판 강도'),
                      const SizedBox(height: 4),
                      _dropdown<String>(
                        context,
                        value: session.criticismLevel,
                        items: SessionConfig.criticismLevels,
                        labelOf: (s) => s,
                        onChanged: (v) {
                          if (v != null) ref.read(sessionProvider.notifier).setCriticismLevel(v);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Advanced settings (accordion)
              _buildAdvancedSettings(session),

              const SizedBox(height: 8),
            ],
          ),
        ),

      ],
    );
  }

  Widget _buildDocArea(BuildContext context, SessionState session) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _pickDocument,
        child: Center(
          child: session.sourceDocumentPath != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.description_outlined, size: 24, color: Color(0xFF0D9488)),
                    const SizedBox(height: 4),
                    Text(
                      _fileName(session.sourceDocumentPath!),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_file_outlined, size: 28, color: Colors.grey.shade400),
                    const SizedBox(height: 4),
                    Text('파일을 드래그하거나 클릭',
                        style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAnalysisModeSelector(String currentMode) {
    final modes = SessionConfig.analysisModes.entries.toList();
    return Column(
      children: modes.map((entry) {
        final isSelected = entry.key == currentMode;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: isSelected
                ? const Color(0xFF0D9488).withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                final notifier = ref.read(sessionProvider.notifier);
                notifier.setAnalysisMode(entry.key);

                final defaults = SessionConfig.defaultsForMode(entry.key);

                // 우측 패널의 결과 요청 텍스트 연동
                StartPanelController.updateForMode(entry.key);

                if (entry.key == 'custom') {
                  // 직접 설정: 고급 설정 펼치기
                  setState(() => _showAdvanced = true);
                } else {
                  // 프리셋 연동
                  if (defaults.containsKey('templatePreset')) {
                    final preset = TemplatePreset.values.firstWhere(
                      (p) => p.name == defaults['templatePreset'],
                      orElse: () => TemplatePreset.developer,
                    );
                    notifier.setStageTemplatePreset(0, preset, cascadeFromFirst: true);
                  }
                  if (defaults.containsKey('runObjective')) {
                    notifier.setRunObjective(defaults['runObjective']!);
                  }
                  if (defaults.containsKey('criticismLevel')) {
                    notifier.setCriticismLevel(defaults['criticismLevel']!);
                  }
                  if (defaults.containsKey('riskFocus')) {
                    _riskController.text = defaults['riskFocus']!;
                    notifier.setRiskFocus(defaults['riskFocus']!);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 18,
                      color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedSettings(SessionState session) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        initiallyExpanded: _showAdvanced,
        onExpansionChanged: (v) => setState(() => _showAdvanced = v),
        title: Text(
          '고급 설정',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 1.2,
          ),
        ),
        children: [
          _fieldLabel(context, '프리셋'),
          const SizedBox(height: 4),
          _dropdown<OrchestrationPreset>(
            context,
            value: session.preset,
            items: OrchestrationPreset.defaults,
            labelOf: (p) => p.name,
            onChanged: (p) {
              if (p != null) ref.read(sessionProvider.notifier).setPreset(p);
            },
          ),
          const SizedBox(height: 12),

          _fieldLabel(context, '실행 목적'),
          const SizedBox(height: 4),
          _dropdown<String>(
            context,
            value: session.runObjective,
            items: SessionConfig.runObjectives,
            labelOf: (s) => s,
            onChanged: (v) {
              if (v != null) {
                ref.read(sessionProvider.notifier).setRunObjective(v);
                if (!_riskManuallyEdited) {
                  final newDefault = SessionConfig.defaultRiskFocus(v);
                  _riskController.text = newDefault;
                  ref.read(sessionProvider.notifier).setRiskFocus(newDefault);
                }
              }
            },
          ),
          const SizedBox(height: 12),

          _fieldLabel(context, '리스크 포커스'),
          const SizedBox(height: 4),
          TextField(
            controller: _riskController,
            style: const TextStyle(fontSize: 13),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: '비워두면 AI가 자동 결정',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
            onChanged: (v) {
              _riskManuallyEdited = true;
              ref.read(sessionProvider.notifier).setRiskFocus(v);
            },
          ),
          const SizedBox(height: 12),

          _fieldLabel(context, '결과 형식'),
          const SizedBox(height: 4),
          _outputFormatSelector(context),
          const SizedBox(height: 12),

          _fieldLabel(context, '참고 프로젝트 루트'),
          const SizedBox(height: 4),
          _pathSelector(
            context,
            value: session.projectRootPath,
            hint: '(선택 사항)',
            onTap: () async {
              final result = await FilePicker.platform.getDirectoryPath();
              if (result != null) {
                ref.read(sessionProvider.notifier).setProjectRoot(result);
              }
            },
          ),
          const SizedBox(height: 12),

          _fieldLabel(context, '출력 루트 경로'),
          const SizedBox(height: 4),
          _pathSelector(
            context,
            value: session.outputRootPath,
            hint: 'output/',
            onTap: () async {
              final result = await FilePicker.platform.getDirectoryPath();
              if (result != null) {
                ref.read(sessionProvider.notifier).setOutputRoot(result);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _outputFormatSelector(BuildContext context) {
    final presets = SessionConfig.outputFormats.where((f) => f != '자동').toList();
    final dropdownItems = ['직접입력', ...presets];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: dropdownItems.contains(_outputFormatMode) ? _outputFormatMode : '직접입력',
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          items: dropdownItems
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item == '직접입력' ? const Color(0xFF0D9488) : const Color(0xFF0F172A),
                        fontWeight: item == '직접입력' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _outputFormatMode = v;
              if (v != '직접입력') {
                _outputFormatController.text = v;
                ref.read(sessionProvider.notifier).setOutputFormat(v);
              }
            });
          },
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _outputFormatController,
          style: const TextStyle(fontSize: 13),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: '비워두면 AI가 자동 결정',
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
          onChanged: (v) {
            if (_outputFormatMode != '직접입력') {
              setState(() => _outputFormatMode = '직접입력');
            }
            ref.read(sessionProvider.notifier).setOutputFormat(v);
          },
        ),
      ],
    );
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: FileConverterService.pickerExtensions,
    );
    if (result != null && result.files.single.path != null) {
      await _loadFile(result.files.single.path!);
    }
  }

  Future<void> _loadFile(String path) async {
    setState(() {
      _fileError = null;
      _isConverting = false;
    });

    if (!FileConverterService.isSupported(path)) {
      setState(() {
        _fileError = '지원하지 않는 파일 형식입니다.\n지원 형식: ${FileConverterService.pickerExtensions.map((e) => '.$e').join(', ')}';
      });
      return;
    }

    if (FileConverterService.isTextFormat(path)) {
      await ref.read(sessionProvider.notifier).setSourceDocument(path);
      return;
    }

    // 바이너리 파일: 변환 필요
    setState(() => _isConverting = true);

    final convertResult = await FileConverterService.convertToText(path);

    if (!mounted) return;

    if (convertResult.success && convertResult.content != null) {
      // 변환된 내용을 임시 md 파일로 저장
      final session = ref.read(sessionProvider);
      final outputDir = session.outputRootPath;
      final dir = Directory(outputDir);
      if (!await dir.exists()) await dir.create(recursive: true);

      final baseName = path.split(Platform.pathSeparator).last;
      final mdPath = '$outputDir${Platform.pathSeparator}${baseName}_converted.md';
      await File(mdPath).writeAsString(convertResult.content!);

      ref.read(sessionProvider.notifier).setSourceDocument(mdPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${convertResult.originalFormat} 파일이 텍스트로 변환되었습니다'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() {
        _fileError = convertResult.error ?? '파일 변환에 실패했습니다.';
      });
    }

    setState(() => _isConverting = false);
  }

  void _setRecommending(bool value) {
    if (mounted) {
      setState(() => _isRecommending = value);
      ref.read(sessionProvider.notifier).setIsAutoRecommending(value);
    }
  }

  /// 문서 업로드 후 설치된 Agent로 분석 모드를 자동 추천
  Future<void> _tryAutoRecommendMode() async {
    if (!_autoRecommendEnabled) return;

    final session = ref.read(sessionProvider);
    final content = session.sourceDocumentContent;
    debugPrint('[MODE_RECOMMEND] content length: ${content?.length ?? 0}');
    if (content == null || content.isEmpty) return;

    _setRecommending(true);
    setState(() {
      _modeRecommendation = null;
    });

    // 설치된 Agent 찾기
    final detection = AgentDetectionService();
    final statuses = await detection.detectAll();
    const priority = ['claude', 'gemini', 'codex'];
    String? availableAgent;
    for (final id in priority) {
      if (statuses.any((s) => s.agentId == id && s.installed)) {
        availableAgent = id;
        break;
      }
    }

    debugPrint('[MODE_RECOMMEND] available agent: $availableAgent');
    if (availableAgent == null) {
      _setRecommending(false);
      return;
    }

    // 문서 첫 500자로 경량 추천
    final preview = content.length > 500 ? content.substring(0, 500) : content;
    final prompt = SessionConfig.buildModeRecommendPrompt(preview);

    debugPrint('[MODE_RECOMMEND] calling $availableAgent...');
    final runner = AgentRunnerService();
    final result = await runner.run(agentId: availableAgent, promptContent: prompt);

    debugPrint('[MODE_RECOMMEND] success: ${result.success}, output: ${result.output.length} chars');
    if (!mounted || !result.success) {
      _setRecommending(false);
      return;
    }

    try {
      final output = result.output;
      final jsonMatch = RegExp(r'\{[\s\S]*?\}').firstMatch(output);
      if (jsonMatch == null) return;

      final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final mode = parsed['mode'] as String?;
      final reason = parsed['reason'] as String?;
      final resultRequest = parsed['resultRequest'] as String?;

      if (mode != null) {
        final notifier = ref.read(sessionProvider.notifier);
        final customModeName = parsed['customModeName'] as String?;

        // 결과 요청 자동 채우기
        if (resultRequest != null && resultRequest.isNotEmpty) {
          StartPanelController.userRequestController.text = resultRequest;
          notifier.setUserResultRequest(resultRequest);
        }

        if (SessionConfig.analysisModes.containsKey(mode)) {
          // 기존 모드에 있는 경우
          notifier.setAnalysisMode(mode);

          final defaults = SessionConfig.defaultsForMode(mode);
          if (defaults.containsKey('templatePreset')) {
            final preset = TemplatePreset.values.firstWhere(
              (p) => p.name == defaults['templatePreset'],
              orElse: () => TemplatePreset.developer,
            );
            notifier.setStageTemplatePreset(0, preset, cascadeFromFirst: true);
          }
          if (defaults.containsKey('runObjective')) notifier.setRunObjective(defaults['runObjective']!);
          if (defaults.containsKey('criticismLevel')) notifier.setCriticismLevel(defaults['criticismLevel']!);
          if (defaults.containsKey('riskFocus')) {
            _riskController.text = defaults['riskFocus']!;
            notifier.setRiskFocus(defaults['riskFocus']!);
          }

          StartPanelController.updateForMode(mode);
          notifier.setAutoPersona('UI에서 자동추천 완료: ${SessionConfig.analysisModes[mode]}');

          _setRecommending(false);
          if (mounted) {
            setState(() {
              _modeRecommendation = '자동추천되었습니다: ${SessionConfig.analysisModes[mode]}${reason != null ? ' - $reason' : ''}';
            });
          }
        } else {
          // 기존 모드에 없는 경우 → 직접 설정으로 전환
          notifier.setAnalysisMode('custom');
          final displayName = customModeName ?? mode;
          notifier.setAutoPersona('UI에서 자동추천 완료 (커스텀): $displayName');

          _setRecommending(false);
          if (mounted) {
            setState(() {
              _showAdvanced = true;
              _modeRecommendation = '자동추천되었습니다: $displayName (직접 설정 모드)${reason != null ? ' - $reason' : ''}';
            });
          }
        }
      } else {
        _setRecommending(false);
      }
    } catch (_) {
      _setRecommending(false);
    }
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: const Color(0xFF334155),
      ),
    );
  }

  Widget _pathSelector(BuildContext context, {String? value, required String hint, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  fontSize: 13,
                  color: value != null ? const Color(0xFF0F172A) : Colors.grey.shade400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.folder_open, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _dropdown<T>(BuildContext context, {required T value, required List<T> items, required String Function(T) labelOf, required ValueChanged<T?> onChanged}) {
    return DropdownButtonFormField<T>(
      initialValue: items.contains(value) ? value : null,
      isExpanded: true,
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
      items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(labelOf(item), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _agentDropdown(BuildContext context, {required AgentProvider value, required AsyncValue<List<AgentInstallStatus>> agentStatus, required ValueChanged<AgentProvider?> onChanged}) {
    return DropdownButtonFormField<AgentProvider>(
      initialValue: AgentProvider.builtIn.contains(value) ? value : null,
      isExpanded: true,
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
      items: AgentProvider.builtIn.map((agent) {
        final status = agentStatus.whenOrNull(
          data: (list) => list.where((s) => s.agentId == agent.id).firstOrNull,
        );
        final installed = status?.installed ?? false;
        final label = agent.id == 'other'
            ? agent.displayName
            : '${agent.displayName}${installed ? '' : ' (미설치)'}';
        return DropdownMenuItem<AgentProvider>(value: agent, child: Text(label, overflow: TextOverflow.ellipsis));
      }).toList(),
      onChanged: onChanged,
    );
  }

  String _fileName(String path) => path.split(Platform.pathSeparator).last;

  String _analysisStepLabel(List<OrchestrationStage> stages) {
    final steps = stages
        .where((s) => s.enabled && s.role == StageRole.analysis)
        .map((s) => 'Step ${s.stepNumber}')
        .toList();
    return steps.isEmpty ? '' : steps.join(', ');
  }

  String _critiqueStepLabel(List<OrchestrationStage> stages) {
    final steps = stages
        .where((s) => s.enabled && s.role == StageRole.critique)
        .map((s) => 'Step ${s.stepNumber}')
        .toList();
    return steps.isEmpty ? '' : steps.join(', ');
  }
}
