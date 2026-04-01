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
  String? _modeRecommendation; // AI 추천 모드 안내 메시지

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

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // AI 모드 추천 안내
              if (_modeRecommendation != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: Colors.green.shade600),
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

              // Analysis Mode
              _sectionTitle(context, '분석 모드'),
              const SizedBox(height: 8),
              _buildAnalysisModeSelector(session.analysisMode),

              const SizedBox(height: 16),

              // Agent selection + Criticism level (always visible)
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
      ref.read(sessionProvider.notifier).setSourceDocument(path);
      _tryAutoRecommendMode();
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
      _tryAutoRecommendMode();

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

  /// 문서 업로드 후 설치된 Agent로 분석 모드를 자동 추천
  Future<void> _tryAutoRecommendMode() async {
    final session = ref.read(sessionProvider);
    final content = session.sourceDocumentContent;
    if (content == null || content.isEmpty) return;

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

    if (availableAgent == null) return; // Agent 없으면 추천 안 함

    // 문서 첫 500자로 경량 추천
    final preview = content.length > 500 ? content.substring(0, 500) : content;
    final prompt = SessionConfig.buildModeRecommendPrompt(preview);

    final runner = AgentRunnerService();
    final result = await runner.run(agentId: availableAgent, promptContent: prompt);

    if (!mounted || !result.success) return;

    try {
      final output = result.output;
      final jsonMatch = RegExp(r'\{[\s\S]*?\}').firstMatch(output);
      if (jsonMatch == null) return;

      final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final mode = parsed['mode'] as String?;
      final reason = parsed['reason'] as String?;

      if (mode != null && SessionConfig.analysisModes.containsKey(mode)) {
        final notifier = ref.read(sessionProvider.notifier);
        notifier.setAnalysisMode(mode);

        // 모드에 따른 설정 연동
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

        // 기본 결과 요청 채우기
        StartPanelController.updateForMode(mode);

        if (mounted) {
          setState(() {
            _modeRecommendation = '${SessionConfig.analysisModes[mode]} 모드를 추천합니다${reason != null ? ': $reason' : ''}';
          });
        }
      }
    } catch (_) {
      // 파싱 실패 시 무시
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
