import 'agent_provider.dart';
import 'orchestration_preset.dart';
import 'orchestration_stage.dart';

class SessionConfig {
  final String sourceDocumentPath;
  final String? projectRootPath;
  final String outputRootPath;
  final AgentProvider analysisAgent;
  final AgentProvider criticAgent;
  final OrchestrationPreset preset;
  final List<OrchestrationStage> stages;
  final String runObjective;
  final String criticismLevel;
  final String riskFocus;
  final String outputFormat;

  final String analysisMode;
  final String userResultRequest;
  final String persona;
  final List<String> focusPoints;

  const SessionConfig({
    required this.sourceDocumentPath,
    this.projectRootPath,
    required this.outputRootPath,
    required this.analysisAgent,
    required this.criticAgent,
    required this.preset,
    required this.stages,
    required this.runObjective,
    required this.criticismLevel,
    required this.riskFocus,
    required this.outputFormat,
    this.analysisMode = 'planning',
    this.userResultRequest = '',
    this.persona = '',
    this.focusPoints = const [],
  });

  static const String autoValue = '자동';

  static const List<String> runObjectives = [
    '자동',
    '비판 검토 포함 실행 계획',
    'QA/버그 대응 분석',
    '기능 기획 검증',
    '리팩터링 계획',
    '경영진 피드백 분석',
    'UX/기획 검증',
    '기타',
  ];

  static const List<String> criticismLevels = [
    '자동',
    '낮음',
    '보통',
    '높음',
    '매우 높음',
  ];

  static const List<String> outputFormats = [
    '간결한 실행 계획',
    '상세 실행 계획',
    '리스크 중심 검토서',
    'QA 체크리스트 포함 결과',
    '의사결정 로그 포함 결과',
    '경영진 피드백 분석서',
    '기획 실행 로드맵',
  ];

  /// 기획 계열 실행 목적인지 판별
  static bool isPlanningObjective(String objective) {
    return const {
      '경영진 피드백 분석',
      'UX/기획 검증',
      '기능 기획 검증',
    }.contains(objective);
  }

  /// 실행 목적에 따른 리스크 포커스 기본값
  static String defaultRiskFocus(String objective) {
    if (isPlanningObjective(objective)) {
      return '의도 왜곡, 요구사항 누락, 실행 가능성, 이해관계자 해석 차이, 측정 기준 부재, MVP 범위 불명확';
    }
    return '공통 컴포넌트 영향, 상태 관리, 라이프사이클, 회귀 위험';
  }

  /// 설정 항목별 도움말
  static const Map<String, String> helpTexts = {
    'settings': '프롬프트만으로도 오케스트레이션이 가능하지만, 설정을 조정하면 분석 깊이와 방향을 제어할 수 있습니다. 모든 항목에 기본값이 있으므로 변경하지 않아도 됩니다.',
    'title': '이 오케스트레이션 실행을 구분하는 이름입니다. 비워두면 자동으로 번호가 부여됩니다.',
    'sourceDocument': '분석할 기준 문서입니다. 기획서, QA 이슈, 버그 리포트, 경영진 피드백 등 어떤 문서든 가능합니다.',
    'projectRoot': 'AI가 코드를 직접 확인할 수 있는 프로젝트 폴더입니다. 기획 문서 분석 시에는 비워둬도 됩니다.',
    'outputRoot': '분석 결과가 저장될 폴더입니다.',
    'preset': '분석 단계 수와 흐름을 결정합니다. 5단계가 가장 정밀하고, 3단계는 빠르게 결과를 얻을 때 적합합니다.',
    'analysisAgent': '문서를 분석하고 계획을 수립하는 AI입니다. Step 1, 3, 5에서 사용됩니다.',
    'criticAgent': '분석 결과를 비판적으로 검증하는 AI입니다. Step 2, 4에서 사용됩니다. 분석 AI와 다른 AI를 쓰면 더 객관적인 검증이 가능합니다.',
    'runObjective': '분석의 목적에 따라 프롬프트 방향이 달라집니다. 예: 경영진 피드백 → 의도/긍정·부정 평가 분석, QA/버그 → 재현·원인·수정 중심.',
    'criticismLevel': 'AI가 얼마나 엄격하게 이전 분석을 비판할지 결정합니다. 높을수록 더 많은 오류와 누락을 찾아내지만 시간이 더 걸립니다.',
    'riskFocus': 'AI가 반드시 깊이 확인해야 할 리스크 영역입니다. 이 항목이 비어있으면 AI가 무엇을 중점 분석할지 모르게 됩니다. 실행 목적에 따라 기본값이 자동으로 채워집니다.',
    'outputFormat': '최종 결과물의 형식을 결정합니다. 예: 경영진 피드백 분석서 → 의도·긍정/부정 평가·핵심 요구사항 구조.',
  };

