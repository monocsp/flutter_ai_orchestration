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
        // Use login shell to get user's full PATH
        final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
        final whichResult = await Process.run(
          shell,
          ['-l', '-c', 'which $exe'],
        ).timeout(const Duration(seconds: 10));
        if (whichResult.exitCode != 0) continue;

        final path = (whichResult.stdout as String).trim().split('\n').first;
        if (path.isEmpty) continue;

        String? version;
        try {
          final vResult = await Process.run(
            shell,
            ['-l', '-c', '$exe --version'],
          ).timeout(const Duration(seconds: 10));
          if (vResult.exitCode == 0) {
            version = (vResult.stdout as String).trim().split('\n').first;
            if (version.isEmpty) {
              version = (vResult.stderr as String).trim().split('\n').first;
            }
          }
        } catch (_) {}

        return AgentInstallStatus(
          agentId: agent.id,
          displayName: agent.displayName,
          installed: true,
          executable: true,
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
