import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/orchestration_thread.dart';
import '../core/services/agent_detection_service.dart';
import 'session_providers.dart';

class ThreadListState {
  final List<OrchestrationThread> threads;
  final String? selectedThreadId;

  const ThreadListState({
    this.threads = const [],
    this.selectedThreadId,
  });

  ThreadListState copyWith({
    List<OrchestrationThread>? threads,
    String? selectedThreadId,
    bool clearSelection = false,
  }) {
    return ThreadListState(
      threads: threads ?? this.threads,
      selectedThreadId:
          clearSelection ? null : (selectedThreadId ?? this.selectedThreadId),
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

  Future<void> startOrchestration({String? customTitle}) async {
    final session = ref.read(sessionProvider);
    final now = DateTime.now();

    final title = (customTitle != null && customTitle.trim().isNotEmpty)
        ? customTitle.trim()
        : '오케스트레이션-${state.threads.length + 1}';

    // 임시 thread ID (세션 생성 전)
    final tempId =
        'thread_${now.millisecondsSinceEpoch}';

    // Step 0: Agent 상태 확인 단계를 맨 앞에 추가
    final analysisAgentName = session.analysisAgent.displayName;
    final criticAgentName = session.criticAgent.displayName;

    final agentCheckStage = StageThread(
      stepNumber: 0,
      name: 'Agent 상태 확인',
      description:
          '$analysisAgentName(분석)과 $criticAgentName(검토)의 설치 및 실행 가능 여부를 확인합니다.',
      status: ThreadStatus.inProgress,
      startedAt: now,
    );

    // 나머지 단계는 pending으로
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

    // Agent 상태 확인 실행
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

    // 결과 텍스트 생성
    final resultLines = StringBuffer();
    resultLines.writeln('## Agent 상태 확인 결과\n');

    resultLines.writeln('### 분석 Agent: $analysisAgentName');
    if (analysisStatus != null && analysisOk) {
      resultLines.writeln('- 상태: 설치됨');
      if (analysisStatus.detectedPath != null) {
        resultLines.writeln('- 경로: `${analysisStatus.detectedPath}`');
      }
      if (analysisStatus.version != null) {
        resultLines.writeln('- 버전: ${analysisStatus.version}');
      }
    } else {
      resultLines.writeln('- 상태: **미설치 또는 실행 불가**');
    }

    resultLines.writeln('\n### 검토 Agent: $criticAgentName');
    if (criticStatus != null && criticOk) {
      resultLines.writeln('- 상태: 설치됨');
      if (criticStatus.detectedPath != null) {
        resultLines.writeln('- 경로: `${criticStatus.detectedPath}`');
      }
      if (criticStatus.version != null) {
        resultLines.writeln('- 버전: ${criticStatus.version}');
      }
    } else {
      resultLines.writeln('- 상태: **미설치 또는 실행 불가**');
    }

    final bothOk = analysisOk && criticOk;
    if (bothOk) {
      resultLines.writeln('\n> 모든 Agent가 정상입니다. 오케스트레이션을 진행합니다.');
    } else {
      resultLines.writeln(
          '\n> **경고**: 일부 Agent가 설치되지 않았습니다. 해당 Agent의 CLI를 설치한 후 다시 시도하세요.');
    }

    // Step 0 완료로 업데이트
    final threadIdx = state.threads.indexWhere((t) => t.id == tempId);
    if (threadIdx < 0) return;

    final currentThread = state.threads[threadIdx];
    final stages = List<StageThread>.from(currentThread.stages);

    stages[0] = stages[0].copyWith(
      status: bothOk ? ThreadStatus.completed : ThreadStatus.failed,
      resultContent: resultLines.toString(),
      completedAt: DateTime.now(),
    );

    if (!bothOk) {
      // Agent 실패 → 스레드도 실패
      final failedThread = currentThread.copyWith(
        stages: stages,
        status: ThreadStatus.failed,
      );
      final threads = List<OrchestrationThread>.from(state.threads);
      threads[threadIdx] = failedThread;
      state = state.copyWith(threads: threads);
      return;
    }

    // Agent 확인 통과 → 세션 파일 생성
    final sessionNotifier = ref.read(sessionProvider.notifier);
    final artifact = await sessionNotifier.generateSession();
    if (artifact == null) return;

    // 1단계를 진행 중으로 전환 + 프롬프트 로드
    if (stages.length > 1) {
      String? promptContent;
      final promptPath =
          artifact.promptPaths.isNotEmpty ? artifact.promptPaths[0] : null;
      if (promptPath != null) {
        try {
          promptContent = await File(promptPath).readAsString();
        } catch (_) {}
      }
      stages[1] = stages[1].copyWith(
        status: ThreadStatus.inProgress,
        promptPath: promptPath,
        resultPath: artifact.resultPlaceholderPaths.isNotEmpty
            ? artifact.resultPlaceholderPaths[0]
            : null,
        promptContent: promptContent,
        startedAt: DateTime.now(),
      );
    }

    // 나머지 단계에도 경로 할당
    for (var i = 2; i < stages.length; i++) {
      final artifactIdx = i - 1; // stages[0]이 agent check이므로
      stages[i] = stages[i].copyWith(
        promptPath: artifactIdx < artifact.promptPaths.length
            ? artifact.promptPaths[artifactIdx]
            : null,
        resultPath: artifactIdx < artifact.resultPlaceholderPaths.length
            ? artifact.resultPlaceholderPaths[artifactIdx]
            : null,
      );
    }

    final updatedThread = currentThread.copyWith(
      stages: stages,
      sessionDirPath: artifact.sessionDirPath,
    );

    final threads = List<OrchestrationThread>.from(state.threads);
    threads[threadIdx] = updatedThread;
    state = state.copyWith(threads: threads);
  }

  void selectThread(String threadId) {
    state = state.copyWith(selectedThreadId: threadId);
  }

  void deselect() {
    state = state.copyWith(clearSelection: true);
  }

  Future<void> submitStageResult(
      String threadId, int stageIndex, String resultContent) async {
    final threadIdx = state.threads.indexWhere((t) => t.id == threadId);
    if (threadIdx < 0) return;

    final thread = state.threads[threadIdx];
    final stages = List<StageThread>.from(thread.stages);
    final now = DateTime.now();

    stages[stageIndex] = stages[stageIndex].copyWith(
      status: ThreadStatus.completed,
      resultContent: resultContent,
      completedAt: now,
    );

    final resultPath = stages[stageIndex].resultPath;
    if (resultPath != null) {
      await File(resultPath).writeAsString(resultContent);
    }

    // 다음 단계 진행
    final hasNext = stageIndex + 1 < stages.length;
    if (hasNext) {
      final nextStage = stages[stageIndex + 1];
      String? promptContent;
      if (nextStage.promptPath != null) {
        try {
          promptContent = await File(nextStage.promptPath!).readAsString();
        } catch (_) {}
      }
      stages[stageIndex + 1] = nextStage.copyWith(
        status: ThreadStatus.inProgress,
        promptContent: promptContent,
        startedAt: now,
      );
    }

    final allCompleted =
        stages.every((s) => s.status == ThreadStatus.completed);
    final updatedThread = thread.copyWith(
      stages: stages,
      status: allCompleted ? ThreadStatus.completed : ThreadStatus.inProgress,
    );

    final threads = List<OrchestrationThread>.from(state.threads);
    threads[threadIdx] = updatedThread;
    state = state.copyWith(threads: threads);
  }
}

final threadListProvider =
    NotifierProvider<ThreadListNotifier, ThreadListState>(
        ThreadListNotifier.new);
