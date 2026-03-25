import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/orchestration_thread.dart';
import '../../providers/thread_providers.dart';
import '../session_setup/session_setup_panel.dart';
import '../stage_editor/stage_editor_panel.dart';
import '../documents/documents_panel.dart';
import '../agent_status/agent_status_bar.dart';
import '../thread/thread_detail_view.dart';
import '../tutorial/tutorial_overlay.dart';

/// Main view mode
enum WorkbenchView { setup, thread }

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

    return Scaffold(
      body: Stack(
        children: [
          // Main UI
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
                            child: currentView == WorkbenchView.setup
                                ? const _SetupBody()
                                : const _ThreadBody(),
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
    );
  }
}

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
          // Thread list
          Expanded(
            child: threadState.threads.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    itemCount: threadState.threads.length,
                    itemBuilder: (context, index) {
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
                    },
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
    final color = AppTheme.stageColors[index % AppTheme.stageColors.length];

    return Tooltip(
      message: '${thread.title}\n${thread.completedCount}/${thread.totalCount} 완료',
      child: Material(
        color: isSelected
            ? color.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: color, width: 1.5)
                  : Border.all(color: const Color(0xFF475569), width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : Colors.grey.shade400,
                  ),
                ),
                // Status dot
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _dotColor(thread.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _dotColor(ThreadStatus status) {
    switch (status) {
      case ThreadStatus.inProgress:
        return const Color(0xFF0D9488);
      case ThreadStatus.completed:
        return const Color(0xFF22C55E);
      case ThreadStatus.failed:
        return const Color(0xFFEF4444);
      case ThreadStatus.pending:
        return Colors.grey.shade500;
    }
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

    String title;
    IconData icon;
    if (currentView == WorkbenchView.thread && selectedThread != null) {
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

/// Setup view: 3-panel layout (session setup / stage editor / documents)
class _SetupBody extends ConsumerWidget {
  const _SetupBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
