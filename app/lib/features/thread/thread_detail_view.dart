import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/orchestration_thread.dart';
import '../../providers/thread_providers.dart';
import 'stage_thread_card.dart';

class ThreadDetailView extends ConsumerWidget {
  const ThreadDetailView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadState = ref.watch(threadListProvider);
    final thread = threadState.selectedThread;

    if (thread == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              '스레드를 선택하세요',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Thread header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              _statusIcon(thread.status),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${thread.completedCount}/${thread.totalCount} 단계 완료',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge or stop button
              if (thread.status == ThreadStatus.inProgress)
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
                )
              else if (thread.status == ThreadStatus.completed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '완료',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                )
              else if (thread.status == ThreadStatus.failed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '실패',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Stage timeline
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            itemCount: thread.stages.length,
            itemBuilder: (context, index) {
              final stage = thread.stages[index];
              return StageThreadCard(
                stage: stage,
                index: index,
                isLast: index == thread.stages.length - 1,
              );
            },
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
            strokeWidth: 2,
            color: Color(0xFF0D9488),
          ),
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
}
