import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/orchestration_thread.dart';
import '../../core/models/parallel_comparison.dart';
import '../../providers/session_providers.dart';
import '../../providers/thread_providers.dart';
import '../session_setup/session_setup_panel.dart';
import '../stage_editor/stage_editor_panel.dart';
import '../documents/documents_panel.dart';
import '../agent_status/agent_status_bar.dart';
import '../thread/thread_detail_view.dart';
import '../parallel/parallel_setup_panel.dart';
import '../parallel/parallel_result_view.dart';
import '../tutorial/tutorial_overlay.dart';

/// Main view mode
enum WorkbenchView { setup, thread, comparison }

class WorkbenchViewNotifier extends Notifier<WorkbenchView> {
  @override
  WorkbenchView build() => WorkbenchView.setup;

  void setView(WorkbenchView view) => state = view;
}

final workbenchViewProvider =
    NotifierProvider<WorkbenchViewNotifier, WorkbenchView>(
        WorkbenchViewNotifier.new);

class WorkbenchScreen extends ConsumerStatefulWidget {
  const WorkbenchScreen({super.key});

  @override
  ConsumerState<WorkbenchScreen> createState() => _WorkbenchScreenState();
}

class _WorkbenchScreenState extends ConsumerState<WorkbenchScreen> {
  bool _showTutorial = false;

  void _toggleTutorial() => setState(() => _showTutorial = !_showTutorial);

  @override
  Widget build(BuildContext context) {
    final currentView = ref.watch(workbenchViewProvider);
    final threadState = ref.watch(threadListProvider);

    return DropTarget(
      onDragDone: (details) {
        for (final file in details.files) {
          if (file.path.isNotEmpty) {
            ref.read(sessionProvider.notifier).setSourceDocument(file.path);
            ref.read(workbenchViewProvider.notifier).setView(WorkbenchView.setup);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('파일 로드: ${file.name}'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            break;
          }
        }
      },
      child: Scaffold(
        body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _SideRail(
                      currentView: currentView,
                      threadState: threadState,
                      onHelpTap: _toggleTutorial,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _TitleBar(
                            currentView: currentView,
                            threadState: threadState,
                            onHelpTap: _toggleTutorial,
                          ),
                          Expanded(
                            child: switch (currentView) {
                              WorkbenchView.setup => const _SetupBody(),
                              WorkbenchView.thread => const _ThreadBody(),
                              WorkbenchView.comparison =>
                                _ComparisonBody(threadState: threadState),
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const AgentStatusBar(),
            ],
          ),
          // Tutorial overlay
          if (_showTutorial)
            TutorialOverlay(
              steps: setupTutorialSteps,
              onComplete: () => setState(() => _showTutorial = false),
            ),
        ],
      ),
      ),
    );
  }
}  // _WorkbenchScreenState

/// Narrow left rail with [+] button + thread list icons
class _SideRail extends ConsumerWidget {
  final WorkbenchView currentView;
  final ThreadListState threadState;
  final VoidCallback onHelpTap;

