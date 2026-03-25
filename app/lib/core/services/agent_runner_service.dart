import 'dart:io';

class AgentRunnerService {
  /// AI CLI를 실행하고 결과를 반환합니다.
  /// [agentId]: codex, claude, gemini, copilot
  /// [promptContent]: 프롬프트 전체 내용
  /// [workingDir]: 실행 디렉터리 (프로젝트 루트)
  Future<AgentRunResult> run({
    required String agentId,
    required String promptContent,
    String? workingDir,
  }) async {
    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
    final exe = _resolveExecutable(agentId);

    // 프롬프트를 stdin으로 전달하는 방식
    // 각 CLI마다 비대화형 모드 명령이 다름
    final args = _buildArgs(agentId, promptContent);

    try {
      final result = await Process.run(
        shell,
        ['-l', '-c', '$exe ${args.join(' ')}'],
        workingDirectory: workingDir,
        environment: {'LANG': 'en_US.UTF-8'},
      ).timeout(const Duration(minutes: 10));

      final stdout = (result.stdout as String).trim();
      final stderr = (result.stderr as String).trim();

      if (result.exitCode == 0 && stdout.isNotEmpty) {
        return AgentRunResult(
          success: true,
          output: stdout,
          exitCode: result.exitCode,
        );
      } else {
        return AgentRunResult(
          success: false,
          output: stdout.isNotEmpty ? stdout : stderr,
          error: stderr.isNotEmpty ? stderr : 'Exit code: ${result.exitCode}',
          exitCode: result.exitCode,
        );
      }
    } on ProcessException catch (e) {
      return AgentRunResult(
        success: false,
        output: '',
        error: 'CLI 실행 실패: ${e.message}',
        exitCode: -1,
      );
    } catch (e) {
      return AgentRunResult(
        success: false,
        output: '',
        error: '실행 중 오류: $e',
        exitCode: -1,
      );
    }
  }

  String _resolveExecutable(String agentId) {
    switch (agentId) {
      case 'codex':
        return 'codex';
      case 'claude':
        return 'claude';
      case 'gemini':
        return 'gemini';
      case 'copilot':
        return 'copilot';
      default:
        return agentId;
    }
  }

  List<String> _buildArgs(String agentId, String promptContent) {
    // 프롬프트를 임시 파일에 쓰지 않고 stdin pipe로 전달
    // 각 CLI의 비대화형 모드:
    // - claude: "claude -p 'prompt'" 또는 stdin pipe
    // - codex: "codex -q 'prompt'"
    // - gemini: "gemini -p 'prompt'"
    // 범용적으로 -p 플래그 + 쉘 heredoc 사용
    final escaped = promptContent
        .replaceAll("'", "'\\''"); // shell single-quote escape

    switch (agentId) {
      case 'claude':
        return ['-p', "'$escaped'"];
      case 'codex':
        return ['-q', "'$escaped'"];
      default:
        // 범용: stdin echo pipe
        return []; // 아래에서 별도 처리
    }
  }

  /// stdin pipe 방식으로 실행 (범용)
  Future<AgentRunResult> runWithStdin({
    required String agentId,
    required String promptContent,
    String? workingDir,
  }) async {
    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
    final exe = _resolveExecutable(agentId);

    try {
      // echo "prompt" | exe 방식
      final escaped = promptContent.replaceAll('"', '\\"');
      final cmd = 'echo "$escaped" | $exe';

      final result = await Process.run(
        shell,
        ['-l', '-c', cmd],
        workingDirectory: workingDir,
        environment: {'LANG': 'en_US.UTF-8'},
      ).timeout(const Duration(minutes: 10));

      final stdout = (result.stdout as String).trim();
      final stderr = (result.stderr as String).trim();

      if (result.exitCode == 0 && stdout.isNotEmpty) {
        return AgentRunResult(
          success: true,
          output: stdout,
          exitCode: result.exitCode,
        );
      } else {
        return AgentRunResult(
          success: false,
          output: stdout.isNotEmpty ? stdout : stderr,
          error: stderr.isNotEmpty ? stderr : 'Exit code: ${result.exitCode}',
          exitCode: result.exitCode,
        );
      }
    } catch (e) {
      return AgentRunResult(
        success: false,
        output: '',
        error: '실행 중 오류: $e',
        exitCode: -1,
      );
    }
  }
}

class AgentRunResult {
  final bool success;
  final String output;
  final String? error;
  final int exitCode;

  const AgentRunResult({
    required this.success,
    required this.output,
    this.error,
    required this.exitCode,
  });
}
