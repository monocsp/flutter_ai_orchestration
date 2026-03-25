import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../core/models/orchestration_thread.dart';
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

  /// 오케스트레이션 시작: 세션 파일 생성 → 스레드 생성 → 1단계 진행 중
  Future<void> startOrchestration({String? customTitle}) async {
    final sessionNotifier = ref.read(sessionProvider.notifier);
    final artifact = await sessionNotifier.generateSession();
    if (artifact == null) return;

    final session = ref.read(sessionProvider);
    final now = DateTime.now();
    final threadId = p.basename(artifact.sessionDirPath);

    // 제목: 사용자 지정 or 자동 번호
    final title = (customTitle != null && customTitle.trim().isNotEmpty)
        ? customTitle.trim()
        : '오케스트레이션-${state.threads.length + 1}';

    // 단계 목록 생성
    final enabledStages = session.stages.where((s) => s.enabled).toList();
    final stageThreads = <StageThread>[];

    for (var i = 0; i < enabledStages.length; i++) {
      final stage = enabledStages[i];
      final promptPath =
          i < artifact.promptPaths.length ? artifact.promptPaths[i] : null;
      final resultPath = i < artifact.resultPlaceholderPaths.length
          ? artifact.resultPlaceholderPaths[i]
          : null;

      String? promptContent;
      if (promptPath != null) {
        try {
          promptContent = await File(promptPath).readAsString();
        } catch (_) {}
      }

      stageThreads.add(StageThread(
        stepNumber: stage.stepNumber,
        name: stage.name,
        status: i == 0 ? ThreadStatus.inProgress : ThreadStatus.pending,
        promptPath: promptPath,
        resultPath: resultPath,
        promptContent: promptContent,
        startedAt: i == 0 ? now : null,
      ));
    }

    final thread = OrchestrationThread(
      id: threadId,
      title: title,
      createdAt: now,
      status: ThreadStatus.inProgress,
      sessionDirPath: artifact.sessionDirPath,
      stages: stageThreads,
    );

    state = state.copyWith(
      threads: [thread, ...state.threads],
      selectedThreadId: threadId,
    );
  }

  void selectThread(String threadId) {
    state = state.copyWith(selectedThreadId: threadId);
  }

  void deselect() {
    state = state.copyWith(clearSelection: true);
  }

  /// 현재 단계에 결과를 입력하고 완료 처리 → 다음 단계 진행 중
  Future<void> submitStageResult(
      String threadId, int stageIndex, String resultContent) async {
    final threadIdx = state.threads.indexWhere((t) => t.id == threadId);
    if (threadIdx < 0) return;

    final thread = state.threads[threadIdx];
    final stages = List<StageThread>.from(thread.stages);
    final now = DateTime.now();

    // 현재 단계 완료
    stages[stageIndex] = stages[stageIndex].copyWith(
      status: ThreadStatus.completed,
      resultContent: resultContent,
      completedAt: now,
    );

    // 결과 파일 저장
    final resultPath = stages[stageIndex].resultPath;
    if (resultPath != null) {
      await File(resultPath).writeAsString(resultContent);
    }

    // 다음 단계가 있으면 진행 중으로
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

    // 스레드 상태 업데이트
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
