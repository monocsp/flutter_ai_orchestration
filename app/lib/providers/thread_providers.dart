import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/agent_provider.dart';
import '../core/models/orchestration_thread.dart';
import '../core/models/orchestration_stage.dart';
import '../core/models/session_config.dart';
import '../core/models/parallel_comparison.dart';
import '../core/services/agent_detection_service.dart';
import '../core/services/agent_runner_service.dart';
import '../core/services/error_log_service.dart';
import 'session_providers.dart';

class ThreadListState {
  final List<OrchestrationThread> threads;
  final List<ParallelComparison> comparisons;
  final String? selectedThreadId;
  final String? selectedComparisonId;
  final bool isStopped;

  const ThreadListState({
    this.threads = const [],
    this.comparisons = const [],
    this.selectedThreadId,
    this.selectedComparisonId,
    this.isStopped = false,
  });

  ThreadListState copyWith({
    List<OrchestrationThread>? threads,
    List<ParallelComparison>? comparisons,
    String? selectedThreadId,
    String? selectedComparisonId,
    bool clearSelection = false,
    bool? isStopped,
  }) {
    return ThreadListState(
      threads: threads ?? this.threads,
      comparisons: comparisons ?? this.comparisons,
      selectedThreadId:
          clearSelection ? null : (selectedThreadId ?? this.selectedThreadId),
      selectedComparisonId: clearSelection
          ? null
          : (selectedComparisonId ?? this.selectedComparisonId),
      isStopped: isStopped ?? this.isStopped,
    );
  }

  OrchestrationThread? get selectedThread {
    if (selectedThreadId == null) return null;
    return threads.cast<OrchestrationThread?>().firstWhere(
          (t) => t!.id == selectedThreadId,
          orElse: () => null,
        );
  }

  ParallelComparison? get selectedComparison {
    if (selectedComparisonId == null) return null;
    return comparisons.cast<ParallelComparison?>().firstWhere(
          (c) => c!.id == selectedComparisonId,
          orElse: () => null,
        );
  }

  /// 사이드 레일용: 순차 + 병렬 합쳐서 시간순
  bool get isComparisonSelected => selectedComparisonId != null;
}

class ThreadListNotifier extends Notifier<ThreadListState> {
  @override
  ThreadListState build() => const ThreadListState();

  /// 오케스트레이션 중단
  void stopOrchestration() {
    state = state.copyWith(isStopped: true);

    // 진행 중인 스레드의 현재 단계를 실패로
    final thread = state.selectedThread;
    if (thread == null || thread.status != ThreadStatus.inProgress) return;

    final threadIdx = state.threads.indexWhere((t) => t.id == thread.id);
    if (threadIdx < 0) return;

    final stages = List<StageThread>.from(thread.stages);
    for (var i = 0; i < stages.length; i++) {
      if (stages[i].status == ThreadStatus.inProgress) {
        stages[i] = stages[i].copyWith(
          status: ThreadStatus.failed,
          resultContent: '> 사용자에 의해 중단되었습니다.',
          completedAt: DateTime.now(),
        );
        break;
      }
    }

    final updatedThread = thread.copyWith(
      stages: stages,
      status: ThreadStatus.failed,
    );
    final threads = List<OrchestrationThread>.from(state.threads);
    threads[threadIdx] = updatedThread;
    state = state.copyWith(threads: threads);
  }

