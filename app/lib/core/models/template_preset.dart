/// 프롬프트 템플릿 프리셋 유형
enum TemplatePreset {
  developer('개발자용', '코드 파일 경로, 호출 체인, 회귀 테스트, 상태 관리 중심 분석'),
  planner('기획자용', 'MVP 범위, 이해관계자, 성공 지표, 실행 로드맵 중심 분석'),
  executive('경영진 피드백 분석용', '의도 해석, 긍정/부정 분리, must/should/could, 암묵적 기대 분석'),
  custom('직접입력', '프롬프트를 직접 작성합니다');

  final String label;
  final String description;

  const TemplatePreset(this.label, this.description);

  /// 역할별 템플릿 파일명 접두사
  String get prefix {
    switch (this) {
      case TemplatePreset.developer:
        return 'dev';
      case TemplatePreset.planner:
        return 'plan';
      case TemplatePreset.executive:
        return 'exec';
      case TemplatePreset.custom:
        return 'custom';
    }
  }

  /// StageRole에 맞는 템플릿 키를 반환
  String templateKeyFor(String baseTemplate) {
    if (this == TemplatePreset.custom) return baseTemplate;
    return '${prefix}_$baseTemplate';
  }
}