  /// "자동" 설정이 하나라도 있는지 확인
  static bool hasAutoSettings({
    required String runObjective,
    required String criticismLevel,
    required String riskFocus,
    required String outputFormat,
  }) {
    return runObjective == autoValue ||
        criticismLevel == autoValue ||
        outputFormat.isEmpty ||
        riskFocus.isEmpty;
  }

  /// 분석 모드 목록
  static const Map<String, String> analysisModes = {
    'code': '코드/기술 분석',
    'planning': '기획/전략 분석',
    'executive': '경영진 피드백 분석',
    'prompt_eng': '프롬프트 엔지니어링 개선',
    'custom': '직접 설정',
  };

  /// 분석 모드별 기본 결과 요청 텍스트
  static const Map<String, String> defaultResultRequests = {
    'code': '우선순위 보드(표), 작업 항목별 분석(관련 파일, 접근 방식, 리스크), 검증 계획, 다음 작업자가 첫 30분 안에 볼 것을 포함한 실행 계획서를 작성해주세요.',
    'planning': '바로 착수 가능한 최종 실행 계획서를 작성해주세요. 채택/기각 판단, 실행 항목별 우선순위, 측정 가능한 완료 기준, 이해관계자별 액션 아이템을 포함해주세요.',
    'executive': '경영진 피드백 분석서를 작성해주세요. 발신자 의도 정리, 긍정/부정 평가 분리, 명시적 지시 vs 암묵적 기대 구분, 기획자가 자체 판단할 영역과 상위 확인이 필요한 영역을 나눠주세요.',
    'prompt_eng': '최종 개선된 프롬프트 전문을 작성해주세요. Before/After 비교, 각 수정의 근거, 개선 효과 점수표(구조 명확성, 모호성 제거, 할루시네이션 방지, 출력 일관성), 사용 가이드를 포함해주세요.',
  };

  /// 분석 모드에 따른 기본 설정 (프리셋 포함)
  static Map<String, String> defaultsForMode(String mode) {
    switch (mode) {
      case 'code':
        return {
          'templatePreset': 'developer',
          'runObjective': '비판 검토 포함 실행 계획',
          'criticismLevel': '높음',
          'riskFocus': '공통 컴포넌트 영향, 상태 관리, 라이프사이클, 회귀 위험',
        };
      case 'planning':
        return {
          'templatePreset': 'planner',
          'runObjective': '기능 기획 검증',
          'criticismLevel': '높음',
          'riskFocus': '의도 왜곡, 요구사항 누락, 실행 가능성, 이해관계자 해석 차이, 측정 기준 부재',
        };
      case 'executive':
        return {
          'templatePreset': 'executive',
          'runObjective': '경영진 피드백 분석',
          'criticismLevel': '매우 높음',
          'riskFocus': '발신자 의도 왜곡, 명시적 지시 vs 암묵적 기대 혼동, 긍정/부정 평가 분리 누락',
        };
      case 'prompt_eng':
        return {
          'templatePreset': 'promptEng',
          'runObjective': '비판 검토 포함 실행 계획',
          'criticismLevel': '매우 높음',
          'riskFocus': '모호한 지시, 할루시네이션 유발 구조, 누락된 조건, 출력 형식 불명확',
        };
      default: // 'custom'
        return {};
    }
  }