  const _SideRail({
    required this.currentView,
    required this.threadState,
    required this.onHelpTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 56,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), // slate-800
        border: Border(right: BorderSide(color: Color(0xFF334155))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // New orchestration button
          _RailButton(
            icon: Icons.add_rounded,
            tooltip: '새 오케스트레이션',
            isActive: currentView == WorkbenchView.setup,
            onTap: () {
              ref.read(workbenchViewProvider.notifier).setView(
                  WorkbenchView.setup);
              ref.read(threadListProvider.notifier).deselect();
            },
          ),
          const SizedBox(height: 8),
          // Divider
          Container(
            width: 28,
            height: 1,
            color: const Color(0xFF475569),
          ),
          const SizedBox(height: 8),
          // Thread + Comparison list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              children: [
                // Sequential threads
                ...List.generate(threadState.threads.length, (index) {
                  final thread = threadState.threads[index];
                  final isSelected =
                      thread.id == threadState.selectedThreadId &&
                          currentView == WorkbenchView.thread;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _ThreadIcon(
                      thread: thread,
                      index: index,
                      isSelected: isSelected,
                      onTap: () {
                        ref
                            .read(threadListProvider.notifier)
                            .selectThread(thread.id);
                        ref.read(workbenchViewProvider.notifier).setView(
                            WorkbenchView.thread);
                      },
                    ),
                  );
                }),
                // Parallel comparisons
                ...List.generate(threadState.comparisons.length, (index) {
                  final comp = threadState.comparisons[index];
                  final isSelected =
                      comp.id == threadState.selectedComparisonId &&
                          currentView == WorkbenchView.comparison;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _ComparisonIcon(
                      comparison: comp,
                      isSelected: isSelected,
                      onTap: () {
                        ref
                            .read(threadListProvider.notifier)
                            .selectComparison(comp.id);
                        ref.read(workbenchViewProvider.notifier).setView(
                            WorkbenchView.comparison);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          // Help button at bottom
          const SizedBox(height: 8),
          Container(
            width: 28,
            height: 1,
            color: const Color(0xFF475569),
          ),
          const SizedBox(height: 8),
          _RailButton(
            icon: Icons.help_outline_rounded,
            tooltip: '사용법',
            isActive: false,
            onTap: onHelpTap,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  const _RailButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive
            ? const Color(0xFF0D9488).withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border.all(color: const Color(0xFF0D9488), width: 1.5)
                  : null,
            ),
            child: Icon(
              icon,
              size: 22,
              color: isActive ? const Color(0xFF0D9488) : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreadIcon extends StatelessWidget {
  final OrchestrationThread thread;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThreadIcon({
    required this.thread,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = thread.status == ThreadStatus.completed;
    final isRunning = thread.status == ThreadStatus.inProgress;
    final isFailed = thread.status == ThreadStatus.failed;
    final progress = thread.totalCount > 0
        ? thread.completedCount / thread.totalCount
        : 0.0;

    Color borderColor;
    if (isCompleted) {
      borderColor = const Color(0xFF22C55E);
    } else if (isRunning) {
      borderColor = const Color(0xFF0D9488);
    } else if (isFailed) {
      borderColor = const Color(0xFFEF4444);
    } else {
      borderColor = const Color(0xFF475569);
    }

    return Tooltip(
      message: '${thread.title}\n${thread.completedCount}/${thread.totalCount} 완료',
      child: Material(
        color: isSelected
            ? borderColor.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring for in-progress
                if (isRunning)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2.5,
                      backgroundColor: const Color(0xFF475569),
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                // Completed ring
                if (isCompleted)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF22C55E), width: 2.5),
                    ),
                  ),
                // Failed ring
                if (isFailed)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFEF4444), width: 2.5),
                    ),
                  ),
                // Pending ring
                if (!isRunning && !isCompleted && !isFailed)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF475569), width: 1),
                    ),
                  ),
                // Center content
                if (isCompleted)
                  const Icon(Icons.check_rounded,
                      size: 20, color: Color(0xFF22C55E))
                else if (isFailed)
                  const Icon(Icons.close_rounded,
                      size: 20, color: Color(0xFFEF4444))
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isRunning
                              ? const Color(0xFF0D9488)
                              : Colors.grey.shade400,
                        ),
                      ),
                      if (isRunning)
                        Text(
                          '${thread.completedCount}/${thread.totalCount}',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Title bar that changes based on view
class _TitleBar extends StatelessWidget {
  final WorkbenchView currentView;
  final ThreadListState threadState;
  final VoidCallback onHelpTap;

  const _TitleBar({
    required this.currentView,
    required this.threadState,
    required this.onHelpTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedThread = threadState.selectedThread;

    final selectedComparison = threadState.selectedComparison;

    String title;
    IconData icon;
    if (currentView == WorkbenchView.comparison && selectedComparison != null) {
      title = selectedComparison.title;
      icon = Icons.compare_arrows;
    } else if (currentView == WorkbenchView.thread && selectedThread != null) {
      title = selectedThread.title;
      icon = Icons.forum_outlined;
    } else {
      title = '새 오케스트레이션';
      icon = Icons.hub;
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.stageColors[0], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (currentView == WorkbenchView.thread && selectedThread != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(selectedThread.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${selectedThread.completedCount}/${selectedThread.totalCount} 단계',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(selectedThread.status),
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.help_outline, size: 18, color: Colors.grey.shade400),
            tooltip: '사용법',
            onPressed: onHelpTap,
          ),
        ],
      ),
    );
  }

  Color _statusColor(ThreadStatus status) {
    switch (status) {
      case ThreadStatus.inProgress:
        return const Color(0xFF0D9488);
      case ThreadStatus.completed:
        return const Color(0xFF22C55E);
      case ThreadStatus.failed:
        return const Color(0xFFEF4444);
      case ThreadStatus.pending:
        return Colors.grey;
    }
  }
}

/// Setup view with mode tabs: sequential / parallel
class _SetupBody extends StatefulWidget {
  const _SetupBody();

  @override
  State<_SetupBody> createState() => _SetupBodyState();
}

