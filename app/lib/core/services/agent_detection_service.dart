import 'dart:io';
import '../models/agent_provider.dart';

class AgentDetectionService {
  String? _cachedPath;

  /// 로그인 셸에서 실제 PATH를 가져옵니다.
  /// .app 번들로 실행 시 Finder가 터미널 PATH를 상속하지 않는 문제를 해결합니다.
  Future<String> _getLoginShellPath() async {
    if (_cachedPath != null) return _cachedPath!;

    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
    try {
      final result = await Process.run(
        shell,
        ['-l', '-c', 'echo \$PATH'],
      ).timeout(const Duration(seconds: 10));

      if (result.exitCode == 0) {
        _cachedPath = (result.stdout as String).trim();
        if (_cachedPath!.isNotEmpty) return _cachedPath!;
      }
    } catch (_) {}

    // 폴백: 일반적인 경로를 직접 추가
    _cachedPath = [
      '/opt/homebrew/bin',
      '/usr/local/bin',
      '/usr/bin',
      '/bin',
      '${Platform.environment['HOME']}/.local/bin',
      '${Platform.environment['HOME']}/.nvm/versions/node/current/bin',
      '${Platform.environment['HOME']}/.npm-global/bin',
      Platform.environment['PATH'] ?? '',
    ].join(':');

    return _cachedPath!;
  }

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
    final loginPath = await _getLoginShellPath();
    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
    final env = {'PATH': loginPath, 'LANG': 'en_US.UTF-8'};

    for (final exe in agent.executableNames) {
      try {
        // 1) which로 경로 확인 — 로그인 셸의 PATH 사용
        final whichResult = await Process.run(
          shell,
          ['-l', '-c', 'which $exe'],
          environment: env,
        ).timeout(const Duration(seconds: 10));
        if (whichResult.exitCode != 0) continue;

        final path = (whichResult.stdout as String).trim().split('\n').first;
        if (path.isEmpty) continue;

        // 2) --version 실행
        String? version;
        bool canExecute = false;
        try {
          final process = await Process.start(
            shell,
            ['-l', '-c', '$exe --version'],
            environment: env,
          );
          process.stdin.writeln('n');
          await process.stdin.close();

          final vResult = await process.exitCode
              .timeout(const Duration(seconds: 8));
          final stdout =
              await process.stdout.transform(const SystemEncoding().decoder).join();
          final stderr =
              await process.stderr.transform(const SystemEncoding().decoder).join();

          final allOutput = '$stdout\n$stderr'.toLowerCase();

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
