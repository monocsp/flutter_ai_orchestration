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

        // 2) --version 실행 (stdin에 "n" 전달하여 대화형 프롬프트 방지)
        String? version;
        bool canExecute = false;
        try {
          final process = await Process.start(
            shell,
            ['-l', '-c', '$exe --version'],
          );
          // stdin에 "n"을 넣어서 대화형 프롬프트가 걸리지 않게
          process.stdin.writeln('n');
          await process.stdin.close();

          final vResult = await process.exitCode
              .timeout(const Duration(seconds: 8));
          final stdout =
              await process.stdout.transform(const SystemEncoding().decoder).join();
          final stderr =
              await process.stderr.transform(const SystemEncoding().decoder).join();

          final allOutput = '$stdout\n$stderr'.toLowerCase();

          // 명확한 미설치 패턴만 감지
          if (allOutput.contains('cannot find') ||
              allOutput.contains('command not found') ||
              allOutput.contains('not installed') ||
              allOutput.contains('install github copilot cli')) {
            canExecute = false;
          } else if (vResult == 0 && stdout.trim().isNotEmpty) {
            canExecute = true;
            version = stdout.trim().split('\n').first;
          }
        } catch (_) {
          // timeout 등 → 실행 불가 판정
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
