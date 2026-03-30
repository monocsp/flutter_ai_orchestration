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
          name: '3단계 (빠른 분석)',
          description: '분석 → 비판 → 최종 계획. 단순한 문서나 빠른 결과가 필요할 때.',
          stages: OrchestrationStage.threeStages,
        ),
        OrchestrationPreset(
          id: 'default_5stage',
          name: '5단계 (기본)',
          description: '분석 → 비판 → 보강 → 재비판 → 최종. 대부분의 문서에 적합.',
          stages: OrchestrationStage.fiveStages,
        ),
        OrchestrationPreset(
          id: 'deep_7stage',
          name: '7단계 (정밀 심화)',
          description: '분석 → 비판 → 보강 → 재비판 → 심화 → 3차 비판 → 최종. 복잡하거나 중요한 문서에.',
          stages: OrchestrationStage.sevenStages,
        ),
      ];
}
