import 'orchestration_stage.dart';

class OrchestrationPreset {
  final String id;
  final String name;
  final String description;
  final List<OrchestrationStage> stages;

  const OrchestrationPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.stages,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrchestrationPreset && other.id == id;

  @override
  int get hashCode => id.hashCode;

  static List<OrchestrationPreset> get defaults => [
        OrchestrationPreset(
          id: 'quick_3stage',
          name: '빠른 3단계 경량형',
          description: '분석 → 비판 → 최종 계획',
          stages: OrchestrationStage.legacyThreeStages,
        ),
        OrchestrationPreset(
          id: 'default_5stage',
          name: '기본 5단계 비판형',
          description: '분석 → 비판 → 보강 → 재비판 → 최종 종합',
          stages: OrchestrationStage.defaultFiveStages,
        ),
        OrchestrationPreset(
          id: 'deep_7stage',
          name: '정밀 7단계 심화형',
          description: '분석 → 비판 → 보강 → 재비판 → 심화 → 3차 비판 → 최종 종합',
          stages: OrchestrationStage.deepSevenStages,
        ),
        OrchestrationPreset(
          id: 'qa_bug',
          name: 'QA/버그 대응형',
          description: '버그 분석 → 원인 검증 → 수정 계획 → 회귀 검토 → 최종',
          stages: OrchestrationStage.qaBugStages,
        ),
        OrchestrationPreset(
          id: 'feature_review',
          name: '기능 기획 검증형',
          description: '기능 분석 → 실현 가능성 비판 → 설계 보강 → 리스크 검토 → 최종',
          stages: OrchestrationStage.featureReviewStages,
        ),
        OrchestrationPreset(
          id: 'refactor',
          name: '리팩터링 계획형',
          description: '현행 분석 → 구조 비판 → 리팩터링 설계 → 영향 검토 → 최종',
          stages: OrchestrationStage.refactorStages,
        ),
      ];
}
