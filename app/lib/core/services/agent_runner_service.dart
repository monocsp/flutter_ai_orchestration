import 'dart:io';
import 'package:path/path.dart' as p;

class AgentRunnerService {
  /// AI CLI를 실행하고 결과를 반환합니다.
  Future<AgentRunResult> run({
    required String agentId,
    required String promptContent,
    String? workingDir,
  }) async {
    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';

    // 프롬프트를 임시 파일에 저장
    final tmpDir = await Directory.systemTemp.createTemp('orchestration_');
    final promptFile = File(p.join(tmpDir.path, 'prompt.md'));
    await promptFile.writeAsString(promptContent);

    try {
      final cmd = _buildCommand(agentId, promptFile.path);

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
          command: cmd,
          exitCode: result.exitCode,
        );
      } else {
        return AgentRunResult(
          success: false,
          output: stdout.isNotEmpty ? stdout : stderr,
          error: stderr.isNotEmpty
              ? stderr
              : 'Exit code: ${result.exitCode}',
          command: cmd,
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
      try {
        await tmpDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  /// 각 CLI에 맞는 비대화형 실행 명령 생성
  String _buildCommand(String agentId, String promptFilePath) {
    switch (agentId) {
      case 'claude':
        // claude -p "$(cat file)" --allowedTools "" --no-input
        // --print 모드 + 권한 체크 건너뛰기
        return 'cat \'$promptFilePath\' | claude -p --dangerously-skip-permissions';
      case 'codex':
        // codex exec "$(cat file)" — 비대화형 모드
        return 'codex exec "\$(cat \'$promptFilePath\')"';
      case 'gemini':
        // gemini -p "prompt" — 비대화형 모드, -p는 값을 인자로 받음
        return 'gemini -p "\$(cat \'$promptFilePath\')"';
      default:
        // 범용: cat file | exe
        return 'cat \'$promptFilePath\' | $agentId';
    }
  }
}

class AgentRunResult {
  final bool success;
  final String output;
  final String? error;
  final String? command;
  final int exitCode;

  const AgentRunResult({
    required this.success,
    required this.output,
    this.error,
    this.command,
    required this.exitCode,
  });
}
