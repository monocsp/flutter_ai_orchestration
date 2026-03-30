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

  // ─── 3단계 ───

  static const List<OrchestrationStage> threeStages = [
    OrchestrationStage(
      stepNumber: 1,
      name: '1차 분석',
      description: '기준 문서를 바탕으로 초기 분석을 수행합니다. '
          '핵심 쟁점, 우선순위, 리스크를 정리합니다.',
      role: StageRole.analysis,
      outputFileName: '01_analysis_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 2,
      name: '비판 검토',
      description: '1차 분석의 오류와 누락을 지적하고 '
          '더 안전한 대안을 제시합니다.',
      role: StageRole.critique,
      outputFileName: '02_critical_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 3,
      name: '최종 계획',
      description: '분석과 비판을 종합하여 '
          '바로 실행 가능한 최종 계획서를 작성합니다.',
      role: StageRole.analysis,
      outputFileName: '03_final_plan_prompt.md',
      promptTemplate: 'final_plan_prompt.md',
    ),
  ];

  // ─── 5단계 ───

  static const List<OrchestrationStage> fiveStages = [
    OrchestrationStage(
      stepNumber: 1,
      name: '1차 분석',
      description: '기준 문서를 바탕으로 초기 분석을 수행합니다. '
          '핵심 쟁점, 우선순위 보드, 리스크를 정리하고 '
          '다음 라운드에서 검증할 포인트를 도출합니다.',
      role: StageRole.analysis,
      outputFileName: '01_analysis_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 2,
      name: '1차 비판 검토',
      description: '이전 분석을 신뢰하지 않고 재검증합니다. '
          '잘못된 해석, 누락된 관점, 과도한 범위를 지적하고 '
          '더 안전하고 단순한 대안을 제시합니다.',
      role: StageRole.critique,
      outputFileName: '02_critical_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 3,
      name: '분석 보강',
      description: '비판 검토에서 지적된 문제를 반영하여 분석을 보강합니다. '
          '누락된 관점, 약한 근거, 잘못된 가정을 수정하고 '
          '더 정확한 분석안을 작성합니다.',
      role: StageRole.analysis,
      outputFileName: '03_reinforced_analysis_prompt.md',
      promptTemplate: 'reinforced_analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 4,
      name: '2차 비판 검토',
      description: '보강된 분석을 다시 한번 검증합니다. '
          '남아있는 약점, 리스크, 누락을 점검하고 '
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

  // ─── 7단계 ───

  static const List<OrchestrationStage> sevenStages = [
    OrchestrationStage(
      stepNumber: 1,
      name: '1차 분석',
      description: '기준 문서를 바탕으로 초기 분석을 수행합니다. '
          '핵심 쟁점, 우선순위 보드, 리스크를 정리하고 '
          '다음 라운드에서 검증할 포인트를 도출합니다.',
      role: StageRole.analysis,
      outputFileName: '01_analysis_prompt.md',
      promptTemplate: 'analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 2,
      name: '1차 비판 검토',
      description: '이전 분석을 신뢰하지 않고 재검증합니다. '
          '잘못된 해석, 누락된 관점, 과도한 범위를 지적하고 '
          '더 안전하고 단순한 대안을 제시합니다.',
      role: StageRole.critique,
      outputFileName: '02_critical_review_prompt.md',
      promptTemplate: 'critical_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 3,
      name: '분석 보강',
      description: '1차 비판에서 지적된 문제를 반영하여 분석을 보강합니다. '
          '누락된 관점, 약한 근거, 잘못된 가정을 수정합니다.',
      role: StageRole.analysis,
      outputFileName: '03_reinforced_analysis_prompt.md',
      promptTemplate: 'reinforced_analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 4,
      name: '2차 비판 검토',
      description: '보강된 분석을 재검증합니다. '
          '남아있는 약점과 새로 생긴 문제를 점검하고 '
          '심화 분석에서 파고들어야 할 핵심 쟁점을 지정합니다.',
      role: StageRole.critique,
      outputFileName: '04_second_review_prompt.md',
      promptTemplate: 'second_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 5,
      name: '심화 분석',
      description: '2차 비판까지 거친 결과를 바탕으로 가장 복잡하거나 '
          '리스크가 높은 항목을 집중 분석합니다. '
          '실행 가능성, 의존성, 엣지 케이스를 깊이 파고듭니다.',
      role: StageRole.analysis,
      outputFileName: '05_deep_analysis_prompt.md',
      promptTemplate: 'reinforced_analysis_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 6,
      name: '3차 비판 검토',
      description: '심화 분석의 최종 품질을 검증합니다. '
          'GO/HOLD/NO-GO 판정을 내리고, '
          '최종 계획에 반드시 포함할 조건과 경고를 확정합니다.',
      role: StageRole.critique,
      outputFileName: '06_final_review_prompt.md',
      promptTemplate: 'second_review_prompt.md',
    ),
    OrchestrationStage(
      stepNumber: 7,
      name: '최종 종합안 작성',
      description: '3라운드의 분석-비판을 모두 종합하여 최종 실행 계획을 작성합니다. '
          '채택/기각 판단, 작업 순서, 검증 계획, 보류 항목을 포함한 '
          '바로 착수 가능한 계획서를 생성합니다.',
      role: StageRole.analysis,
      outputFileName: '07_final_plan_prompt.md',
      promptTemplate: 'final_plan_prompt.md',
    ),
  ];
}
