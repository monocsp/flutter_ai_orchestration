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
  String? _selectedResultFile;
  String? _selectedResultContent;

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

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    return Column(
      children: [
        // Tab bar
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
              Tab(text: '입력 문서'),
              Tab(text: '결과 파일'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Input documents
              _buildInputTab(session),
              // Tab 2: Result files
              _buildResultsTab(session),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputTab(SessionState session) {
    if (session.importedFiles.isEmpty) {
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
            const SizedBox(height: 4),
            Text(
              '왼쪽 패널에서 파일을 가져오세요',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // File list
        Container(
          height: 120,
          padding: const EdgeInsets.all(8),
          child: ListView.builder(
            itemCount: session.importedFiles.length,
            itemBuilder: (context, index) {
              final path = session.importedFiles[index];
              final isSelected = path == session.sourceDocumentPath;
              return ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: const Color(0xFF0D9488).withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                leading: Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: isSelected
                      ? const Color(0xFF0D9488)
                      : Colors.grey.shade400,
                ),
                title: Text(
                  path.split(Platform.pathSeparator).last,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  path,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  ref.read(sessionProvider.notifier).setSourceDocument(path);
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        // Preview
        Expanded(
          child: session.sourceDocumentContent != null
              ? MarkdownViewer(content: session.sourceDocumentContent!)
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

  Widget _buildResultsTab(SessionState session) {
    final artifact = session.lastArtifact;
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
            const SizedBox(height: 4),
            Text(
              '세션을 생성하면 결과가 표시됩니다',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final allFiles = [
      artifact.sessionSummaryPath,
      ...artifact.promptPaths,
      artifact.executionGuidePath,
      ...artifact.resultPlaceholderPaths,
    ];

    return Column(
      children: [
        // Session path + open folder button
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
        // File list
        Container(
          height: 160,
          padding: const EdgeInsets.all(8),
          child: ListView.builder(
            itemCount: allFiles.length,
            itemBuilder: (context, index) {
              final path = allFiles[index];
              final fileName = path.split(Platform.pathSeparator).last;
              final isSelected = path == _selectedResultFile;
              return ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: const Color(0xFF0D9488).withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                leading: Icon(
                  fileName.contains('result')
                      ? Icons.edit_note
                      : Icons.article_outlined,
                  size: 18,
                  color: isSelected
                      ? const Color(0xFF0D9488)
                      : Colors.grey.shade400,
                ),
                title: Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                onTap: () async {
                  final content = await File(path).readAsString();
                  setState(() {
                    _selectedResultFile = path;
                    _selectedResultContent = content;
                  });
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        // Result preview
        Expanded(
          child: _selectedResultContent != null
              ? MarkdownViewer(content: _selectedResultContent!)
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
