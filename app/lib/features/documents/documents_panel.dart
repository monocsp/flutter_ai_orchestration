import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_providers.dart';
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
        Expanded(child: _fileListWithPreview(files)),
      ],
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
