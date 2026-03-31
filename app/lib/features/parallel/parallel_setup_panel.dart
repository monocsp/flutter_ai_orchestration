import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/agent_provider.dart';
import '../../providers/agent_providers.dart';
import '../../providers/parallel_setup_providers.dart';
import '../../providers/thread_providers.dart';
import '../workbench/workbench_screen.dart';

class ParallelSetupPanel extends ConsumerStatefulWidget {
  const ParallelSetupPanel({super.key});

  @override
  ConsumerState<ParallelSetupPanel> createState() => _ParallelSetupPanelState();
}

class _ParallelSetupPanelState extends ConsumerState<ParallelSetupPanel> {
  final _titleController = TextEditingController();
  final _promptController = TextEditingController();
  bool _syncingFromProvider = false;

  @override
  void initState() {
    super.initState();
    // Provider에서 초기값 복원
    final state = ref.read(parallelSetupProvider);
    _titleController.text = state.title;
    _promptController.text = state.prompt;

    // 텍스트 변경 시 Provider에 반영
    _titleController.addListener(_onTitleChanged);
    _promptController.addListener(_onPromptChanged);
  }

  void _onTitleChanged() {
    if (!_syncingFromProvider) {
      ref.read(parallelSetupProvider.notifier).setTitle(_titleController.text);
    }
  }

  void _onPromptChanged() {
    if (!_syncingFromProvider) {
      ref.read(parallelSetupProvider.notifier).setPrompt(_promptController.text);
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _promptController.removeListener(_onPromptChanged);
    _titleController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(parallelSetupProvider);
    final agentStatus = ref.watch(agentStatusProvider);

    // Provider 값이 외부에서 변경된 경우 (clearAfterStart 등) 컨트롤러 동기화
    if (_titleController.text != setup.title) {
      _syncingFromProvider = true;
      _titleController.text = setup.title;
      _syncingFromProvider = false;
    }

    return DropTarget(
      onDragDone: (details) {
        for (final file in details.files) {
          if (file.path.isNotEmpty) {
            ref.read(parallelSetupProvider.notifier).setSourceDocument(file.path);
            break;
          }
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title
          _fieldLabel(context, '비교 제목'),
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

          // Source document
          _sectionTitle(context, '계획서'),
          const SizedBox(height: 8),
          _buildDocArea(context, setup.sourceDocPath),
          const SizedBox(height: 16),

          // Prompt
          _sectionTitle(context, '프롬프트'),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _promptController,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Color(0xFF334155),
                height: 1.5,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Agent selection
          _sectionTitle(context, '실행할 AGENT 선택'),
          const SizedBox(height: 8),
          agentStatus.when(
            data: (statuses) => Column(
              children: statuses
                  .where((s) => s.agentId != 'other')
                  .map((status) => _agentCheckbox(status, setup.selectedAgentIds))
                  .toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            ),
            error: (_, _) => Text('Agent 확인 실패',
                style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
          ),

          const SizedBox(height: 24),

          // Start button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: setup.sourceDocPath == null ||
                      setup.selectedAgentIds.isEmpty ||
                      setup.isStarting
                  ? null
                  : _startParallel,
              icon: setup.isStarting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.compare_arrows, size: 20),
              label: Text(setup.isStarting
                  ? '시작 중...'
                  : '병렬 실행 시작 (${setup.selectedAgentIds.length}개 Agent)'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDocArea(BuildContext context, String? sourceDocPath) {
    return InkWell(
      onTap: _pickDocument,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: sourceDocPath != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.description_outlined,
                        size: 22, color: Color(0xFF0D9488)),
                    const SizedBox(height: 4),
                    Text(
                      sourceDocPath.split(Platform.pathSeparator).last,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_file_outlined,
                        size: 24, color: Colors.grey.shade400),
                    const SizedBox(height: 4),
                    Text('파일을 드래그하거나 클릭',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _agentCheckbox(AgentInstallStatus status, Set<String> selectedAgentIds) {
    final isInstalled = status.installed;
    final isChecked = selectedAgentIds.contains(status.agentId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isChecked
            ? const Color(0xFF0D9488).withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: CheckboxListTile(
          dense: true,
          value: isChecked,
          onChanged: isInstalled
              ? (v) {
                  ref.read(parallelSetupProvider.notifier)
                      .toggleAgent(status.agentId, v == true);
                }
              : null,
          activeColor: const Color(0xFF0D9488),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            children: [
              Text(
                status.displayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isInstalled
                      ? const Color(0xFF0F172A)
                      : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isInstalled
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isInstalled ? '설치됨' : '미설치',
                style: TextStyle(
                  fontSize: 10,
                  color: isInstalled
                      ? Colors.grey.shade500
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
          subtitle: status.version != null
              ? Text(status.version!,
                  style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Colors.grey.shade400))
              : null,
        ),
      ),
    );
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      ref.read(parallelSetupProvider.notifier)
          .setSourceDocument(result.files.single.path!);
    }
  }

  Future<void> _startParallel() async {
    final notifier = ref.read(parallelSetupProvider.notifier);
    notifier.setIsStarting(true);
    try {
      final setup = ref.read(parallelSetupProvider);
      final fullPrompt = setup.sourceDocContent != null
          ? '# 기준 문서\n\n${setup.sourceDocContent}\n\n---\n\n${setup.prompt}'
          : setup.prompt;

      // 병렬 실행 시작 (백그라운드)
      ref.read(threadListProvider.notifier).startParallelComparison(
            agentIds: setup.selectedAgentIds.toList(),
            promptContent: fullPrompt,
            sourceDocPath: setup.sourceDocPath,
            customTitle: setup.title,
          );

      notifier.clearAfterStart();

      // 즉시 비교 결과 뷰로 전환
      ref.read(workbenchViewProvider.notifier).setView(
          WorkbenchView.comparison);
    } finally {
      await Future.delayed(const Duration(seconds: 3));
      notifier.setIsStarting(false);
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
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF334155),
      ),
    );
  }
}
