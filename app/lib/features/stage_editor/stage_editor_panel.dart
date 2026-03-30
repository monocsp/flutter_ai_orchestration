import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/session_providers.dart';
import 'stage_card.dart';

class StageEditorPanel extends ConsumerStatefulWidget {
  const StageEditorPanel({super.key});

  @override
  ConsumerState<StageEditorPanel> createState() => _StageEditorPanelState();
}

class _StageEditorPanelState extends ConsumerState<StageEditorPanel> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final stages = session.stages;

    if (_selectedIndex >= stages.length) {
      _selectedIndex = 0;
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'STAGE EDITOR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  session.preset.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stage timeline - horizontal step indicators
          SizedBox(
            height: 68,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stageWidth = constraints.maxWidth / stages.length;
                return Row(
                  children: List.generate(stages.length, (i) {
                    final stage = stages[i];
                    final color =
                        AppTheme.stageColors[i % AppTheme.stageColors.length];
                    final isSelected = i == _selectedIndex;

                    return SizedBox(
                      width: stageWidth,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Connector line + circle row
                            SizedBox(
                              height: 36,
                              child: Row(
                                children: [
                                  // Left connector
                                  Expanded(
                                    child: i > 0
                                        ? Container(
                                            height: 2,
                                            color: stages[i - 1].enabled
                                                ? AppTheme.stageColors[
                                                        (i - 1) %
                                                            AppTheme.stageColors
                                                                .length]
                                                    .withValues(alpha: 0.3)
                                                : Colors.grey.shade300,
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  // Circle badge
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: isSelected ? 36 : 30,
                                    height: isSelected ? 36 : 30,
                                    decoration: BoxDecoration(
                                      color: stage.enabled
                                          ? (isSelected
                                              ? color
                                              : color.withValues(alpha: 0.15))
                                          : Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? Border.all(
                                              color:
                                                  color.withValues(alpha: 0.4),
                                              width: 3,
                                            )
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${stage.stepNumber}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: stage.enabled
                                              ? (isSelected
                                                  ? Colors.white
                                                  : color)
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Right connector
                                  Expanded(
                                    child: i < stages.length - 1
                                        ? Container(
                                            height: 2,
                                            color: stage.enabled
                                                ? color.withValues(alpha: 0.3)
                                                : Colors.grey.shade300,
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Label + help tooltip
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    stage.name,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF0F172A)
                                          : Colors.grey.shade500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (stage.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2),
                                    child: Tooltip(
                                      message: stage.description,
                                      preferBelow: true,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        height: 1.4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      waitDuration:
                                          const Duration(milliseconds: 300),
                                      child: Icon(
                                        Icons.help_outline_rounded,
                                        size: 11,
                                        color: isSelected
                                            ? color.withValues(alpha: 0.6)
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Selected stage detail
          Expanded(
            child: StageCard(
              stage: stages[_selectedIndex],
              stageIndex: _selectedIndex,
              color: AppTheme
                  .stageColors[_selectedIndex % AppTheme.stageColors.length],
              onChanged: (updatedStage) {
                ref
                    .read(sessionProvider.notifier)
                    .updateStage(_selectedIndex, updatedStage);
              },
            ),
          ),
        ],
      ),
    );
  }
}
