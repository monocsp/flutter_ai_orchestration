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

  /// AI가 계획서를 보고 설정을 자동 결정하기 위한 프롬프트
  static String buildAutoSettingsPrompt({
    required String documentContent,
    required String runObjective,
    required String criticismLevel,
    required String riskFocus,
    required String outputFormat,
  }) {
    final needsObjective = runObjective == autoValue;
    final needsCriticism = criticismLevel == autoValue;
    final needsRisk = riskFocus.isEmpty;
    final needsFormat = outputFormat.isEmpty;

    final buf = StringBuffer();
    buf.writeln('아래 문서를 읽고, 이 문서를 AI 오케스트레이션으로 분석할 때 적합한 설정을 JSON으로 추천하세요.');
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
    buf.writeln(fields.join(',\n'));
    buf.writeln('}');
    buf.writeln('```');
    buf.writeln('');
    buf.writeln('--- 분석 대상 문서 ---');
    buf.writeln(documentContent);

    return buf.toString();
  }
}
