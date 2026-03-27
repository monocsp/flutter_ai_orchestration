import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/agent_provider.dart';
import '../../providers/agent_providers.dart';
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
  String? _sourceDocPath;
  String? _sourceDocContent;
  final Set<String> _selectedAgentIds = {};
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _promptController.text = _defaultPrompt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agentStatus = ref.watch(agentStatusProvider);

    return DropTarget(
      onDragDone: (details) {
        for (final file in details.files) {
          if (file.path.isNotEmpty) {
            _loadSourceDoc(file.path);
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
          _buildDocArea(context),
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
                  .map((status) => _agentCheckbox(status))
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
              onPressed: _sourceDocPath == null ||
                      _selectedAgentIds.isEmpty ||
                      _isStarting
                  ? null
                  : _startParallel,
              icon: _isStarting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.compare_arrows, size: 20),
              label: Text(_isStarting
                  ? '시작 중...'
                  : '병렬 실행 시작 (${_selectedAgentIds.length}개 Agent)'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDocArea(BuildContext context) {
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
          child: _sourceDocPath != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.description_outlined,
                        size: 22, color: Color(0xFF0D9488)),
                    const SizedBox(height: 4),
                    Text(
                      _sourceDocPath!.split(Platform.pathSeparator).last,
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

  Widget _agentCheckbox(AgentInstallStatus status) {
    final isInstalled = status.installed;
    final isChecked = _selectedAgentIds.contains(status.agentId);

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
                  setState(() {
                    if (v == true) {
                      _selectedAgentIds.add(status.agentId);
                    } else {
                      _selectedAgentIds.remove(status.agentId);
                    }
                  });
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
      _loadSourceDoc(result.files.single.path!);
    }
  }

  Future<void> _loadSourceDoc(String path) async {
    try {
      final content = await File(path).readAsString();
      setState(() {
        _sourceDocPath = path;
        _sourceDocContent = content;
      });
    } catch (_) {}
  }

  Future<void> _startParallel() async {
    setState(() => _isStarting = true);
    try {
      final title = _titleController.text;
      final prompt = _promptController.text;

      // 계획서 내용을 프롬프트 앞에 추가
      final fullPrompt = _sourceDocContent != null
          ? '# 기준 문서\n\n$_sourceDocContent\n\n---\n\n$prompt'
          : prompt;

      ref.read(workbenchViewProvider.notifier).setView(WorkbenchView.thread);

      ref.read(threadListProvider.notifier).startParallelComparison(
            agentIds: _selectedAgentIds.toList(),
            promptContent: fullPrompt,
            sourceDocPath: _sourceDocPath,
            customTitle: title,
          );

      _titleController.clear();
    } finally {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _isStarting = false);
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

  static const _defaultPrompt = '''당신은 시니어 소프트웨어 엔지니어입니다.
위의 기준 문서를 분석하고, 아래 항목을 포함한 실행 계획을 작성하세요.

## 필수 출력 항목
1. 입력 유형 판별 (버그/기능/리팩터링 등)
2. 우선순위 보드 (표)
3. 작업 항목별 분석 (관련 파일, 접근 방식, 리스크)
4. 검증 계획
5. 다음 작업자가 첫 30분 안에 볼 것

## 규칙
- 한국어 Markdown으로 작성
- 코드 미검증 시 명시
- 사실과 가정을 분리
''';
}
