import 'orchestration_thread.dart';

class ParallelRun {
  final String agentId;
  final String agentName;
  final ThreadStatus status;
  final String? resultContent;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const ParallelRun({
    required this.agentId,
    required this.agentName,
    this.status = ThreadStatus.pending,
    this.resultContent,
    this.startedAt,
    this.completedAt,
  });

  ParallelRun copyWith({
    String? agentId,
    String? agentName,
    ThreadStatus? status,
    String? resultContent,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return ParallelRun(
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      status: status ?? this.status,
      resultContent: resultContent ?? this.resultContent,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  String get executionTimeText {
    if (startedAt == null || completedAt == null) return '';
    final diff = completedAt!.difference(startedAt!);
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 ${diff.inSeconds % 60}초';
    }
    return '${diff.inSeconds}초';
  }
}

class ParallelComparison {
  final String id;
  final String title;
  final DateTime createdAt;
  final ThreadStatus status;
  final String promptContent;
  final String? sourceDocumentPath;
  final List<ParallelRun> runs;

  const ParallelComparison({
    required this.id,
    required this.title,
    required this.createdAt,
    this.status = ThreadStatus.pending,
    required this.promptContent,
    this.sourceDocumentPath,
    required this.runs,
  });

  ParallelComparison copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    ThreadStatus? status,
    String? promptContent,
    String? sourceDocumentPath,
    List<ParallelRun>? runs,
  }) {
    return ParallelComparison(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      promptContent: promptContent ?? this.promptContent,
      sourceDocumentPath: sourceDocumentPath ?? this.sourceDocumentPath,
      runs: runs ?? this.runs,
    );
  }

  int get completedCount =>
      runs.where((r) => r.status == ThreadStatus.completed).length;
  int get totalCount => runs.length;
}
