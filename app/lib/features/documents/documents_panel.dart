import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/session_config.dart';
import '../../providers/session_providers.dart';
import '../../providers/thread_providers.dart';
import '../workbench/workbench_screen.dart';
import 'markdown_viewer.dart';

class DocumentsPanel extends ConsumerStatefulWidget {
  const DocumentsPanel({super.key});

  @override
  ConsumerState<DocumentsPanel> createState() => _DocumentsPanelState();
}

class _DocumentsPanelState extends ConsumerState<DocumentsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedFilePath;
  String? _selectedFileContent;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectFile(String path) async {
    try {
      final content = await File(path).readAsString();
      setState(() {
        _selectedFilePath = path;
        _selectedFileContent = content;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final artifact = session.lastArtifact;

    // 오케스트레이션 시작 전이면 결과 요청 + 시작 버튼
    if (artifact == null) {
      final view = ref.watch(workbenchViewProvider);
      final threadState = ref.watch(threadListProvider);
      // thread view에 진입했고 스레드가 있으면 → 준비 중 화면
      if (view == WorkbenchView.thread && threadState.threads.isNotEmpty) {
        return _buildPreparingPanel(session);
      }
      return _buildStartPanel(context, session);
    }

    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: '입력/프롬프트'),
              Tab(text: '결과'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInputTab(session, artifact),
              _buildResultsTab(session, artifact),
            ],
          ),
        ),
      ],
    );
  }

  /// 입력/프롬프트 탭: 계획서 + 세션 요약 + 프롬프트 파일들 + 실행 가이드
  Widget _buildInputTab(SessionState session, dynamic artifact) {
    final files = <_FileEntry>[];

    // 1) 계획서 (기준 문서)
    if (session.sourceDocumentPath != null) {
      files.add(_FileEntry(
        path: session.sourceDocumentPath!,
        label: '계획서',
        icon: Icons.description,
        color: const Color(0xFF0D9488),
      ));
    }

    // 2) 세션 파일들 (프롬프트 + 가이드)
    if (artifact != null) {
      files.add(_FileEntry(
        path: artifact.sessionSummaryPath,
        label: '세션 요약',
        icon: Icons.summarize_outlined,
      ));
      for (final p in artifact.promptPaths) {
        final name = p.split(Platform.pathSeparator).last;
        files.add(_FileEntry(
          path: p,
          label: name,
          icon: Icons.article_outlined,
          color: const Color(0xFF6366F1),
        ));
      }
      files.add(_FileEntry(
        path: artifact.executionGuidePath,
        label: '실행 가이드',
        icon: Icons.play_lesson_outlined,
      ));
    }

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              '입력 문서가 없습니다',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return _fileListWithPreview(files);
  }

  /// 결과 탭: AI가 생성한 result 파일만
  Widget _buildResultsTab(SessionState session, dynamic artifact) {
    if (artifact == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              '생성된 결과가 없습니다',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final files = <_FileEntry>[];
    for (final p in artifact.resultPlaceholderPaths) {
      final name = p.split(Platform.pathSeparator).last;
      files.add(_FileEntry(
        path: p,
        label: name,
        icon: Icons.edit_note,
        color: const Color(0xFF22C55E),
      ));
    }

    return Column(
      children: [
        // Session path + folder button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFFF1F5F9),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  artifact.sessionDirPath,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF475569),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.folder_open, size: 18),
                tooltip: '폴더 열기',
                onPressed: () => _openFolder(artifact.sessionDirPath),
              ),
            ],
          ),
        ),
        // 결과 요청 방향 표시
        if (session.userResultRequest.isNotEmpty)
          _buildResultDirectionBanner(session.userResultRequest),
        Expanded(child: _fileListWithPreview(files)),
      ],
    );
  }

  /// 결과 탭 상단: 결과 요청 방향 배너
  Widget _buildResultDirectionBanner(String resultRequest) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF4),
        border: Border(bottom: BorderSide(color: Color(0xFFBBF7D0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined,
                  size: 14, color: Color(0xFF16A34A)),
              const SizedBox(width: 6),
              Text(
                '결과 방향',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF166534),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            resultRequest,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF166534),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 파일 리스트 + 미리보기 공통 위젯
  Widget _fileListWithPreview(List<_FileEntry> files) {
    return Column(
      children: [
        // File list
        Expanded(
          flex: 2,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final entry = files[index];
              final isSelected = entry.path == _selectedFilePath;
              return ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor:
                    const Color(0xFF0D9488).withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                leading: Icon(
                  entry.icon,
                  size: 18,
                  color: isSelected
                      ? const Color(0xFF0D9488)
                      : (entry.color ?? Colors.grey.shade400),
                ),
                title: Text(
                  entry.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _selectFile(entry.path),
              );
            },
          ),
        ),
        const Divider(height: 1),
        // Preview
        Expanded(
          flex: 3,
          child: _selectedFileContent != null
              ? MarkdownViewer(content: _selectedFileContent!)
              : Center(
                  child: Text(
                    '파일을 선택하면 미리보기가 표시됩니다',
                    style:
                        TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ),
        ),
      ],
    );
  }

  /// 오케스트레이션 시작 직후 (모드추천/설정분석 중) 준비 화면
  Widget _buildPreparingPanel(SessionState session) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: '입력/프롬프트'),
              Tab(text: '결과'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 입력 탭: 계획서만 클릭 가능 + 안내 메시지
              _buildPreparingInputTab(session),
              // 결과 탭: 결과 요청이 확정되면 보여주기
              _buildPreparingResultTab(session),
            ],
          ),
        ),
      ],
    );
  }

  /// 준비 중 입력 탭: 계획서만 클릭 가능, 프롬프트 자리는 비활성화 안내
  Widget _buildPreparingInputTab(SessionState session) {
    final files = <_FileEntry>[];

    if (session.sourceDocumentPath != null) {
      files.add(_FileEntry(
        path: session.sourceDocumentPath!,
        label: '계획서',
        icon: Icons.description,
        color: const Color(0xFF0D9488),
      ));
    }

    return Column(
      children: [
        // 클릭 가능한 계획서
        if (files.isNotEmpty)
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                // 계획서 파일
                ...files.map((entry) {
                  final isSelected = entry.path == _selectedFilePath;
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor:
                        const Color(0xFF0D9488).withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    leading: Icon(
                      entry.icon,
                      size: 18,
                      color: isSelected
                          ? const Color(0xFF0D9488)
                          : (entry.color ?? Colors.grey.shade400),
                    ),
                    title: Text(
                      entry.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    onTap: () => _selectFile(entry.path),
                  );
                }),
                const SizedBox(height: 8),
                // 비활성화된 프롬프트 안내
                Tooltip(
                  message: '설정 분석이 완료되면 프롬프트가 생성됩니다',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '설정 분석 후 프롬프트가 생성됩니다',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (files.isNotEmpty) const Divider(height: 1),
        // 미리보기
        Expanded(
          flex: 3,
          child: _selectedFileContent != null
              ? MarkdownViewer(content: _selectedFileContent!)
              : Center(
                  child: Text(
                    '파일을 선택하면 미리보기가 표시됩니다',
                    style:
                        TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ),
        ),
      ],
    );
  }

  /// 준비 중 결과 탭: 결과 요청이 확정되면 미리 보여줌
  Widget _buildPreparingResultTab(SessionState session) {
    final resultRequest = session.userResultRequest;

    // 아직 결과 요청이 비어있으면 → 분석 중 스피너
    if (resultRequest.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 16),
            Text(
              '설정 분석 중입니다...\n결과 요청이 자동으로 결정됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // 결과 요청이 확정됨 → 내용 표시
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(Icons.assignment_outlined,
                  size: 20, color: const Color(0xFF0D9488)),
              const SizedBox(width: 8),
              const Text(
                '최종 결과물 방향',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '아래 내용을 기반으로 각 단계의 분석이 진행됩니다.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),

          // 결과 요청 내용
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  resultRequest,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF166534),
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 하단 안내
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '곧 1차 분석이 시작됩니다...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isStarting = false;

  Widget _buildStartPanel(BuildContext context, SessionState session) {
    StartPanelController.ensureInit(ref);

    final enabledCount = session.stages.where((s) => s.enabled).length;
    final modeName = SessionConfig.analysisModes[session.analysisMode] ?? session.analysisMode;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.edit_note, size: 20, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(
                '원하는 결과 요청',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '최종 결과물에 포함할 내용을 자유롭게 작성하세요. 분석 모드에 따라 기본값이 제공됩니다.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400, height: 1.4),
          ),
          const SizedBox(height: 12),

          // Text field (expanded)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: StartPanelController.userRequestController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                  hintText: '예: 체크리스트 형태로 정리해주세요, 표보다 불릿 선호',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.blue.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$modeName | $enabledCount단계 | 예상 소요시간 약 ${2 + enabledCount * 5}분 ~ 최대 ${2 + enabledCount * 20}분',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Start button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: session.sourceDocumentPath == null ||
                      session.isGenerating ||
                      _isStarting
                  ? null
                  : () async {
                      setState(() => _isStarting = true);
                      try {
                        // 모드 자동추천 안내
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('모드 자동추천한 설정으로 오케스트레이션이 시작됩니다'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                        ref.read(workbenchViewProvider.notifier).setView(WorkbenchView.thread);
                        ref.read(threadListProvider.notifier).startOrchestration();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red.shade700),
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
                  : const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text(
                _isStarting || session.isGenerating ? '시작 중...' : '오케스트레이션 시작',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFolder(String path) async {
    if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    }
  }
}

class _FileEntry {
  final String path;
  final String label;
  final IconData icon;
  final Color? color;

  const _FileEntry({
    required this.path,
    required this.label,
    required this.icon,
    this.color,
  });
}

/// 오케스트레이션 시작 전 우측 패널에 표시할 위젯
class StartPanelController {
  static final userRequestController = TextEditingController();
  static bool _initialized = false;

  static void ensureInit(WidgetRef ref) {
    if (!_initialized) {
      final session = ref.read(sessionProvider);
      if (session.userResultRequest.isNotEmpty) {
        userRequestController.text = session.userResultRequest;
      } else {
        final defaultRequest = SessionConfig.defaultResultRequests[session.analysisMode];
        if (defaultRequest != null) {
          userRequestController.text = defaultRequest;
          Future.microtask(() {
            ref.read(sessionProvider.notifier).setUserResultRequest(defaultRequest);
          });
        }
      }
      userRequestController.addListener(() {
        // provider 업데이트는 build 중이 아닌 다음 프레임에서
        Future.microtask(() {
          ref.read(sessionProvider.notifier).setUserResultRequest(userRequestController.text);
        });
      });
      _initialized = true;
    }
  }

  /// 분석 모드 변경 시 외부에서 호출
  static void updateForMode(String mode) {
    final defaultRequest = SessionConfig.defaultResultRequests[mode];
    if (mode == 'custom') {
      userRequestController.text = '';
    } else if (defaultRequest != null) {
      userRequestController.text = defaultRequest;
    }
  }
}
