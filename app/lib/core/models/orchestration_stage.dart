enum StageRole { analysis, critique }

class OrchestrationStage {
  final int stepNumber;
  final String name;
  final String description;
  final StageRole role;
  final String outputFileName;
  final String promptTemplate;
  final bool enabled;

  const OrchestrationStage({
    required this.stepNumber,
    required this.name,
    this.description = '',
    required this.role,
    required this.outputFileName,
    required this.promptTemplate,
    this.enabled = true,
  });

  OrchestrationStage copyWith({
    int? stepNumber,
    String? name,
    String? description,
    StageRole? role,
    String? outputFileName,
    String? promptTemplate,
    bool? enabled,
  }) {
    return OrchestrationStage(
      stepNumber: stepNumber ?? this.stepNumber,
      name: name ?? this.name,
      description: description ?? this.description,
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
      description: '기준 문서를 바탕으로 초기 분석을 수행합니다. '
          '코드 파일 경로, 호출 흐름, 우선순위 보드, 리스크를 정리하고 '
          '다음 라운드에서 검증할 포인트를 도출합니다.',
      role: StageRole.analysis,
      outputFileName: '01_analysis_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 2,
      name: '1차 비판 검토',
      description: '이전 분석을 신뢰하지 않고 재검증합니다. '
          '잘못 짚은 파일, 누락된 호출 경로, 과도한 수정안을 지적하고 '
          '더 안전하고 단순한 대안을 제시합니다.',
      role: StageRole.critique,
      outputFileName: '02_critical_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 3,
      name: '분석 보강',
      description: '비판 검토에서 지적된 문제를 반영하여 분석을 보강합니다. '
          '누락된 파일, 약한 근거, 잘못된 가정을 수정하고 '
          '더 정확한 분석안을 작성합니다.',
      role: StageRole.analysis,
      outputFileName: '03_reinforced_analysis_prompt.md',
      promptTemplate: 'reinforced_analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 4,
      name: '2차 비판 검토',
      description: '보강된 분석을 다시 한번 검증합니다. '
          '남아있는 약점, 회귀 위험, 테스트 누락을 점검하고 '
          '최종 계획으로 넘길 핵심 수정 사항을 정리합니다.',
      role: StageRole.critique,
      outputFileName: '04_second_review_prompt.md',
      promptTemplate: 'second_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 5,
      name: '최종 종합안 작성',
      description: '모든 분석과 비판을 종합하여 최종 실행 계획을 작성합니다. '
          '채택/기각 판단, 작업 순서, 검증 계획, 보류 항목을 포함한 '
          '바로 착수 가능한 계획서를 생성합니다.',
      role: StageRole.analysis,
      outputFileName: '05_final_plan_prompt.md',
      promptTemplate: 'final_plan_prompt.md',
    ),
  ];

  static const List<OrchestrationStage> legacyThreeStages = [
    OrchestrationStage(
      stepNumber: 1,
      name: '1차 분석',
      description: '기준 문서 기반 초기 분석. 파일 경로, 우선순위, 리스크를 정리합니다.',
      role: StageRole.analysis,
      outputFileName: '01_analysis_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 2,
      name: '비판 검토',
      description: '분석의 오류와 누락을 지적하고 더 안전한 대안을 제시합니다.',
      role: StageRole.critique,
      outputFileName: '02_critical_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 3,
      name: '최종 계획',
      description: '분석과 비판을 종합하여 바로 실행 가능한 최종 계획서를 작성합니다.',
      role: StageRole.analysis,
      outputFileName: '03_final_plan_prompt.md',
      promptTemplate: 'final_plan_prompt.md',
    ),
  ];

  static const List<OrchestrationStage> qaBugStages = [
    OrchestrationStage(
      stepNumber: 1,
      name: '버그 분석',
      description: '버그 증상과 관련 코드를 분석하여 원인 가설을 도출합니다.',
      role: StageRole.analysis,
      outputFileName: '01_bug_analysis_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 2,
      name: '원인 검증',
      description: '분석된 원인 가설을 검증하고 잘못된 추측을 제거합니다.',
      role: StageRole.critique,
      outputFileName: '02_cause_verification_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 3,
      name: '수정 계획',
      description: '검증된 원인을 바탕으로 구체적인 수정 방안을 설계합니다.',
      role: StageRole.analysis,
      outputFileName: '03_fix_plan_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 4,
      name: '회귀 검토',
      description: '수정이 다른 기능에 영향을 주지 않는지 회귀 위험을 점검합니다.',
      role: StageRole.critique,
      outputFileName: '04_regression_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 5,
      name: '최종 수정안',
      description: '모든 검증을 반영한 최종 버그 수정 계획서를 작성합니다.',
      role: StageRole.analysis,
      outputFileName: '05_final_fix_prompt.md',
      promptTemplate: 'final_plan_prompt.md',
    ),
  ];

  static const List<OrchestrationStage> featureReviewStages = [
    OrchestrationStage(
      stepNumber: 1,
      name: '기능 분석',
      description: '요구사항을 분석하고 구현에 필요한 파일과 영향 범위를 파악합니다.',
      role: StageRole.analysis,
      outputFileName: '01_feature_analysis_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 2,
      name: '실현 가능성 비판',
      description: '기술적 실현 가능성, 복잡도, 숨겨진 의존성을 비판적으로 검토합니다.',
      role: StageRole.critique,
      outputFileName: '02_feasibility_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 3,
      name: '설계 보강',
      description: '비판을 반영하여 설계를 보강하고 대안을 비교합니다.',
      role: StageRole.analysis,
      outputFileName: '03_design_reinforcement_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 4,
      name: '리스크 검토',
      description: '보강된 설계의 리스크, 성능 영향, 하위 호환성을 점검합니다.',
      role: StageRole.critique,
      outputFileName: '04_risk_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 5,
      name: '최종 기획안',
      description: '모든 검토를 종합한 최종 기능 구현 계획서를 작성합니다.',
      role: StageRole.analysis,
      outputFileName: '05_final_feature_prompt.md',
      promptTemplate: 'final_plan_prompt.md',
    ),
  ];

  static const List<OrchestrationStage> refactorStages = [
    OrchestrationStage(
      stepNumber: 1,
      name: '현행 분석',
      description: '현재 코드 구조와 문제점을 분석하고 개선 대상을 파악합니다.',
      role: StageRole.analysis,
      outputFileName: '01_current_analysis_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 2,
      name: '구조 비판',
      description: '분석된 개선안의 과도함이나 누락을 비판적으로 검토합니다.',
      role: StageRole.critique,
      outputFileName: '02_structure_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 3,
      name: '리팩터링 설계',
      description: '비판을 반영한 구체적인 리팩터링 설계안을 작성합니다.',
      role: StageRole.analysis,
      outputFileName: '03_refactor_design_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 4,
      name: '영향 검토',
      description: '리팩터링이 기존 기능에 미치는 영향과 회귀 위험을 검토합니다.',
      role: StageRole.critique,
      outputFileName: '04_impact_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 5,
      name: '최종 리팩터링 계획',
      description: '모든 검토를 종합한 최종 리팩터링 실행 계획서를 작성합니다.',
      role: StageRole.analysis,
      outputFileName: '05_final_refactor_prompt.md',
      promptTemplate: 'final_plan_prompt.md',
    ),
  ];
}
