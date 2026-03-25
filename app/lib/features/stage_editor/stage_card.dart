import 'package:flutter/material.dart';
import '../../core/models/orchestration_stage.dart';

class StageCard extends StatefulWidget {
  final OrchestrationStage stage;
  final int stageIndex;
  final Color color;
  final ValueChanged<OrchestrationStage> onChanged;

  const StageCard({
    super.key,
    required this.stage,
    required this.stageIndex,
    required this.color,
    required this.onChanged,
  });

  @override
  State<StageCard> createState() => _StageCardState();
}

class _StageCardState extends State<StageCard> {
  late TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _promptController =
        TextEditingController(text: widget.stage.promptTemplate);
  }

  @override
  void didUpdateWidget(covariant StageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stageIndex != widget.stageIndex) {
      _promptController.text = widget.stage.promptTemplate;
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${stage.stepNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        stage.role == StageRole.analysis
                            ? '분석 Agent 담당'
                            : '검토 Agent 담당',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Enable toggle
                Switch(
                  value: stage.enabled,
                  activeThumbColor: widget.color,
                  onChanged: (v) {
                    widget.onChanged(stage.copyWith(enabled: v));
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Stage info - wrap for narrow screens
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _infoChip(
                  icon: Icons.output_rounded,
                  label: '출력',
                  value: stage.outputFileName,
                ),
                _infoChip(
                  icon: Icons.article_outlined,
                  label: '템플릿',
                  value: stage.promptTemplate,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Prompt template editor label
            Text(
              '프롬프트 템플릿 파일',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),

            // Prompt template editor
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _promptController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: Color(0xFF334155),
                    height: 1.6,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: true,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: (v) {
                    widget.onChanged(stage.copyWith(promptTemplate: v));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