  /// 전체 오케스트레이션 자동 실행
  Future<void> startOrchestration({String? customTitle}) async {
    state = state.copyWith(isStopped: false);

    final session = ref.read(sessionProvider);
    final now = DateTime.now();

    final title = (customTitle != null && customTitle.trim().isNotEmpty)
        ? customTitle.trim()
        : '오케스트레이션-${state.threads.length + 1}';

    final tempId = 'thread_${now.millisecondsSinceEpoch}';
    final analysisAgentName = session.analysisAgent.displayName;
    final criticAgentName = session.criticAgent.displayName;

    // Step 0: Agent 상태 확인
    final agentCheckStage = StageThread(
      stepNumber: 0,
      name: 'Agent 상태 확인',
      description:
          '$analysisAgentName(분석)과 $criticAgentName(검토)의 설치 및 실행 가능 여부를 확인합니다.',
      status: ThreadStatus.inProgress,
      startedAt: now,
    );

    final enabledStages = session.stages.where((s) => s.enabled).toList();
    final pendingStages = enabledStages
        .map((stage) => StageThread(
              stepNumber: stage.stepNumber,
              name: stage.name,
              description: stage.description,
              status: ThreadStatus.pending,
            ))
        .toList();

    final thread = OrchestrationThread(
      id: tempId,
      title: title,
      createdAt: now,
      status: ThreadStatus.inProgress,
      sessionDirPath: '',
      stages: [agentCheckStage, ...pendingStages],
    );

    state = state.copyWith(
      threads: [thread, ...state.threads],
      selectedThreadId: tempId,
    );

    // Agent 상태 확인
    final detection = AgentDetectionService();
    final allStatuses = await detection.detectAll();

    final analysisStatus = allStatuses
        .where((s) => s.agentId == session.analysisAgent.id)
        .firstOrNull;
    final criticStatus = allStatuses
        .where((s) => s.agentId == session.criticAgent.id)
        .firstOrNull;

    final analysisOk = analysisStatus?.installed == true;
    final criticOk = criticStatus?.installed == true;

    final resultLines = StringBuffer();
    resultLines.writeln('## Agent 상태 확인 결과\n');
    resultLines.writeln('### 분석 Agent: $analysisAgentName');
    if (analysisOk) {
      resultLines.writeln('- 상태: 설치됨');
      if (analysisStatus?.detectedPath != null) {
        resultLines.writeln('- 경로: `${analysisStatus!.detectedPath}`');
      }
      if (analysisStatus?.version != null) {
        resultLines.writeln('- 버전: ${analysisStatus!.version}');
      }
    } else {
      resultLines.writeln('- 상태: **미설치 또는 실행 불가**');
    }
    resultLines.writeln('\n### 검토 Agent: $criticAgentName');
    if (criticOk) {
      resultLines.writeln('- 상태: 설치됨');
      if (criticStatus?.detectedPath != null) {
        resultLines.writeln('- 경로: `${criticStatus!.detectedPath}`');
      }
      if (criticStatus?.version != null) {
        resultLines.writeln('- 버전: ${criticStatus!.version}');
      }
    } else {
      resultLines.writeln('- 상태: **미설치 또는 실행 불가**');
    }

    final bothOk = analysisOk && criticOk;
    if (bothOk) {
      resultLines.writeln('\n> 모든 Agent가 정상입니다. 오케스트레이션을 자동 진행합니다.');
    } else {
      resultLines.writeln(
          '\n> **경고**: 일부 Agent가 설치되지 않았습니다.');
    }

    // Step 0 완료
    _updateStage(tempId, 0, (s) => s.copyWith(
      status: bothOk ? ThreadStatus.completed : ThreadStatus.failed,
      resultContent: resultLines.toString(),
      completedAt: DateTime.now(),
    ));

    if (!bothOk) {
      await ErrorLogService.log(
        stage: 'Agent 상태 확인',
        error: resultLines.toString(),
      );
      _updateThreadStatus(tempId, ThreadStatus.failed);
      return;
    }

    // Step 0.5: 설정 분석 — "자동" 설정이 있으면 AI가 계획서를 보고 결정
    final sessionNotifier = ref.read(sessionProvider.notifier);
    final hasAuto = SessionConfig.hasAutoSettings(
      runObjective: session.runObjective,
      criticismLevel: session.criticismLevel,
      riskFocus: session.riskFocus,
      outputFormat: session.outputFormat,
    );

    // 설정 분석 단계 추가 (자동이든 수동이든 표시)
    final settingsStage = StageThread(
      stepNumber: 0,
      name: hasAuto ? '설정 자동 분석' : '설정 확인',
      description: hasAuto
          ? '계획서를 읽고 최적의 분석 설정을 자동으로 결정합니다.'
          : '사용자가 지정한 설정을 확인합니다.',
      status: ThreadStatus.inProgress,
      startedAt: DateTime.now(),
    );

    // 기존 stages 리스트에 설정 단계 삽입 (Step 0 다음, Step 1 이전)
    {
      final currentThread = _getThread(tempId)!;
      final stages = List<StageThread>.from(currentThread.stages);
      stages.insert(1, settingsStage); // index 0 = agent check, index 1 = settings
      final threads = List<OrchestrationThread>.from(state.threads);
      final threadIdx = state.threads.indexWhere((t) => t.id == tempId);
      threads[threadIdx] = currentThread.copyWith(stages: stages);
      state = state.copyWith(threads: threads);
    }

    if (hasAuto && session.sourceDocumentContent != null) {
      // AI에게 계획서를 보여주고 설정 추천 받기
      final autoPrompt = SessionConfig.buildAutoSettingsPrompt(
        documentContent: session.sourceDocumentContent!,
        runObjective: session.runObjective,
        criticismLevel: session.criticismLevel,
        riskFocus: session.riskFocus,
        outputFormat: session.outputFormat,
      );

      final runner = AgentRunnerService();
      final autoResult = await runner.run(
        agentId: session.analysisAgent.id,
        promptContent: autoPrompt,
      );

      if (autoResult.success) {
        // JSON 파싱해서 설정 적용
        final applied = _applyAutoSettings(
          output: autoResult.output,
          currentObjective: session.runObjective,
          currentCriticism: session.criticismLevel,
          currentRisk: session.riskFocus,
          currentFormat: session.outputFormat,
          sessionNotifier: sessionNotifier,
        );

        final settingsResult = StringBuffer();
        settingsResult.writeln('## 설정 자동 분석 결과\n');
        settingsResult.writeln('계획서를 분석하여 다음 설정을 자동으로 결정했습니다.\n');
        for (final entry in applied) {
          settingsResult.writeln('### ${entry['field']}');
          settingsResult.writeln('- **선택**: ${entry['value']}');
          settingsResult.writeln('- **이유**: ${entry['reason']}');
          settingsResult.writeln('');
        }

        _updateStage(tempId, 1, (s) => s.copyWith(
          status: ThreadStatus.completed,
          resultContent: settingsResult.toString(),
          completedAt: DateTime.now(),
        ));
      } else {
        // AI 실패 시 기본값으로 폴백
        _applyFallbackSettings(sessionNotifier: sessionNotifier);

        _updateStage(tempId, 1, (s) => s.copyWith(
          status: ThreadStatus.completed,
          resultContent: '## 설정 자동 분석\n\n'
              'AI 분석에 실패하여 기본 설정을 적용했습니다.\n\n'
              '- 실행 목적: 비판 검토 포함 실행 계획\n'
              '- 비판 강도: 높음\n'
              '- 리스크 포커스: 공통 컴포넌트 영향, 상태 관리, 라이프사이클, 회귀 위험\n'
              '- 결과 형식: 상세 실행 계획\n',
          completedAt: DateTime.now(),
        ));
      }
    } else {
      // 수동 설정: 현재 설정을 보여주고 바로 진행
      final confirmResult = StringBuffer();
      confirmResult.writeln('## 현재 설정 확인\n');
      confirmResult.writeln('| 항목 | 값 |');
      confirmResult.writeln('|------|-----|');
      confirmResult.writeln('| 실행 목적 | ${session.runObjective} |');
      confirmResult.writeln('| 비판 강도 | ${session.criticismLevel} |');
      confirmResult.writeln('| 리스크 포커스 | ${session.riskFocus} |');
      confirmResult.writeln('| 결과 형식 | ${session.outputFormat} |');
      confirmResult.writeln('| 분석 Agent | ${session.analysisAgent.displayName} |');
      confirmResult.writeln('| 검토 Agent | ${session.criticAgent.displayName} |');
      confirmResult.writeln('\n> 사용자 지정 설정으로 1차 분석을 시작합니다.');

      _updateStage(tempId, 1, (s) => s.copyWith(
        status: ThreadStatus.completed,
        resultContent: confirmResult.toString(),
        completedAt: DateTime.now(),
      ));
    }

    if (state.isStopped) return;

    // 세션 파일 생성 (설정이 확정된 후)
    final artifact = await sessionNotifier.generateSession();
    if (artifact == null) return;

    // 단계에 경로 할당
    _assignArtifactPaths(tempId, artifact);

    // 자동 실행 루프
    final runner = AgentRunnerService();

    // index 0 = agent check, index 1 = settings, index 2~ = 실제 단계
    final stageStartIndex = 2;

    for (var i = stageStartIndex; i < _getThread(tempId)!.stages.length; i++) {
      if (state.isStopped) break;

      final currentThread = _getThread(tempId)!;
      final stage = currentThread.stages[i];
      final artifactIdx = i - stageStartIndex;

      // 이 단계를 진행 중으로
      String? promptContent;
      if (stage.promptPath != null) {
        try {
          promptContent = await File(stage.promptPath!).readAsString();
        } catch (_) {}
      }

      _updateStage(tempId, i, (s) => s.copyWith(
        status: ThreadStatus.inProgress,
        promptContent: promptContent,
        startedAt: DateTime.now(),
      ));

      if (state.isStopped) break;

      // AI 담당 agent 결정
      final originalStage = enabledStages[artifactIdx];
      final agentId = originalStage.role == StageRole.analysis
          ? session.analysisAgent.id
          : session.criticAgent.id;

      // AI CLI 실행
      final result = await runner.run(
        agentId: agentId,
        promptContent: promptContent ?? '',
        workingDir: session.projectRootPath,
      );

      if (state.isStopped) break;

      if (result.success) {
        // 메모 파싱: 분석 과정 메모를 본문에서 분리
        final parsed = AgentRunnerService.parseMemo(result.output);

        // 결과 파일 저장 (본문만)
        if (stage.resultPath != null) {
          await File(stage.resultPath!).writeAsString(parsed.mainContent);

          // 메모가 있으면 별도 파일로 저장
          if (parsed.memo != null) {
            final memoPath = stage.resultPath!.replaceAll(
              RegExp(r'_result\.md$'),
              '_memo.md',
            );
            await File(memoPath).writeAsString(parsed.memo!);
          }
        }

        // UI에는 메모 + 본문 합쳐서 표시 (유저가 과정을 볼 수 있도록)
        _updateStage(tempId, i, (s) => s.copyWith(
          status: ThreadStatus.completed,
          resultContent: result.output,
          completedAt: DateTime.now(),
        ));
      } else {
        final errorMsg = StringBuffer();
        errorMsg.writeln('## 실행 실패\n');
        errorMsg.writeln('- Exit code: ${result.exitCode}');
        if (result.error != null) {
          errorMsg.writeln('- 오류: ${result.error}');
        }
        if (result.output.isNotEmpty) {
          errorMsg.writeln('\n### 출력\n```\n${result.output}\n```');
        }

        final logPath = await ErrorLogService.log(
          stage: stage.name,
          error: result.error ?? 'Unknown error',
          stdout: result.output,
          command: result.command,
          exitCode: result.exitCode,
        );
        errorMsg.writeln('\n> 에러 로그: `$logPath`');

        _updateStage(tempId, i, (s) => s.copyWith(
          status: ThreadStatus.failed,
          resultContent: errorMsg.toString(),
          completedAt: DateTime.now(),
        ));

        _updateThreadStatus(tempId, ThreadStatus.failed);
        return;
      }
    }

    // 모든 단계 완료 확인
    final finalThread = _getThread(tempId);
    if (finalThread != null) {
      final allDone = finalThread.stages
          .every((s) => s.status == ThreadStatus.completed);
      _updateThreadStatus(
          tempId, allDone ? ThreadStatus.completed : ThreadStatus.failed);
    }
  }

