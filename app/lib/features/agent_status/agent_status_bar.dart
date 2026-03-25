import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/agent_provider.dart';
import '../../providers/agent_providers.dart';
import '../../providers/session_providers.dart';

class AgentStatusBar extends ConsumerWidget {
  const AgentStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(agentStatusProvider);
    final session = ref.watch(sessionProvider);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Agent badges - flexible to prevent overflow
          Expanded(
            child: statusAsync.when(
              data: (statuses) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: statuses
                      .where((s) => s.agentId != 'other')
                      .map((status) => _agentBadge(context, status))
                      .toList(),
                ),
              ),
              loading: () => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Agent 확인 중...',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
              error: (_, _) => Text(
                'Agent 확인 실패',
                style: TextStyle(fontSize: 11, color: Colors.red.shade400),
              ),
            ),
          ),

          // Session path
          if (session.lastArtifact != null)
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.folder_outlined,
                      size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      session.lastArtifact!.sessionDirPath.split('/').last,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _agentBadge(BuildContext context, AgentInstallStatus status) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Tooltip(
        message: _tooltipText(status),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status.installed
                    ? (status.executable
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFFBBF24))
                    : const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              status.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: status.installed
                    ? const Color(0xFF334155)
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tooltipText(AgentInstallStatus status) {
    if (!status.installed) return '${status.displayName}: 미설치';
    final parts = <String>['설치됨'];
    if (status.executable) parts.add('실행 가능');
    if (status.detectedPath != null) parts.add('경로: ${status.detectedPath}');
    if (status.version != null) parts.add('버전: ${status.version}');
    return '${status.displayName}: ${parts.join(' | ')}';
  }
}