  /// AI가 계획서를 보고 설정 + 페르소나 + 집중포인트를 자동 결정하기 위한 프롬프트
  static String buildAutoSettingsPrompt({
    required String documentContent,
    required String runObjective,
    required String criticismLevel,
    required String riskFocus,
    required String outputFormat,
    required String analysisMode,
    required String userResultRequest,
  }) {
    final needsObjective = runObjective == autoValue;
    final needsCriticism = criticismLevel == autoValue;
    final needsRisk = riskFocus.isEmpty;
    final needsFormat = outputFormat.isEmpty;

    final modeName = analysisModes[analysisMode] ?? analysisMode;

    final buf = StringBuffer();
    buf.writeln('아래 문서를 읽고, 이 문서를 AI 오케스트레이션으로 분석할 때 적합한 설정을 JSON으로 추천하세요.');
    buf.writeln('');
    buf.writeln('분석 모드: $modeName');
    if (userResultRequest.isNotEmpty) {
      buf.writeln('사용자 추가 요청: $userResultRequest');
    }
    buf.writeln('');
    buf.writeln('추천해야 할 항목:');
    if (needsObjective) {
      buf.writeln('- runObjective: 다음 중 하나 선택 → "비판 검토 포함 실행 계획", "QA/버그 대응 분석", "기능 기획 검증", "리팩터링 계획", "경영진 피드백 분석", "UX/기획 검증"');
    }
    if (needsCriticism) {
      buf.writeln('- criticismLevel: 다음 중 하나 선택 → "낮음", "보통", "높음", "매우 높음"');
    }
    if (needsRisk) {
      buf.writeln('- riskFocus: 이 문서를 분석할 때 반드시 깊이 확인해야 할 리스크 영역을 쉼표로 구분하여 작성');
    }
    if (needsFormat) {
      buf.writeln('- outputFormat: 다음 중 하나 선택 → "간결한 실행 계획", "상세 실행 계획", "리스크 중심 검토서", "QA 체크리스트 포함 결과", "의사결정 로그 포함 결과", "경영진 피드백 분석서", "기획 실행 로드맵"');
    }
    buf.writeln('');
    buf.writeln('또한 반드시 아래 항목도 포함하세요:');
    buf.writeln('- persona: 이 문서를 가장 잘 분석할 수 있는 전문가의 페르소나를 작성하세요. 구체적인 전문 분야, 경력, 관점을 포함해야 합니다. 예: "10년차 모바일 UX 전략가이며 감정 기반 서비스의 리텐션 구조에 전문성이 있는 시니어 프로덕트 매니저"');
    buf.writeln('- focusPoints: 이 문서의 핵심 분석 포인트 3~5개를 배열로 작성하세요. 각 포인트는 구체적인 분석 방향이어야 합니다.');
    buf.writeln('');
    buf.writeln('각 선택에 대한 이유도 reason 필드에 한 줄로 작성하세요.');
    buf.writeln('');
    buf.writeln('반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트는 포함하지 마세요:');
    buf.writeln('```json');
    buf.writeln('{');
    final fields = <String>[];
    if (needsObjective) fields.add('  "runObjective": "...", "runObjectiveReason": "..."');
    if (needsCriticism) fields.add('  "criticismLevel": "...", "criticismLevelReason": "..."');
    if (needsRisk) fields.add('  "riskFocus": "...", "riskFocusReason": "..."');
    if (needsFormat) fields.add('  "outputFormat": "...", "outputFormatReason": "..."');
    fields.add('  "persona": "...", "personaReason": "..."');
    fields.add('  "focusPoints": ["...", "...", "..."]');
    buf.writeln(fields.join(',\n'));
    buf.writeln('}');
    buf.writeln('```');
    buf.writeln('');
    buf.writeln('--- 분석 대상 문서 ---');
    buf.writeln(documentContent);

    return buf.toString();
  }

  /// 문서 첫 부분을 읽고 분석 모드를 추천하는 경량 프롬프트
  static String buildModeRecommendPrompt(String documentPreview) {
    return '''아래 문서의 첫 부분을 읽고, 가장 적합한 분석 모드를 JSON으로 추천하세요.

선택지:
- "code": 코드/기술 분석 (버그, 리팩터링, 코드 리뷰 관련 문서)
- "planning": 기획/전략 분석 (기획서, UX 설계, 기능 요구서)
- "executive": 경영진 피드백 분석 (경영진/상위자의 피드백, 리뷰)
- "prompt_eng": 프롬프트 엔지니어링 개선 (AI 프롬프트, 시스템 프롬프트)

반드시 아래 JSON 형식으로만 응답하세요:
```json
{"mode": "...", "reason": "한 줄 이유"}
```

--- 문서 미리보기 ---
$documentPreview''';
  }
}