  void selectThread(String threadId) {
    state = state.copyWith(
        selectedThreadId: threadId, selectedComparisonId: null);
  }

  void selectComparison(String comparisonId) {
    state = state.copyWith(
        selectedComparisonId: comparisonId, selectedThreadId: null);
  }

  void deselect() {
    state = state.copyWith(clearSelection: true);
  }

  // ─── 병렬 비교 ───

  Future<void> startParallelComparison({
    required List<String> agentIds,
    required String promptContent,
    String? sourceDocPath,
    String? customTitle,
  }) async {
    state = state.copyWith(isStopped: false);

    final now = DateTime.now();
    final compId = 'parallel_${now.millisecondsSinceEpoch}';
    final title = (customTitle != null && customTitle.trim().isNotEmpty)
        ? customTitle.trim()
        : '병렬 비교-${state.comparisons.length + 1}';

    // Agent 이름 매핑
    final runs = agentIds.map((id) {
      final agent = AgentProvider.builtIn.firstWhere(
        (a) => a.id == id,
        orElse: () => AgentProvider(id: id, displayName: id),
      );
      return ParallelRun(
        agentId: id,
        agentName: agent.displayName,
        status: ThreadStatus.pending,
      );
    }).toList();

    final comparison = ParallelComparison(
      id: compId,
      title: title,
      createdAt: now,
      status: ThreadStatus.inProgress,
      promptContent: promptContent,
      sourceDocumentPath: sourceDocPath,
      runs: runs,
    );

    state = state.copyWith(
      comparisons: [comparison, ...state.comparisons],
      selectedComparisonId: compId,
      selectedThreadId: null,
    );

    // 병렬 실행
    final runner = AgentRunnerService();
    final futures = <Future<void>>[];

    for (var i = 0; i < agentIds.length; i++) {
      futures.add(_runParallelAgent(
        compId: compId,
        index: i,
        agentId: agentIds[i],
        promptContent: promptContent,
        runner: runner,
      ));
    }

    await Future.wait(futures);

    // 최종 상태: 모든 Agent가 끝났으면 completed (개별 실패는 세그먼트로 표시)
    final finalComp = _getComparison(compId);
    if (finalComp != null) {
      final allFinished = finalComp.runs.every(
          (r) => r.status == ThreadStatus.completed || r.status == ThreadStatus.failed);
      _updateComparisonStatus(
        compId,
        allFinished ? ThreadStatus.completed : ThreadStatus.inProgress,
      );
    }
  }

