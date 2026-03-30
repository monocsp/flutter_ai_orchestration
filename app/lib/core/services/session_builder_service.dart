import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/session_config.dart';
import '../models/orchestration_stage.dart';
import '../models/template_preset.dart';
import 'config_loader_service.dart';
import 'template_renderer_service.dart';

class SessionArtifact {
  final String sessionDirPath;
  final String resultsDirPath;
  final String promptsDirPath;
  final String memosDirPath;
  final String metaDirPath;
  final String sessionSummaryPath;
  final String executionGuidePath;
  final List<String> promptPaths;
  final List<String> resultPlaceholderPaths;

  const SessionArtifact({
    required this.sessionDirPath,
    required this.resultsDirPath,
    required this.promptsDirPath,
    required this.memosDirPath,
    required this.metaDirPath,
    required this.sessionSummaryPath,
    required this.executionGuidePath,
    required this.promptPaths,
    required this.resultPlaceholderPaths,
  });
}

class SessionBuilderService {
  final ConfigLoaderService configLoader;
  final TemplateRendererService templateRenderer;

  SessionBuilderService({
    required this.configLoader,
    required this.templateRenderer,
  });

  Future<SessionArtifact> buildSession(SessionConfig config) async {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    final createdAt =
        '${now.year}-${_pad(now.month)}-${_pad(now.day)} ${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}';

    final docBaseName = _sanitizeName(
      p.basenameWithoutExtension(config.sourceDocumentPath),
    );

    final sessionDir =
        p.join(config.outputRootPath, 'session_${timestamp}_$docBaseName');

    // 하위 디렉터리 생성
    final resultsDir = p.join(sessionDir, 'results');
    final promptsDir = p.join(sessionDir, 'prompts');
    final memosDir = p.join(sessionDir, 'memos');
    final metaDir = p.join(sessionDir, 'meta');

    await Future.wait([
      Directory(resultsDir).create(recursive: true),
      Directory(promptsDir).create(recursive: true),
      Directory(memosDir).create(recursive: true),
      Directory(metaDir).create(recursive: true),
    ]);

    final promptPaths = <String>[];
    final resultPaths = <String>[];

    final enabledStages =
        config.stages.where((s) => s.enabled).toList();

    for (final stage in enabledStages) {
      final promptPath = p.join(promptsDir, stage.outputFileName);
      final resultFileName = stage.outputFileName
          .replaceFirst(RegExp(r'^\d+_'), '${_resultPrefix(stage.stepNumber)}_')
          .replaceFirst('_prompt.md', '_result.md');
      final resultPath = p.join(resultsDir, resultFileName);

      // 직접입력이면 customPromptContent 사용, 아니면 프리셋별 템플릿 로드
      final template = stage.templatePreset == TemplatePreset.custom
          ? (stage.customPromptContent ?? '')
          : await configLoader.loadTemplateForPreset(
              stage.promptTemplate, stage.templatePreset);
      final rendered = templateRenderer.render(template, {
        'SOURCE_DOCUMENT_PATH': config.sourceDocumentPath,
        'PROVIDER_NAME': stage.role == StageRole.analysis
            ? config.analysisAgent.displayName
            : config.criticAgent.displayName,
        'RUN_OBJECTIVE': config.runObjective,
        'CRITICISM_LEVEL': config.criticismLevel,
        'RISK_FOCUS': config.riskFocus,
        'OUTPUT_FORMAT': config.outputFormat,
        'SESSION_CREATED_AT': createdAt,
        'ANALYSIS_RESULT_PATH': enabledStages.isNotEmpty
            ? '${_resultPrefix(1)}_analysis_result.md'
            : '',
        'CRITICAL_REVIEW_RESULT_PATH': enabledStages.length > 1
            ? '${_resultPrefix(2)}_critical_review_result.md'
            : '',
      });

      await File(promptPath).writeAsString(rendered);
      await _writeResultPlaceholder(resultPath, stage.name, createdAt);

      promptPaths.add(promptPath);
      resultPaths.add(resultPath);
    }

    final summaryPath = p.join(metaDir, '00_session_summary.md');
    await File(summaryPath).writeAsString(_buildSummary(config, createdAt, enabledStages));

    final guidePath = p.join(metaDir, '04_execution_guide.md');
    await File(guidePath).writeAsString(
      _buildExecutionGuide(config, createdAt),
    );

    return SessionArtifact(
      sessionDirPath: sessionDir,
      resultsDirPath: resultsDir,
      promptsDirPath: promptsDir,
      memosDirPath: memosDir,
      metaDirPath: metaDir,
      sessionSummaryPath: summaryPath,
      executionGuidePath: guidePath,
      promptPaths: promptPaths,
      resultPlaceholderPaths: resultPaths,
    );
  }

