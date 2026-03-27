import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/orchestration_thread.dart';
import '../core/models/orchestration_stage.dart';
import '../core/services/agent_detection_service.dart';
import '../core/services/agent_runner_service.dart';
import '../core/services/error_log_service.dart';
import 'session_providers.dart';

class ThreadListState {
  final List<OrchestrationThread> threads;
  final String? selectedThreadId;
  final bool isStopped;

  const ThreadListState({
    this.threads = const [],
    this.selectedThreadId,
    this.isStopped = false,
  });

  ThreadListState copyWith({
    List<OrchestrationThread>? threads,
    String? selectedThreadId,
    bool clearSelection = false,
    bool? isStopped,
  }) {
    return ThreadListState(
      threads: threads ?? this.threads,
      selectedThreadId:
          clearSelection ? null : (selectedThreadId ?? this.selectedThreadId),
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

    // 세션 파일 생성
    final sessionNotifier = ref.read(sessionProvider.notifier);
    final artifact = await sessionNotifier.generateSession();
    if (artifact == null) return;

    // 단계에 경로 할당
    _assignArtifactPaths(tempId, artifact);

    // 자동 실행 루프
    final runner = AgentRunnerService();

    for (var i = 1; i < _getThread(tempId)!.stages.length; i++) {
      if (state.isStopped) break;

      final currentThread = _getThread(tempId)!;
      final stage = currentThread.stages[i];
      final artifactIdx = i - 1;

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
        // 결과 파일 저장
        if (stage.resultPath != null) {
          await File(stage.resultPath!).writeAsString(result.output);
        }

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
    state = state.copyWith(selectedThreadId: threadId);
  }

  void deselect() {
    state = state.copyWith(clearSelection: true);
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

    for (var i = 1; i < stages.length; i++) {
      final artifactIdx = i - 1;
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