  Future<void> _runParallelAgent({
    required String compId,
    required int index,
    required String agentId,
    required String promptContent,
    required AgentRunnerService runner,
  }) async {
    if (state.isStopped) return;

    // Mark as in progress
    _updateRun(compId, index, (r) => r.copyWith(
      status: ThreadStatus.inProgress,
      startedAt: DateTime.now(),
    ));

    final result = await runner.run(
      agentId: agentId,
      promptContent: promptContent,
    );

    if (state.isStopped) {
      _updateRun(compId, index, (r) => r.copyWith(
        status: ThreadStatus.failed,
        resultContent: '> 사용자에 의해 중단되었습니다.',
        completedAt: DateTime.now(),
      ));
      return;
    }

    if (result.success) {
      _updateRun(compId, index, (r) => r.copyWith(
        status: ThreadStatus.completed,
        resultContent: result.output,
        completedAt: DateTime.now(),
      ));
    } else {
      final errorMsg = '## 실행 실패\n\n'
          '- Exit code: ${result.exitCode}\n'
          '- 오류: ${result.error ?? "Unknown"}\n'
          '${result.output.isNotEmpty ? "\n### 출력\n```\n${result.output}\n```" : ""}';

      await ErrorLogService.log(
        stage: '병렬 비교 - $agentId',
        error: result.error ?? 'Unknown error',
        stdout: result.output,
        command: result.command,
        exitCode: result.exitCode,
      );

      _updateRun(compId, index, (r) => r.copyWith(
        status: ThreadStatus.failed,
        resultContent: errorMsg,
        completedAt: DateTime.now(),
      ));
    }
  }