  String _buildSummary(
      SessionConfig config, String createdAt, List<OrchestrationStage> stages) {
    final stageFiles = stages
        .map((s) => '- ${s.outputFileName}')
        .join('\n');
    return '''# 세션 요약

- 생성 시각: $createdAt
- 기준 문서: ${config.sourceDocumentPath}
- 참고 프로젝트: ${config.projectRootPath ?? '(없음)'}
- 분석 AI: ${config.analysisAgent.displayName}
- 검토 AI: ${config.criticAgent.displayName}
- 프리셋: ${config.preset.name}
- 실행 목적: ${config.runObjective}
- 비판 검토 강도: ${config.criticismLevel}
- 리스크 포커스: ${config.riskFocus}
- 결과 형식: ${config.outputFormat}

## 폴더 구조
- results/ — 각 단계의 분석/검토 결과 본문
- prompts/ — 각 단계에 사용된 프롬프트
- memos/  — AI의 분석 과정 메모
- meta/   — 세션 요약, 실행 가이드, Agent 확인, 설정 분석

## 생성 파일
$stageFiles
- 04_execution_guide.md
''';
  }

  String _buildExecutionGuide(SessionConfig config, String createdAt) {
    return '''# 실행 가이드

## 1. 이번 세션 설정
- 기준 문서: ${config.sourceDocumentPath}
- 분석 AI: ${config.analysisAgent.displayName}
- 검토 AI: ${config.criticAgent.displayName}
- 실행 목적: ${config.runObjective}
- 비판 검토 강도: ${config.criticismLevel}
- 꼭 확인할 리스크: ${config.riskFocus}
- 원하는 결과 형식: ${config.outputFormat}

## 2. 라운드별 실행 순서
1. AI CLI에서 대상 프로젝트를 열거나, 최소한 기준 문서와 관련 코드에 접근 가능한 상태를 만듭니다.
2. 각 단계의 프롬프트 파일과 기준 문서를 함께 넣어 분석/검토를 받습니다.
3. 받은 답변을 해당 단계의 결과 파일에 저장합니다.
4. 다음 단계에서는 이전 결과를 함께 제공합니다.

## 3. 대화 중 반드시 지킬 운영 규칙
- 파일 경로를 추측으로 쓰지 말고 실제 경로인지 후보 경로인지 구분하게 하세요.
- 사실과 가정을 섞으면 다시 분리해서 작성하게 하세요.
- 공통 컴포넌트, 상태 관리, 라이프사이클, 비동기 타이밍, 회귀 포인트가 빠지면 보완하게 하세요.
- 코드에 직접 접근하지 못한 답변이면 코드 미검증 또는 검증 불가를 명시하게 하세요.
- 최종 결과에는 구현 순서와 검증 순서가 모두 있어야 합니다.

## 4. 저장 규칙
- 원문 요약본을 따로 만들지 말고, AI가 준 원문을 먼저 저장한 뒤 필요하면 사본을 만드세요.
''';
  }

  Future<void> _writeResultPlaceholder(
      String path, String title, String createdAt) async {
    final fileName = p.basename(path);
    await File(path).writeAsString('''# $title

이 파일에는 AI CLI에서 받은 결과를 붙여넣으세요.

- 생성 시각: $createdAt
- 저장 파일: $fileName
''');
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _resultPrefix(int step) => (step + 10).toString();

  String _sanitizeName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣_.\-]'), '_');
  }
}