class _SetupBodyState extends State<_SetupBody>
    with SingleTickerProviderStateMixin {
  late TabController _modeTab;

  @override
  void initState() {
    super.initState();
    _modeTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _modeTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mode tabs
        Container(
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: TabBar(
            controller: _modeTab,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.linear_scale, size: 14),
                    SizedBox(width: 6),
                    Text('순차 오케스트레이션'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.compare_arrows, size: 14),
                    SizedBox(width: 6),
                    Text('병렬 비교'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _modeTab,
            children: [
              const _SequentialSetup(),
              const _ParallelSetup(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sequential: existing 3-panel layout
class _SequentialSetup extends StatelessWidget {
  const _SequentialSetup();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return const _CompactSetup();
        }
        final sideWidth =
            (constraints.maxWidth * 0.26).clamp(260.0, 340.0);
        final rightWidth =
            (constraints.maxWidth * 0.28).clamp(260.0, 380.0);

        return Row(
          children: [
            SizedBox(
              width: sideWidth,
              child: Container(
                decoration: AppTheme.sidebarDecoration,
                child: const SessionSetupPanel(),
              ),
            ),
            const Expanded(child: StageEditorPanel()),
            SizedBox(
              width: rightWidth,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: const DocumentsPanel(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Parallel: setup panel only (full width)
class _ParallelSetup extends StatelessWidget {
  const _ParallelSetup();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return const ParallelSetupPanel();
        }
        return Row(
          children: [
            SizedBox(
              width: (constraints.maxWidth * 0.35).clamp(300.0, 400.0),
              child: Container(
                decoration: AppTheme.sidebarDecoration,
                child: const ParallelSetupPanel(),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.compare_arrows,
                        size: 56, color: Colors.grey.shade200),
                    const SizedBox(height: 16),
                    Text(
                      '동일한 프롬프트를 여러 AI에 병렬로 실행하여\n결과를 비교합니다',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Thread view: thread detail + documents
class _ThreadBody extends ConsumerWidget {
  const _ThreadBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return const ThreadDetailView();
        }
        final rightWidth =
            (constraints.maxWidth * 0.30).clamp(260.0, 400.0);

        return Row(
          children: [
            const Expanded(child: ThreadDetailView()),
            SizedBox(
              width: rightWidth,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: const DocumentsPanel(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Comparison view: parallel result view
class _ComparisonBody extends StatelessWidget {
  final ThreadListState threadState;
  const _ComparisonBody({required this.threadState});

  @override
  Widget build(BuildContext context) {
    final comparison = threadState.selectedComparison;
    if (comparison == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              '병렬 비교를 선택하세요',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ParallelResultView(
      key: ValueKey(comparison.id),
      comparison: comparison,
    );
  }
}

/// Sidebar icon for parallel comparisons — segmented ring per agent
class _ComparisonIcon extends StatelessWidget {
  final ParallelComparison comparison;
  final bool isSelected;
  final VoidCallback onTap;

  const _ComparisonIcon({
    required this.comparison,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final allDone = comparison.runs
        .every((r) => r.status == ThreadStatus.completed || r.status == ThreadStatus.failed);
    final isRunning = comparison.status == ThreadStatus.inProgress;

    return Tooltip(
      message:
          '${comparison.title}\n${comparison.completedCount}/${comparison.totalCount} 완료',
      child: Material(
        color: isSelected
            ? const Color(0xFF6366F1).withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Segmented ring
                CustomPaint(
                  size: const Size(40, 40),
                  painter: _SegmentedRingPainter(
                    segments: comparison.runs.map((r) => r.status).toList(),
                  ),
                ),
                // Center icon
                if (allDone)
                  const Icon(Icons.check_rounded,
                      size: 18, color: Color(0xFF22C55E))
                else if (isRunning)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: const Color(0xFF6366F1),
                    ),
                  )
                else
                  Icon(Icons.compare_arrows,
                      size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a circle divided into N equal arcs, each colored by status
class _SegmentedRingPainter extends CustomPainter {
  final List<ThreadStatus> segments;

  _SegmentedRingPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;
    const strokeWidth = 3.0;
    const gapRadians = 0.08; // small gap between segments

    final sweepPerSegment =
        (2 * 3.14159265 - gapRadians * segments.length) / segments.length;
    var startAngle = -3.14159265 / 2; // start from top

    for (final status in segments) {
      final paint = Paint()
        ..color = _colorForStatus(status)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepPerSegment,
        false,
        paint,
      );

      startAngle += sweepPerSegment + gapRadians;
    }
  }

  Color _colorForStatus(ThreadStatus status) {
    switch (status) {
      case ThreadStatus.completed:
        return const Color(0xFF22C55E);
      case ThreadStatus.inProgress:
        return const Color(0xFF6366F1);
      case ThreadStatus.failed:
        return const Color(0xFFEF4444);
      case ThreadStatus.pending:
        return const Color(0xFF475569);
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedRingPainter oldDelegate) {
    if (oldDelegate.segments.length != segments.length) return true;
    for (var i = 0; i < segments.length; i++) {
      if (oldDelegate.segments[i] != segments[i]) return true;
    }
    return false;
  }
}

class _CompactSetup extends StatefulWidget {
  const _CompactSetup();

  @override
  State<_CompactSetup> createState() => _CompactSetupState();
}

class _CompactSetupState extends State<_CompactSetup>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '설정'),
            Tab(text: '단계 편집'),
            Tab(text: '문서/결과'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              SessionSetupPanel(),
              StageEditorPanel(),
              DocumentsPanel(),
            ],
          ),
        ),
      ],
    );
  }
}