  // ─── Parallel Helpers ───

  ParallelComparison? _getComparison(String id) {
    return state.comparisons.cast<ParallelComparison?>().firstWhere(
          (c) => c!.id == id,
          orElse: () => null,
        );
  }

  void _updateRun(String compId, int index,
      ParallelRun Function(ParallelRun) updater) {
    final compIdx = state.comparisons.indexWhere((c) => c.id == compId);
    if (compIdx < 0) return;

    final comp = state.comparisons[compIdx];
    final runs = List<ParallelRun>.from(comp.runs);
    runs[index] = updater(runs[index]);

    final comparisons = List<ParallelComparison>.from(state.comparisons);
    comparisons[compIdx] = comp.copyWith(runs: runs);
    state = state.copyWith(comparisons: comparisons);
  }

  void _updateComparisonStatus(String compId, ThreadStatus status) {
    final compIdx = state.comparisons.indexWhere((c) => c.id == compId);
    if (compIdx < 0) return;

    final comparisons = List<ParallelComparison>.from(state.comparisons);
    comparisons[compIdx] = comparisons[compIdx].copyWith(status: status);
    state = state.copyWith(comparisons: comparisons);
  }

  // ─── Helpers ───

  OrchestrationThread? _getThread(String id) {
    return state.threads.cast<OrchestrationThread?>().firstWhere(
          (t) => t!.id == id,
          orElse: () => null,
        );
  }

