import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/models/orchestration_thread.dart';
import '../../core/theme/app_theme.dart';

class StageThreadCard extends StatefulWidget {
  final StageThread stage;
  final int index;
  final bool isLast;

  const StageThreadCard({
    super.key,
    required this.stage,
    required this.index,
    this.isLast = false,
  });

  @override
  State<StageThreadCard> createState() => _StageThreadCardState();
}

class _StageThreadCardState extends State<StageThreadCard> {
  bool _showPrompt = false;
  bool _showResult = true;

  Color get _stageColor =>
      AppTheme.stageColors[widget.index % AppTheme.stageColors.length];

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline badge + connector
          Column(
            children: [
              _statusBadge(stage),
              if (!widget.isLast)
                Container(
                  width: 2,
                  height: 16,
                  color: stage.status == ThreadStatus.completed
                      ? _stageColor.withValues(alpha: 0.3)
                      : Colors.grey.shade200,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildContent(stage)),
        ],
      ),
    );
  }

  Widget _statusBadge(StageThread stage) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _badgeColor(stage.status),
        shape: BoxShape.circle,
        border: stage.status == ThreadStatus.inProgress
            ? Border.all(color: _stageColor.withValues(alpha: 0.4), width: 2)
            : null,
      ),
      child: Center(child: _badgeContent(stage)),
    );
  }

  Color _badgeColor(ThreadStatus status) {
    switch (status) {
      case ThreadStatus.completed:
        return const Color(0xFF22C55E);
      case ThreadStatus.inProgress:
        return _stageColor.withValues(alpha: 0.15);
      case ThreadStatus.failed:
        return const Color(0xFFEF4444);
      case ThreadStatus.pending:
        return Colors.grey.shade200;
    }
  }

  Widget _badgeContent(StageThread stage) {
    switch (stage.status) {
      case ThreadStatus.completed:
        return const Icon(Icons.check, size: 16, color: Colors.white);
      case ThreadStatus.inProgress:
        return SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _stageColor,
          ),
        );
      case ThreadStatus.failed:
        return const Icon(Icons.close, size: 16, color: Colors.white);
      case ThreadStatus.pending:
        return Text(
          '${stage.stepNumber}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade400,
          ),
        );
    }
  }

  Widget _buildContent(StageThread stage) {
    return Card(
      color: stage.status == ThreadStatus.inProgress
          ? const Color(0xFFF0FDFA)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    stage.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: stage.status == ThreadStatus.pending
                          ? Colors.grey.shade400
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                _statusLabel(stage.status),
              ],
            ),

            // Description
            if (stage.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  stage.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
              ),

            // In progress: show spinner + prompt
            if (stage.status == ThreadStatus.inProgress) ...[
              const SizedBox(height: 12),
              // Running indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _stageColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _stageColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _stageColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'AI가 분석 중입니다...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _stageColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Prompt (collapsible)
              if (stage.promptContent != null)
                _expandableSection(
                  title: '프롬프트 보기',
                  icon: Icons.description_outlined,
                  isExpanded: _showPrompt,
                  onToggle: () => setState(() => _showPrompt = !_showPrompt),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 14),
                    tooltip: '프롬프트 복사',
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: stage.promptContent!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('클립보드에 복사되었습니다'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              if (_showPrompt && stage.promptContent != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Markdown(
                    data: stage.promptContent!,
                    selectable: true,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
            ],

            // Completed: show result
            if (stage.status == ThreadStatus.completed &&
                stage.resultContent != null) ...[
              const SizedBox(height: 8),
              _expandableSection(
                title: '결과',
                icon: Icons.check_circle_outline,
                isExpanded: _showResult,
                onToggle: () => setState(() => _showResult = !_showResult),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 14),
                  tooltip: '결과 복사',
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: stage.resultContent!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('결과가 클립보드에 복사되었습니다'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              if (_showResult)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Markdown(
                    data: stage.resultContent!,
                    selectable: true,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              if (stage.completedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '완료: ${_formatTime(stage.completedAt!)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ),
            ],

            // Failed: show error
            if (stage.status == ThreadStatus.failed &&
                stage.resultContent != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      stage.resultContent!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF991B1B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: stage.resultContent!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('에러 내용이 클립보드에 복사되었습니다'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 14),
                        label: const Text('에러 복사'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Pending
            if (stage.status == ThreadStatus.pending)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '이전 단계가 완료되면 자동으로 진행됩니다',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusLabel(ThreadStatus status) {
    String text;
    Color color;
    switch (status) {
      case ThreadStatus.inProgress:
        text = 'AI 실행 중';
        color = _stageColor;
      case ThreadStatus.completed:
        text = '완료';
        color = const Color(0xFF22C55E);
      case ThreadStatus.failed:
        text = '실패';
        color = const Color(0xFFEF4444);
      case ThreadStatus.pending:
        text = '대기';
        color = Colors.grey.shade400;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _expandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: Colors.grey.shade400,
            ),
            if (trailing != null) ...[const Spacer(), trailing],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
