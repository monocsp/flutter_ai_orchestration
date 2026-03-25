enum ThreadStatus { pending, inProgress, completed, failed }

class StageThread {
  final int stepNumber;
  final String name;
  final ThreadStatus status;
  final String? promptPath;
  final String? resultPath;
  final String? promptContent;
  final String? resultContent;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const StageThread({
    required this.stepNumber,
    required this.name,
    this.status = ThreadStatus.pending,
    this.promptPath,
    this.resultPath,
    this.promptContent,
    this.resultContent,
    this.startedAt,
    this.completedAt,
  });

  StageThread copyWith({
    int? stepNumber,
    String? name,
    ThreadStatus? status,
    String? promptPath,
    String? resultPath,
    String? promptContent,
    String? resultContent,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return StageThread(
      stepNumber: stepNumber ?? this.stepNumber,
      name: name ?? this.name,
      status: status ?? this.status,
      promptPath: promptPath ?? this.promptPath,
      resultPath: resultPath ?? this.resultPath,
      promptContent: promptContent ?? this.promptContent,
      resultContent: resultContent ?? this.resultContent,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class OrchestrationThread {
  final String id;
  final String title;
  final DateTime createdAt;
  final ThreadStatus status;
  final String sessionDirPath;
  final List<StageThread> stages;

  const OrchestrationThread({
    required this.id,
    required this.title,
    required this.createdAt,
    this.status = ThreadStatus.pending,
    required this.sessionDirPath,
    required this.stages,
  });

  OrchestrationThread copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    ThreadStatus? status,
    String? sessionDirPath,
    List<StageThread>? stages,
  }) {
    return OrchestrationThread(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      sessionDirPath: sessionDirPath ?? this.sessionDirPath,
      stages: stages ?? this.stages,
    );
  }

  int get completedCount => stages.where((s) => s.status == ThreadStatus.completed).length;
  int get totalCount => stages.length;
  StageThread? get currentStage => stages.cast<StageThread?>().firstWhere(
        (s) => s!.status == ThreadStatus.inProgress,
        orElse: () => null,
      );
}