  void _updateStage(
      String threadId, int index, StageThread Function(StageThread) updater) {
    final threadIdx = state.threads.indexWhere((t) => t.id == threadId);
    if (threadIdx < 0) return;

    final thread = state.threads[threadIdx];
    final stages = List<StageThread>.from(thread.stages);
    stages[index] = updater(stages[index]);

    final threads = List<OrchestrationThread>.from(state.threads);
    threads[threadIdx] = thread.copyWith(stages: stages);
    state = state.copyWith(threads: threads);
  }

  /// AI 응답에서 JSON을 파싱해 자동 설정 적용
  List<Map<String, String>> _applyAutoSettings({
    required String output,
    required String currentObjective,
    required String currentCriticism,
    required String currentRisk,
    required String currentFormat,
    required SessionNotifier sessionNotifier,
  }) {
    final applied = <Map<String, String>>[];

    try {
      // JSON 블록 추출 (```json ... ``` 또는 { ... })
      String jsonStr = output;
      final jsonBlockMatch = RegExp(r'```json\s*([\s\S]*?)```').firstMatch(output);
      if (jsonBlockMatch != null) {
        jsonStr = jsonBlockMatch.group(1)!.trim();
      } else {
        final braceMatch = RegExp(r'\{[\s\S]*\}').firstMatch(output);
        if (braceMatch != null) {
          jsonStr = braceMatch.group(0)!;
        }
      }

      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (currentObjective == SessionConfig.autoValue && parsed.containsKey('runObjective')) {
        final val = parsed['runObjective'] as String;
        sessionNotifier.setRunObjective(val);
        applied.add({
          'field': '실행 목적',
          'value': val,
          'reason': (parsed['runObjectiveReason'] as String?) ?? '-',
        });

        // 리스크 포커스도 연동
        if (currentRisk.isEmpty && !parsed.containsKey('riskFocus')) {
          final autoRisk = SessionConfig.defaultRiskFocus(val);
          sessionNotifier.setRiskFocus(autoRisk);
          applied.add({
            'field': '리스크 포커스 (실행 목적 연동)',
            'value': autoRisk,
            'reason': '실행 목적에 맞는 기본 리스크 포커스 자동 적용',
          });
        }
      }

      if (currentCriticism == SessionConfig.autoValue && parsed.containsKey('criticismLevel')) {
        final val = parsed['criticismLevel'] as String;
        sessionNotifier.setCriticismLevel(val);
        applied.add({
          'field': '비판 강도',
          'value': val,
          'reason': (parsed['criticismLevelReason'] as String?) ?? '-',
        });
      }

      if (currentRisk.isEmpty && parsed.containsKey('riskFocus')) {
        final val = parsed['riskFocus'] as String;
        sessionNotifier.setRiskFocus(val);
        applied.add({
          'field': '리스크 포커스',
          'value': val,
          'reason': (parsed['riskFocusReason'] as String?) ?? '-',
        });
      }

      if (currentFormat.isEmpty && parsed.containsKey('outputFormat')) {
        final val = parsed['outputFormat'] as String;
        sessionNotifier.setOutputFormat(val);
        applied.add({
          'field': '결과 형식',
          'value': val,
          'reason': (parsed['outputFormatReason'] as String?) ?? '-',
        });
      }
    } catch (_) {
      // 파싱 실패 시 폴백
      _applyFallbackSettings(sessionNotifier: sessionNotifier);
      applied.add({
        'field': '전체',
        'value': '기본값 적용',
        'reason': 'AI 응답 파싱 실패로 기본 설정 적용',
      });
    }

    return applied;
  }

