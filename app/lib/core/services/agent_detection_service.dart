import 'dart:io';
import '../models/agent_provider.dart';

class AgentDetectionService {
  static String? _cachedPath;

  /// 로그인 셸에서 실제 PATH를 한 번 가져와 캐싱합니다.
  /// .app 번들에서 Finder로 실행 시 터미널 PATH가 없는 문제를 해결합니다.
  static Future<String> getLoginShellPath() async {
    if (_cachedPath != null) return _cachedPath!;

    if (Platform.isWindows) {
      return _getWindowsPath();
    }
    return _getMacLinuxPath();
  }

  /// Windows: 시스템 PATH를 그대로 사용 + npm/nodejs 일반 경로 보강
  static Future<String> _getWindowsPath() async {
    final currentPath = Platform.environment['PATH'] ?? '';
    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    final appData = Platform.environment['APPDATA'] ?? '';
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final programFiles = Platform.environment['ProgramFiles'] ?? r'C:\Program Files';

    final extraPaths = [
      if (appData.isNotEmpty) '$appData\\npm',
      if (localAppData.isNotEmpty) '$localAppData\\Programs\\Python\\Python311',
      if (localAppData.isNotEmpty) '$localAppData\\Programs\\Python\\Python312',
      '$programFiles\\nodejs',
      '$programFiles\\Git\\cmd',
      if (userProfile.isNotEmpty) '$userProfile\\.pub-cache\\bin',
    ];

    _cachedPath = [...extraPaths, currentPath].join(';');
    return _cachedPath!;
  }

  /// macOS/Linux: 로그인 셸에서 PATH를 가져옴
  static Future<String> _getMacLinuxPath() async {
    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
    final home = Platform.environment['HOME'] ?? '';

    try {
      final result = await Process.run(
        shell,
        ['-l', '-i', '-c', 'echo \$PATH'],
        environment: null,
      ).timeout(const Duration(seconds: 10));

      if (result.exitCode == 0) {
        final p = (result.stdout as String).trim().split('\n').last;
        if (p.isNotEmpty) {
          _cachedPath = p;
          return _cachedPath!;
        }
      }
    } catch (_) {}

    // 폴백: 현재 PATH에 일반적인 경로를 보강
    final currentPath = Platform.environment['PATH'] ?? '';
    final extraPaths = [
      '/opt/homebrew/bin',
      '/opt/homebrew/sbin',
      '/usr/local/bin',
      '$home/.local/bin',
      '$home/.nvm/versions/node/current/bin',
      '$home/.npm-global/bin',
      '$home/.pub-cache/bin',
    ];

    _cachedPath = [...extraPaths, currentPath].join(':');
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
    if (Platform.isWindows) {
      return _detectWindows(agent);
    }
    return _detectMacLinux(agent);
  }

  /// Windows: where.exe로 실행 파일 검색
  Future<AgentInstallStatus> _detectWindows(AgentProvider agent) async {
    final loginPath = await getLoginShellPath();

    for (final exe in agent.executableNames) {
      try {
        // 1) where.exe로 경로 확인
        final whereResult = await Process.run(
          'cmd.exe',
          ['/c', 'set "PATH=$loginPath" && where $exe'],
        ).timeout(const Duration(seconds: 10));
        if (whereResult.exitCode != 0) continue;

        final path = (whereResult.stdout as String).trim().split('\n').first.trim();
        if (path.isEmpty) continue;

        // 2) --version 실행
        String? version;
        bool canExecute = false;
        try {
          final process = await Process.start(
            'cmd.exe',
            ['/c', 'set "PATH=$loginPath" && $exe --version'],
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

          if (allOutput.contains('is not recognized') ||
              allOutput.contains('could not be found') ||
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

  /// macOS/Linux: which로 실행 파일 검색
  Future<AgentInstallStatus> _detectMacLinux(AgentProvider agent) async {
    final loginPath = await getLoginShellPath();
    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';

    for (final exe in agent.executableNames) {
      try {
        // 1) which로 경로 확인
        final whichResult = await Process.run(
          shell,
          ['-c', 'export PATH="$loginPath:\$PATH"; which $exe'],
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
            ['-c', 'export PATH="$loginPath:\$PATH"; $exe --version'],
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
