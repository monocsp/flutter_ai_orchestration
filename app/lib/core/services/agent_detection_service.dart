import 'dart:io';
import '../models/agent_provider.dart';

class AgentDetectionService {
  Future<List<AgentInstallStatus>> detectAll() async {
    final results = <AgentInstallStatus>[];
    for (final agent in AgentProvider.builtIn) {
      if (agent.executableNames.isEmpty) {
        results.add(AgentInstallStatus(
          agentId: agent.id,
          displayName: agent.displayName,
        ));
        continue;
      }
      results.add(await _detect(agent));
    }
    return results;
  }

  Future<AgentInstallStatus> _detect(AgentProvider agent) async {
    for (final exe in agent.executableNames) {
      try {
        final shell = Platform.environment['SHELL'] ?? '/bin/zsh';

        // 1) which로 경로 확인
        final whichResult = await Process.run(
          shell,
          ['-l', '-c', 'which $exe'],
        ).timeout(const Duration(seconds: 10));
        if (whichResult.exitCode != 0) continue;

        final path = (whichResult.stdout as String).trim().split('\n').first;
        if (path.isEmpty) continue;

        // 2) --version으로 실제 실행 가능 여부 확인
        String? version;
        bool canExecute = false;
        try {
          final vResult = await Process.run(
            shell,
            ['-l', '-c', '$exe --version'],
          ).timeout(const Duration(seconds: 10));

          if (vResult.exitCode == 0) {
            canExecute = true;
            version = (vResult.stdout as String).trim().split('\n').first;
            if (version.isEmpty) {
              version = (vResult.stderr as String).trim().split('\n').first;
            }
          } else {
            // --version 실패 → 경로는 있지만 실행 불가
            final stderr = (vResult.stderr as String).trim();
            // "Cannot find" 같은 메시지가 있으면 미설치
            if (stderr.contains('Cannot find') ||
                stderr.contains('not found') ||
                stderr.contains('not installed')) {
              canExecute = false;
            }
          }
        } catch (_) {
          canExecute = false;
        }

        return AgentInstallStatus(
          agentId: agent.id,
          displayName: agent.displayName,
          installed: canExecute,
          executable: canExecute,
          detectedPath: path,
          version: version,
        );
      } catch (_) {
        continue;
      }
    }
    return AgentInstallStatus(
      agentId: agent.id,
      displayName: agent.displayName,
    );
  }
}