  /// AI 분석 실패 시 기본값 적용
  void _applyFallbackSettings({required SessionNotifier sessionNotifier}) {
    final session = ref.read(sessionProvider);
    if (session.runObjective == SessionConfig.autoValue) {
      sessionNotifier.setRunObjective('비판 검토 포함 실행 계획');
    }
    if (session.criticismLevel == SessionConfig.autoValue) {
      sessionNotifier.setCriticismLevel('높음');
    }
    if (session.riskFocus.isEmpty) {
      sessionNotifier.setRiskFocus('공통 컴포넌트 영향, 상태 관리, 라이프사이클, 회귀 위험');
    }
    if (session.outputFormat.isEmpty) {
      sessionNotifier.setOutputFormat('상세 실행 계획');
    }
  }

  void _updateThreadStatus(String threadId, ThreadStatus status) {
    final threadIdx = state.threads.indexWhere((t) => t.id == threadId);
    if (threadIdx < 0) return;

    final threads = List<OrchestrationThread>.from(state.threads);
    threads[threadIdx] = threads[threadIdx].copyWith(status: status);
    state = state.copyWith(threads: threads);
  }

  void _assignArtifactPaths(String threadId, dynamic artifact) {
    final threadIdx = state.threads.indexWhere((t) => t.id == threadId);
    if (threadIdx < 0) return;

    final thread = state.threads[threadIdx];
    final stages = List<StageThread>.from(thread.stages);

    // index 0 = agent check, index 1 = settings, index 2~ = 실제 단계
    for (var i = 2; i < stages.length; i++) {
      final artifactIdx = i - 2;
      stages[i] = stages[i].copyWith(
        promptPath: artifactIdx < artifact.promptPaths.length
            ? artifact.promptPaths[artifactIdx]
            : null,
        resultPath: artifactIdx < artifact.resultPlaceholderPaths.length
            ? artifact.resultPlaceholderPaths[artifactIdx]
            : null,
      );
    }

    final threads = List<OrchestrationThread>.from(state.threads);
    threads[threadIdx] =
        thread.copyWith(stages: stages, sessionDirPath: artifact.sessionDirPath);
    state = state.copyWith(threads: threads);
  }
}

final threadListProvider =
    NotifierProvider<ThreadListNotifier, ThreadListState>(
        ThreadListNotifier.new);
