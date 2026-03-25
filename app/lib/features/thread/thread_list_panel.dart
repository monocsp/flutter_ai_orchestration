import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/orchestration_thread.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/thread_providers.dart';

class ThreadListPanel extends ConsumerWidget {
  const ThreadListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadState = ref.watch(threadListProvider);
    final threads = threadState.threads;

    if (threads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_outlined, size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                '오케스트레이션을 시작하면\n스레드가 여기에 표시됩니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: threads.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final thread = threads[index];
        final isSelected = thread.id == threadState.selectedThreadId;

        return _ThreadTile(
          thread: thread,
          isSelected: isSelected,
          onTap: () {
            ref.read(threadListProvider.notifier).selectThread(thread.id);
          },
        );
      },
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final OrchestrationThread thread;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThreadTile({
    required this.thread,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? const Color(0xFF0D9488).withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Status indicator
              _statusIcon(thread.status),
              const SizedBox(width: 10),
              // Title + progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Progress bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: thread.totalCount > 0
                                  ? thread.completedCount / thread.totalCount
                                  : 0,
                              minHeight: 3,
                              backgroundColor: Colors.grey.shade200,
                              color: _statusColor(thread.status),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${thread.completedCount}/${thread.totalCount}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIcon(ThreadStatus status) {
    switch (status) {
      case ThreadStatus.inProgress:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.stageColors[0],
          ),
        );
      case ThreadStatus.completed:
        return const Icon(Icons.check_circle, size: 16, color: Color(0xFF22C55E));
      case ThreadStatus.failed:
        return const Icon(Icons.error, size: 16, color: Color(0xFFEF4444));
      case ThreadStatus.pending:
        return Icon(Icons.circle_outlined, size: 16, color: Colors.grey.shade300);
    }
  }

  Color _statusColor(ThreadStatus status) {
    switch (status) {
      case ThreadStatus.inProgress:
        return AppTheme.stageColors[0];
      case ThreadStatus.completed:
        return const Color(0xFF22C55E);
      case ThreadStatus.failed:
        return const Color(0xFFEF4444);
      case ThreadStatus.pending:
        return Colors.grey.shade300;
    }
  }
}
