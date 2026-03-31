import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParallelSetupState {
  final String title;
  final String prompt;
  final String? sourceDocPath;
  final String? sourceDocContent;
  final Set<String> selectedAgentIds;
  final bool isStarting;

  const ParallelSetupState({
    this.title = '',
    this.prompt = _defaultPrompt,
    this.sourceDocPath,
    this.sourceDocContent,
    this.selectedAgentIds = const {},
    this.isStarting = false,
  });

  ParallelSetupState copyWith({
    String? title,
    String? prompt,
    String? sourceDocPath,
    String? sourceDocContent,
    Set<String>? selectedAgentIds,
    bool? isStarting,
    bool clearSourceDoc = false,
  }) {
    return ParallelSetupState(
      title: title ?? this.title,
      prompt: prompt ?? this.prompt,
      sourceDocPath: clearSourceDoc ? null : (sourceDocPath ?? this.sourceDocPath),
      sourceDocContent: clearSourceDoc ? null : (sourceDocContent ?? this.sourceDocContent),
      selectedAgentIds: selectedAgentIds ?? this.selectedAgentIds,
      isStarting: isStarting ?? this.isStarting,
    );
  }

  static const _defaultPrompt = '''당신은 시니어 소프트웨어 엔지니어입니다.
위의 기준 문서를 분석하고, 아래 항목을 포함한 실행 계획을 작성하세요.

## 필수 출력 항목
1. 입력 유형 판별 (버그/기능/리팩터링 등)
2. 우선순위 보드 (표)
3. 작업 항목별 분석 (관련 파일, 접근 방식, 리스크)
4. 검증 계획
5. 다음 작업자가 첫 30분 안에 볼 것

## 규칙
- 한국어 Markdown으로 작성
- 코드 미검증 시 명시
- 사실과 가정을 분리
''';
}

class ParallelSetupNotifier extends Notifier<ParallelSetupState> {
  @override
  ParallelSetupState build() => const ParallelSetupState();

  void setTitle(String value) => state = state.copyWith(title: value);
  void setPrompt(String value) => state = state.copyWith(prompt: value);

  Future<void> setSourceDocument(String path) async {
    try {
      final content = await File(path).readAsString();
      state = state.copyWith(sourceDocPath: path, sourceDocContent: content);
    } catch (_) {
      state = state.copyWith(sourceDocPath: path);
    }
  }

  void toggleAgent(String agentId, bool selected) {
    final newSet = Set<String>.from(state.selectedAgentIds);
    if (selected) {
      newSet.add(agentId);
    } else {
      newSet.remove(agentId);
    }
    state = state.copyWith(selectedAgentIds: newSet);
  }

  void setIsStarting(bool value) => state = state.copyWith(isStarting: value);

  void clearAfterStart() {
    state = state.copyWith(title: '');
  }
}

final parallelSetupProvider =
    NotifierProvider<ParallelSetupNotifier, ParallelSetupState>(
        ParallelSetupNotifier.new);
