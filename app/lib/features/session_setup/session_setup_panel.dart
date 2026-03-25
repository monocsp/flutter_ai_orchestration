import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/agent_provider.dart';
import '../../core/models/orchestration_preset.dart';
import '../../core/models/session_config.dart';
import '../../providers/session_providers.dart';
import '../../providers/agent_providers.dart';

class SessionSetupPanel extends ConsumerStatefulWidget {
  const SessionSetupPanel({super.key});

  @override
  ConsumerState<SessionSetupPanel> createState() => _SessionSetupPanelState();
}

class _SessionSetupPanelState extends ConsumerState<SessionSetupPanel> {
  bool _isDragging = false;
  final _riskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _riskController.text = '공통 컴포넌트 영향, 상태 관리, 라이프사이클, 회귀 위험';
  }

  @override
  void dispose() {
    _riskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final agentStatus = ref.watch(agentStatusProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section: Document Input
        _sectionTitle(context, 'INPUT'),
        const SizedBox(height: 8),
        DropTarget(
          onDragEntered: (_) => setState(() => _isDragging = true),
          onDragExited: (_) => setState(() => _isDragging = false),
          onDragDone: (details) {
            setState(() => _isDragging = false);
            for (final file in details.files) {
              if (file.path.endsWith('.md') || file.path.endsWith('.txt')) {
                ref.read(sessionProvider.notifier).setSourceDocument(file.path);
              }
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 100,
            decoration: BoxDecoration(
              color: _isDragging
                  ? const Color(0xFF0D9488).withValues(alpha: 0.08)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDragging
                    ? const Color(0xFF0D9488)
                    : const Color(0xFFE2E8F0),
                width: _isDragging ? 2 : 1,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDocument,
              child: Center(
                child: session.sourceDocumentPath != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description_outlined,
                              size: 24, color: Color(0xFF0D9488)),
                          const SizedBox(height: 4),
                          Text(
                            _fileName(session.sourceDocumentPath!),
                            style: theme.textTheme.bodyMedium?.copyWith(
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
                          Icon(Icons.upload_file_outlined,
                              size: 28, color: Colors.grey.shade400),
                          const SizedBox(height: 4),
                          Text(
                            'Markdown 파일을 드래그하거나 클릭',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Project root
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

        // Output root
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

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        // Section: Orchestration
        _sectionTitle(context, 'ORCHESTRATION'),
        const SizedBox(height: 12),

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

        _fieldLabel(context, '분석 Agent (Step 1, 3, 5)'),
        const SizedBox(height: 4),
        _agentDropdown(
          context,
          value: session.analysisAgent,
          agentStatus: agentStatus,
          onChanged: (a) {
            if (a != null) {
              ref.read(sessionProvider.notifier).setAnalysisAgent(a);
            }
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
            if (a != null) {
              ref.read(sessionProvider.notifier).setCriticAgent(a);
            }
          },
        ),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        // Section: Settings
        _sectionTitle(context, 'SETTINGS'),
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
            }
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
            if (v != null) {
              ref.read(sessionProvider.notifier).setCriticismLevel(v);
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
          onChanged: (v) =>
              ref.read(sessionProvider.notifier).setRiskFocus(v),
        ),

        const SizedBox(height: 12),

        _fieldLabel(context, '결과 형식'),
        const SizedBox(height: 4),
        _dropdown<String>(
          context,
          value: session.outputFormat,
          items: SessionConfig.outputFormats,
          labelOf: (s) => s,
          onChanged: (v) {
            if (v != null) {
              ref.read(sessionProvider.notifier).setOutputFormat(v);
            }
          },
        ),

        const SizedBox(height: 24),

        // Generate button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: session.sourceDocumentPath == null || session.isGenerating
                ? null
                : () async {
                    try {
                      final artifact = await ref
                          .read(sessionProvider.notifier)
                          .generateSession();
                      if (artifact != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('세션 생성 완료: ${artifact.sessionDirPath}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
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
                    }
                  },
            icon: session.isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(session.isGenerating ? '생성 중...' : '세션 생성'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      ref
          .read(sessionProvider.notifier)
          .setSourceDocument(result.files.single.path!);
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

  Widget _pathSelector(
    BuildContext context, {
    String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
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
                  color: value != null
                      ? const Color(0xFF0F172A)
                      : Colors.grey.shade400,
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

  Widget _dropdown<T>(
    BuildContext context, {
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: items.contains(value) ? value : null,
      isExpanded: true,
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(labelOf(item), overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _agentDropdown(
    BuildContext context, {
    required AgentProvider value,
    required AsyncValue<List<AgentInstallStatus>> agentStatus,
    required ValueChanged<AgentProvider?> onChanged,
  }) {
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
        return DropdownMenuItem<AgentProvider>(
          value: agent,
          child: Text(label, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  String _fileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }
}
