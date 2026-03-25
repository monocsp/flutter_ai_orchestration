import 'dart:io';
import 'package:path/path.dart' as p;

class AgentRunnerService {
  /// AI CLI를 실행하고 결과를 반환합니다.
  /// 프롬프트는 임시 파일에 저장하여 CLI에 전달합니다.
  Future<AgentRunResult> run({
    required String agentId,
    required String promptContent,
    String? workingDir,
  }) async {
    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
    final exe = _resolveExecutable(agentId);

    // 프롬프트를 임시 파일에 저장
    final tmpDir = await Directory.systemTemp.createTemp('orchestration_');
    final promptFile = File(p.join(tmpDir.path, 'prompt.md'));
    await promptFile.writeAsString(promptContent);

    try {
      final cmd = _buildCommand(agentId, exe, promptFile.path);

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
          error: stderr.isNotEmpty
              ? stderr
              : 'Exit code: ${result.exitCode}',
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
    } finally {
      // 임시 파일 정리
      try {
        await tmpDir.delete(recursive: true);
      } catch (_) {}
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

  /// 각 CLI에 맞는 비대화형 실행 명령을 생성합니다.
  /// 프롬프트는 임시 파일 경로로 전달합니다.
  String _buildCommand(String agentId, String exe, String promptFilePath) {
    switch (agentId) {
      case 'claude':
        // claude -p "$(cat file)" -- 파일 내용을 프롬프트로
        return '$exe -p "\$(cat \'$promptFilePath\')"';
      case 'codex':
        // codex -q "$(cat file)"
        return '$exe -q "\$(cat \'$promptFilePath\')"';
      case 'gemini':
        // cat file | gemini
        return 'cat \'$promptFilePath\' | $exe';
      default:
        // 범용: cat file | exe
        return 'cat \'$promptFilePath\' | $exe';
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
