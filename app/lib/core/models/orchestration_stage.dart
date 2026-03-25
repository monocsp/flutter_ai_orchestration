enum StageRole { analysis, critique }

class OrchestrationStage {
  final int stepNumber;
  final String name;
  final StageRole role;
  final String outputFileName;
  final String promptTemplate;
  final bool enabled;

  const OrchestrationStage({
    required this.stepNumber,
    required this.name,
    required this.role,
    required this.outputFileName,
    required this.promptTemplate,
    this.enabled = true,
  });

  OrchestrationStage copyWith({
    int? stepNumber,
    String? name,
    StageRole? role,
    String? outputFileName,
    String? promptTemplate,
    bool? enabled,
  }) {
    return OrchestrationStage(
      stepNumber: stepNumber ?? this.stepNumber,
      name: name ?? this.name,
      role: role ?? this.role,
      outputFileName: outputFileName ?? this.outputFileName,
      promptTemplate: promptTemplate ?? this.promptTemplate,
      enabled: enabled ?? this.enabled,
    );
  }

  static const List<OrchestrationStage> defaultFiveStages = [
    OrchestrationStage(
      stepNumber: 1,
      name: '1차 분석',
      role: StageRole.analysis,
      outputFileName: '01_analysis_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 2,
      name: '1차 비판 검토',
      role: StageRole.critique,
      outputFileName: '02_critical_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 3,
      name: '분석 보강',
      role: StageRole.analysis,
      outputFileName: '03_reinforced_analysis_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 4,
      name: '2차 비판 검토',
      role: StageRole.critique,
      outputFileName: '04_second_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 5,
      name: '최종 종합안 작성',
      role: StageRole.analysis,
      outputFileName: '05_final_plan_prompt.md',
      promptTemplate: 'final_plan_prompt.md',
    ),
  ];

  static const List<OrchestrationStage> legacyThreeStages = [
    OrchestrationStage(
      stepNumber: 1,
      name: '1차 분석',
      role: StageRole.analysis,
      outputFileName: '01_analysis_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 2,
      name: '비판 검토',
      role: StageRole.critique,
      outputFileName: '02_critical_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 3,
      name: '최종 계획',
      role: StageRole.analysis,
      outputFileName: '03_final_plan_prompt.md',
      promptTemplate: 'final_plan_prompt.md',
    ),
  ];

  static const List<OrchestrationStage> qaBugStages = [
    OrchestrationStage(
      stepNumber: 1,
      name: '버그 분석',
      role: StageRole.analysis,
      outputFileName: '01_bug_analysis_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 2,
      name: '원인 검증',
      role: StageRole.critique,
      outputFileName: '02_cause_verification_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 3,
      name: '수정 계획',
      role: StageRole.analysis,
      outputFileName: '03_fix_plan_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 4,
      name: '회귀 검토',
      role: StageRole.critique,
      outputFileName: '04_regression_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 5,
      name: '최종 수정안',
      role: StageRole.analysis,
      outputFileName: '05_final_fix_prompt.md',
      promptTemplate: 'final_plan_prompt.md',
    ),
  ];

  static const List<OrchestrationStage> featureReviewStages = [
    OrchestrationStage(
      stepNumber: 1,
      name: '기능 분석',
      role: StageRole.analysis,
      outputFileName: '01_feature_analysis_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 2,
      name: '실현 가능성 비판',
      role: StageRole.critique,
      outputFileName: '02_feasibility_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 3,
      name: '설계 보강',
      role: StageRole.analysis,
      outputFileName: '03_design_reinforcement_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 4,
      name: '리스크 검토',
      role: StageRole.critique,
      outputFileName: '04_risk_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 5,
      name: '최종 기획안',
      role: StageRole.analysis,
      outputFileName: '05_final_feature_prompt.md',
      promptTemplate: 'final_plan_prompt.md',
    ),
  ];

  static const List<OrchestrationStage> refactorStages = [
    OrchestrationStage(
      stepNumber: 1,
      name: '현행 분석',
      role: StageRole.analysis,
      outputFileName: '01_current_analysis_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 2,
      name: '구조 비판',
      role: StageRole.critique,
      outputFileName: '02_structure_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 3,
      name: '리팩터링 설계',
      role: StageRole.analysis,
      outputFileName: '03_refactor_design_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 4,
      name: '영향 검토',
      role: StageRole.critique,
      outputFileName: '04_impact_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 5,
      name: '최종 리팩터링 계획',
      role: StageRole.analysis,
      outputFileName: '05_final_refactor_prompt.md',
      promptTemplate: 'final_plan_prompt.md',
    ),
  ];
}
