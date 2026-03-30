import 'dart:io';
import 'package:path/path.dart' as p;

class AgentRunnerService {
  /// 래핑 프롬프트: 모든 AI 호출 앞에 자동 주입
  static const _memoWrapper = '''
[필수 지시 1] 결과의 전체 내용을 반드시 이 응답에 직접 출력하세요. 파일에 저장하거나 별도 경로에 쓰지 마세요. 요약만 출력하는 것은 금지입니다.

[필수 지시 2] 아래 프롬프트에 대해 응답할 때, 반드시 본론을 시작하기 전에 맨 앞에 아래 형식의 섹션을 작성하세요.

## 분석 과정 메모

- 이 문서/분석을 읽고 가장 먼저 느낀 핵심 쟁점
- 여러 해석이 가능했던 부분과 왜 이쪽을 택했는지
- 판단에 확신이 없는 부분
- 다음 단계 검토자에게 전하고 싶은 맥락

이 메모를 작성한 후 "---" 구분선을 넣고 본론(구조화된 분석)을 시작하세요.

---

''';

  /// AI CLI를 실행하고 결과를 반환합니다.
  Future<AgentRunResult> run({
    required String agentId,
    required String promptContent,
    String? workingDir,
    Duration timeout = const Duration(minutes: 20),
  }) async {
    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';

    // 래핑 프롬프트 주입
    final wrappedPrompt = '$_memoWrapper$promptContent';

    // 프롬프트를 임시 파일에 저장
    final tmpDir = await Directory.systemTemp.createTemp('orchestration_');
    final promptFile = File(p.join(tmpDir.path, 'prompt.md'));
    await promptFile.writeAsString(wrappedPrompt);

    try {
      final cmd = _buildCommand(agentId, promptFile.path);

      final result = await Process.run(
        shell,
        ['-l', '-c', cmd],
        workingDirectory: workingDir,
        environment: {'LANG': 'en_US.UTF-8'},
      ).timeout(timeout);

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

  /// AI 결과에서 "## 분석 과정 메모" 섹션을 분리합니다.
  /// Returns (memo, mainContent). 메모가 없으면 memo는 null.
  static MemoParseResult parseMemo(String output) {
    // "## 분석 과정 메모" 또는 "## 검토 과정 메모" 또는 "## 보강 과정 메모" 등을 찾음
    final memoPattern = RegExp(
      r'^## (?:분석|검토|보강|종합) ?과정 ?메모[^\n]*\n',
      multiLine: true,
    );

    final match = memoPattern.firstMatch(output);
    if (match == null) {
      return MemoParseResult(memo: null, mainContent: output);
    }

    final memoStart = match.start;
    final afterHeader = match.end;

    // 메모 끝: 다음 "---" 구분선 또는 다음 "## " 헤더
    final separatorPattern = RegExp(r'^---\s*$|^## ', multiLine: true);
    final endMatch = separatorPattern.firstMatch(output.substring(afterHeader));

    String memo;
    String mainContent;

    if (endMatch != null) {
      final memoEnd = afterHeader + endMatch.start;
      memo = output.substring(memoStart, memoEnd).trim();

      // "---" 구분선이면 건너뛰기
      var mainStart = afterHeader + endMatch.start;
      if (output.substring(mainStart).startsWith('---')) {
        final afterSep = output.indexOf('\n', mainStart);
        mainStart = afterSep >= 0 ? afterSep + 1 : output.length;
      }
      mainContent = output.substring(mainStart).trim();
    } else {
      // 구분선 없이 끝까지 메모만 있는 경우
      memo = output.substring(memoStart).trim();
      mainContent = '';
    }

    return MemoParseResult(
      memo: memo.isNotEmpty ? memo : null,
      mainContent: mainContent.isNotEmpty ? mainContent : output,
    );
  }

  /// 각 CLI에 맞는 비대화형 실행 명령 생성
  String _buildCommand(String agentId, String promptFilePath) {
    switch (agentId) {
      case 'claude':
        return 'cat \'$promptFilePath\' | claude -p --dangerously-skip-permissions';
      case 'codex':
        return 'codex exec "\$(cat \'$promptFilePath\')"';
      case 'gemini':
        return 'gemini -p "\$(cat \'$promptFilePath\')"';
      default:
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

class MemoParseResult {
  final String? memo;
  final String mainContent;

  const MemoParseResult({required this.memo, required this.mainContent});
}
