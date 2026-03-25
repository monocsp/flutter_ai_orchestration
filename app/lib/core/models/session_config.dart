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

  static const List<String> runObjectives = [
    '비판 검토 포함 실행 계획',
    'QA/버그 대응 분석',
    '기능 기획 검증',
    '리팩터링 계획',
    '기타',
  ];

  static const List<String> criticismLevels = [
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
  ];
}
