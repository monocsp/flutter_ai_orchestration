import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/orchestration_thread.dart';
import '../../core/models/parallel_comparison.dart';
import '../../providers/thread_providers.dart';

class ParallelResultView extends ConsumerStatefulWidget {
  final ParallelComparison comparison;
  const ParallelResultView({super.key, required this.comparison});

  @override
  ConsumerState<ParallelResultView> createState() => _ParallelResultViewState();
}

class _ParallelResultViewState extends ConsumerState<ParallelResultView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.comparison.runs.length,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant ParallelResultView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comparison.runs.length != widget.comparison.runs.length) {
      _tabController.dispose();
      _tabController = TabController(
        length: widget.comparison.runs.length,
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comparison = widget.comparison;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              _statusIcon(comparison.status),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comparison.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${comparison.completedCount}/${comparison.totalCount} Agent 완료',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (comparison.status == ThreadStatus.inProgress)
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(threadListProvider.notifier).stopOrchestration();
                  },
                  icon: const Icon(Icons.stop_rounded, size: 16),
                  label: const Text('중단'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              if (comparison.status == ThreadStatus.completed)
                _badge('완료', const Color(0xFF22C55E)),
              if (comparison.status == ThreadStatus.failed)
                _badge('실패', const Color(0xFFEF4444)),
            ],
          ),
        ),

        // Agent tabs
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: comparison.runs.length > 3,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: comparison.runs.map((run) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _runStatusDot(run.status),
                    const SizedBox(width: 6),
                    Text(run.agentName),
                    if (run.executionTimeText.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        run.executionTimeText,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: comparison.runs.map((run) {
              return _buildRunContent(run);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRunContent(ParallelRun run) {
    if (run.status == ThreadStatus.pending) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('대기 중',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    if (run.status == ThreadStatus.inProgress) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: const Color(0xFF0D9488),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${run.agentName}이(가) 분석 중입니다...',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D9488),
              ),
            ),
          ],
        ),
      );
    }

    if (run.resultContent == null || run.resultContent!.isEmpty) {
      return Center(
        child: Text('결과 없음',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      );
    }

    // Completed or Failed: show result
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: run.status == ThreadStatus.failed
              ? const Color(0xFFFEF2F2)
              : const Color(0xFFF8FAFC),
          child: Row(
            children: [
              Icon(
                run.status == ThreadStatus.failed
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                size: 14,
                color: run.status == ThreadStatus.failed
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22C55E),
              ),
              const SizedBox(width: 6),
              Text(
                run.status == ThreadStatus.failed ? '실패' : '완료',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: run.status == ThreadStatus.failed
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF22C55E),
                ),
              ),
              if (run.executionTimeText.isNotEmpty) ...[
                const SizedBox(width: 12),
                Text(
                  '실행 시간: ${run.executionTimeText}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: Icon(Icons.copy, size: 14, color: Colors.grey.shade400),
                tooltip: '결과 복사',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: run.resultContent!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('결과가 클립보드에 복사되었습니다'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: Markdown(
            data: run.resultContent!,
            selectable: true,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _statusIcon(ThreadStatus status) {
    switch (status) {
      case ThreadStatus.inProgress:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFF0D9488)),
        );
      case ThreadStatus.completed:
        return const Icon(Icons.check_circle,
            size: 20, color: Color(0xFF22C55E));
      case ThreadStatus.failed:
        return const Icon(Icons.error, size: 20, color: Color(0xFFEF4444));
      case ThreadStatus.pending:
        return Icon(Icons.circle_outlined,
            size: 20, color: Colors.grey.shade300);
    }
  }

  Widget _runStatusDot(ThreadStatus status) {
    Color color;
    switch (status) {
      case ThreadStatus.inProgress:
        color = const Color(0xFF0D9488);
      case ThreadStatus.completed:
        color = const Color(0xFF22C55E);
      case ThreadStatus.failed:
        color = const Color(0xFFEF4444);
      case ThreadStatus.pending:
        color = Colors.grey.shade300;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
