import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../session_setup/session_setup_panel.dart';
import '../stage_editor/stage_editor_panel.dart';
import '../documents/documents_panel.dart';
import '../agent_status/agent_status_bar.dart';

class WorkbenchScreen extends ConsumerWidget {
  const WorkbenchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          // Title bar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: const Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.hub, color: AppTheme.stageColors[0], size: 22),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'AI Orchestration Workbench',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // 3-panel body with minimum window size handling
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // For narrow windows, stack vertically with tabs
                if (constraints.maxWidth < 900) {
                  return _CompactLayout();
                }
                // Normal 3-panel layout
                final sideWidth = (constraints.maxWidth * 0.24).clamp(260.0, 340.0);
                final rightWidth = (constraints.maxWidth * 0.28).clamp(280.0, 400.0);
                return Row(
                  children: [
                    SizedBox(
                      width: sideWidth,
                      child: Container(
                        decoration: AppTheme.sidebarDecoration,
                        child: const SessionSetupPanel(),
                      ),
                    ),
                    const Expanded(
                      child: StageEditorPanel(),
                    ),
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
            ),
          ),
          // Bottom: Agent status bar
          const AgentStatusBar(),
        ],
      ),
    );
  }
}

/// Compact layout for narrow windows — uses tabs instead of 3 panels
class _CompactLayout extends StatefulWidget {
  @override
  State<_CompactLayout> createState() => _CompactLayoutState();
}

class _CompactLayoutState extends State<_CompactLayout>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
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
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
