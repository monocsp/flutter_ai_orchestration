import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/agent_provider.dart';
import '../../core/models/orchestration_preset.dart';
import '../../core/models/session_config.dart';
import '../../providers/session_providers.dart';
import '../../providers/agent_providers.dart';
import '../../providers/thread_providers.dart';
import '../../core/services/sample_template_service.dart';
import '../workbench/workbench_screen.dart';

class SessionSetupPanel extends ConsumerStatefulWidget {
  const SessionSetupPanel({super.key});

  @override
  ConsumerState<SessionSetupPanel> createState() => _SessionSetupPanelState();
}

class _SessionSetupPanelState extends ConsumerState<SessionSetupPanel> {
  final _titleController = TextEditingController();
  final _userRequestController = TextEditingController();
  final _riskController = TextEditingController();
  final _outputFormatController = TextEditingController();
  bool _isStarting = false;
  bool _showAdvanced = false;
  bool _riskManuallyEdited = false;
  String _outputFormatMode = '직접입력';

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider);
    _userRequestController.text = session.userResultRequest;
    _userRequestController.addListener(() {
      ref.read(sessionProvider.notifier).setUserResultRequest(_userRequestController.text);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _userRequestController.dispose();
    _riskController.dispose();
    _outputFormatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final agentStatus = ref.watch(agentStatusProvider);

    return ListView(
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

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        // Analysis Mode
        _sectionTitle(context, '분석 모드'),
        const SizedBox(height: 8),
        _buildAnalysisModeSelector(session.analysisMode),

        const SizedBox(height: 16),

        // Agent selection + Criticism level (always visible)
        _fieldLabel(context, '분석 Agent (Step 1, 3, 5)'),
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

        _fieldLabel(context, '검토 Agent (Step 2, 4)'),
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

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        // User result request
        _sectionTitle(context, '원하는 결과 요청'),
        const SizedBox(height: 4),
        Text(
          'AI에게 추가로 요청하고 싶은 사항을 자유롭게 작성하세요.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: _userRequestController,
            maxLines: null,
            expands: true,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF334155),
              height: 1.5,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              hintText: '예: 체크리스트 형태로 정리해주세요, 표보다 불릿 선호',
              hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Advanced settings (accordion)
        _buildAdvancedSettings(session),

        const SizedBox(height: 16),

        // Estimated time
        _estimatedTimeInfo(session.stages.where((s) => s.enabled).length),

        const SizedBox(height: 12),

        // Start button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: session.sourceDocumentPath == null ||
                    session.isGenerating ||
                    _isStarting
                ? null
                : () async {
                    setState(() => _isStarting = true);
                    try {
                      final title = _titleController.text;
                      ref.read(workbenchViewProvider.notifier).setView(WorkbenchView.thread);
                      _titleController.clear();
                      ref.read(threadListProvider.notifier)
                          .startOrchestration(customTitle: title);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('오류: $e'),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } finally {
                      await Future.delayed(const Duration(seconds: 3));
                      if (mounted) setState(() => _isStarting = false);
                    }
                  },
            icon: _isStarting || session.isGenerating
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(_isStarting || session.isGenerating ? '시작 중...' : '오케스트레이션 시작'),
          ),
        ),
        const SizedBox(height: 16),
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
                ref.read(sessionProvider.notifier).setAnalysisMode(entry.key);
                // 분석 모드에 따른 기본값 적용
                final defaults = SessionConfig.defaultsForMode(entry.key);
                if (defaults.containsKey('riskFocus') && !_riskManuallyEdited) {
                  _riskController.text = defaults['riskFocus']!;
                  ref.read(sessionProvider.notifier).setRiskFocus(defaults['riskFocus']!);
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

  Widget _estimatedTimeInfo(int enabledStageCount) {
    const autoAnalysisMin = 2;
    const perStageMaxMin = 20;
    const perStageTypicalMin = 5;

    final maxMinutes = autoAnalysisMin + (enabledStageCount * perStageMaxMin);
    final typicalMinutes = autoAnalysisMin + (enabledStageCount * perStageTypicalMin);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 14, color: Colors.blue.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '예상 소요 시간: 약 $typicalMinutes분 ~ 최대 $maxMinutes분 ($enabledStageCount단계)',
              style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      ref.read(sessionProvider.notifier).setSourceDocument(result.files.single.path!);
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
}
