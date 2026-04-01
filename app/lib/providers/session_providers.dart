import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../core/models/agent_provider.dart';
import '../core/models/orchestration_preset.dart';
import '../core/models/orchestration_stage.dart';
import '../core/models/session_config.dart';
import '../core/models/template_preset.dart';
import '../core/services/config_loader_service.dart';
import '../core/services/session_builder_service.dart';
import '../core/services/template_renderer_service.dart';

/// 실행 파일이 위치한 디렉토리 (인스톨러 배포 시에도 올바르게 동작)
String _resolveAppDir() {
  final exePath = Platform.resolvedExecutable;
  return p.dirname(exePath);
}

/// 사용자 데이터를 저장할 디렉토리 (output, logs 등)
/// Program Files는 쓰기 권한이 없으므로 사용자 문서 폴더 사용
String _resolveDataDir() {
  if (Platform.isWindows) {
    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    if (userProfile.isNotEmpty) {
      return p.join(userProfile, 'Documents', 'AI Orchestration');
    }
  }
  // macOS/Linux 또는 폴백: exe와 같은 디렉토리
  return _resolveAppDir();
}

// Handoff kit path detection
final handoffKitPathProvider = Provider<String>((ref) {
  final appDir = _resolveAppDir();
  final cwd = Directory.current.path;
  final candidates = [
    p.join(appDir, 'user_handoff_kit'),            // exe와 같은 디렉토리 (인스톨러)
    p.join(cwd, 'user_handoff_kit'),               // CWD (flutter run: app/)
    p.join(p.dirname(cwd), 'user_handoff_kit'),    // 프로젝트루트/user_handoff_kit
    p.join(cwd, '..', 'user_handoff_kit'),         // 상대경로
  ];
  for (final c in candidates) {
    final resolved = p.normalize(c);
    if (Directory(resolved).existsSync()) {
      debugPrint('[CONFIG] handoff kit found: $resolved');
      return resolved;
    }
  }
  final fallback = p.normalize(p.join(appDir, 'user_handoff_kit'));
  debugPrint('[CONFIG] handoff kit fallback: $fallback (appDir=$appDir, cwd=$cwd)');
  return fallback;
});

final configLoaderProvider = Provider<ConfigLoaderService>((ref) {
  final kitPath = ref.watch(handoffKitPathProvider);
  return ConfigLoaderService(configDirPath: p.join(kitPath, 'config'));
});

final templateRendererProvider = Provider<TemplateRendererService>((ref) {
  return TemplateRendererService();
});

final sessionBuilderProvider = Provider<SessionBuilderService>((ref) {
  return SessionBuilderService(
    configLoader: ref.watch(configLoaderProvider),
    templateRenderer: ref.watch(templateRendererProvider),
  );
});

final providerConfigsProvider =
    FutureProvider<Map<String, AgentProvider>>((ref) {
  return ref.watch(configLoaderProvider).loadProviderConfigs();
});

// Session state
class SessionState {
  final String? sourceDocumentPath;
  final String? sourceDocumentContent;
  final String? projectRootPath;
  final String outputRootPath;
  final AgentProvider analysisAgent;
  final AgentProvider criticAgent;
  final OrchestrationPreset preset;
  final List<OrchestrationStage> stages;
  final String analysisMode; // 'code' | 'planning' | 'executive' | 'prompt_eng' | 'custom'
  final String runObjective;
  final String criticismLevel;
  final String riskFocus;
  final String outputFormat;
  final String userResultRequest; // 유저가 원하는 결과 요청
  final String? autoPersona; // AI가 자동 생성한 페르소나
  final List<String>? autoFocusPoints; // AI가 자동 생성한 집중 포인트
  final List<String> importedFiles;
  final SessionArtifact? lastArtifact;
  final bool isGenerating;

  SessionState({
    this.sourceDocumentPath,
    this.sourceDocumentContent,
    this.projectRootPath,
    String? outputRootPath,
    AgentProvider? analysisAgent,
    AgentProvider? criticAgent,
    OrchestrationPreset? preset,
    List<OrchestrationStage>? stages,
    this.analysisMode = 'planning',
    this.runObjective = '자동',
    this.criticismLevel = '자동',
    this.riskFocus = '',
    this.outputFormat = '',
    this.userResultRequest = '',
    this.autoPersona,
    this.autoFocusPoints,
    this.importedFiles = const [],
    this.lastArtifact,
    this.isGenerating = false,
  })  : outputRootPath =
            outputRootPath ?? p.join(_resolveDataDir(), 'output'),
        analysisAgent = analysisAgent ?? AgentProvider.builtIn[1],
        criticAgent = criticAgent ?? AgentProvider.builtIn[0],
        preset = preset ?? OrchestrationPreset.defaults[1],  // 5단계 기본
        stages = stages ?? OrchestrationPreset.defaults[1].stages;

  SessionState copyWith({
    String? sourceDocumentPath,
    String? sourceDocumentContent,
    String? projectRootPath,
    String? outputRootPath,
    AgentProvider? analysisAgent,
    AgentProvider? criticAgent,
    OrchestrationPreset? preset,
    List<OrchestrationStage>? stages,
    String? analysisMode,
    String? runObjective,
    String? criticismLevel,
    String? riskFocus,
    String? outputFormat,
    String? userResultRequest,
    String? autoPersona,
    List<String>? autoFocusPoints,
    List<String>? importedFiles,
    SessionArtifact? lastArtifact,
    bool? isGenerating,
  }) {
    return SessionState(
      sourceDocumentPath: sourceDocumentPath ?? this.sourceDocumentPath,
      sourceDocumentContent:
          sourceDocumentContent ?? this.sourceDocumentContent,
      projectRootPath: projectRootPath ?? this.projectRootPath,
      outputRootPath: outputRootPath ?? this.outputRootPath,
      analysisAgent: analysisAgent ?? this.analysisAgent,
      criticAgent: criticAgent ?? this.criticAgent,
      preset: preset ?? this.preset,
      stages: stages ?? this.stages,
      analysisMode: analysisMode ?? this.analysisMode,
      runObjective: runObjective ?? this.runObjective,
      criticismLevel: criticismLevel ?? this.criticismLevel,
      riskFocus: riskFocus ?? this.riskFocus,
      outputFormat: outputFormat ?? this.outputFormat,
      userResultRequest: userResultRequest ?? this.userResultRequest,
      autoPersona: autoPersona ?? this.autoPersona,
      autoFocusPoints: autoFocusPoints ?? this.autoFocusPoints,
      importedFiles: importedFiles ?? this.importedFiles,
      lastArtifact: lastArtifact ?? this.lastArtifact,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() => SessionState();

  Future<void> setSourceDocument(String path) async {
    try {
      final content = await File(path).readAsString();
      state = state.copyWith(
        sourceDocumentPath: path,
        sourceDocumentContent: content,
        importedFiles: {...state.importedFiles, path}.toList(),
      );
    } catch (e) {
      // 파일 읽기 실패해도 경로는 설정
      state = state.copyWith(
        sourceDocumentPath: path,
        importedFiles: {...state.importedFiles, path}.toList(),
      );
    }
  }

  void addImportedFile(String path) {
    state = state.copyWith(
      importedFiles: {...state.importedFiles, path}.toList(),
    );
  }

  void setProjectRoot(String path) {
    state = state.copyWith(projectRootPath: path);
  }

  void setOutputRoot(String path) {
    state = state.copyWith(outputRootPath: path);
  }

  void setAnalysisAgent(AgentProvider agent) {
    state = state.copyWith(analysisAgent: agent);
  }

  void setCriticAgent(AgentProvider agent) {
    state = state.copyWith(criticAgent: agent);
  }

  void setAnalysisMode(String mode) {
    state = state.copyWith(analysisMode: mode);
  }

  void setUserResultRequest(String value) {
    state = state.copyWith(userResultRequest: value);
  }

  void setAutoPersona(String persona) {
    state = state.copyWith(autoPersona: persona);
  }

  void setAutoFocusPoints(List<String> points) {
    state = state.copyWith(autoFocusPoints: points);
  }

  void setPreset(OrchestrationPreset preset) {
    state = state.copyWith(preset: preset, stages: preset.stages);
  }

  void updateStage(int index, OrchestrationStage stage) {
    final newStages = List<OrchestrationStage>.from(state.stages);
    newStages[index] = stage;
    state = state.copyWith(stages: newStages);
  }

  void setRunObjective(String value) =>
      state = state.copyWith(runObjective: value);
  void setCriticismLevel(String value) =>
      state = state.copyWith(criticismLevel: value);
  void setRiskFocus(String value) =>
      state = state.copyWith(riskFocus: value);
  void setOutputFormat(String value) =>
      state = state.copyWith(outputFormat: value);

  /// 특정 단계의 템플릿 프리셋 변경
  /// [cascadeFromFirst]: true면 1단계 변경 시 수동 편집 안 된 단계도 함께 변경
  void setStageTemplatePreset(int index, TemplatePreset preset, {bool cascadeFromFirst = false}) {
    final newStages = List<OrchestrationStage>.from(state.stages);
    newStages[index] = newStages[index].copyWith(
      templatePreset: preset,
      manuallyEdited: true,
      customPromptContent: preset == TemplatePreset.custom
          ? newStages[index].customPromptContent
          : null,
    );

    if (cascadeFromFirst && index == 0) {
      // 1단계 변경 → 수동 편집 안 된 나머지 단계도 함께 변경
      for (var i = 1; i < newStages.length; i++) {
        if (!newStages[i].manuallyEdited) {
          newStages[i] = newStages[i].copyWith(
            templatePreset: preset,
            customPromptContent: null,
          );
        }
      }
    }

    state = state.copyWith(stages: newStages);
  }

  /// 특정 단계의 직접입력 프롬프트 내용 변경
  void setStageCustomPrompt(int index, String content) {
    final newStages = List<OrchestrationStage>.from(state.stages);
    newStages[index] = newStages[index].copyWith(
      templatePreset: TemplatePreset.custom,
      manuallyEdited: true,
      customPromptContent: content,
    );
    state = state.copyWith(stages: newStages);
  }

  Future<SessionArtifact?> generateSession() async {
    if (state.sourceDocumentPath == null) return null;

    state = state.copyWith(isGenerating: true);
    try {
      final builder = ref.read(sessionBuilderProvider);
      final config = SessionConfig(
        sourceDocumentPath: state.sourceDocumentPath!,
        sourceDocumentContent: state.sourceDocumentContent,
        projectRootPath: state.projectRootPath,
        outputRootPath: state.outputRootPath,
        analysisAgent: state.analysisAgent,
        criticAgent: state.criticAgent,
        preset: state.preset,
        stages: state.stages,
        runObjective: state.runObjective,
        criticismLevel: state.criticismLevel,
        riskFocus: state.riskFocus,
        outputFormat: state.outputFormat,
        analysisMode: state.analysisMode,
        userResultRequest: state.userResultRequest,
        persona: state.autoPersona ?? '',
        focusPoints: state.autoFocusPoints ?? [],
      );
      final artifact = await builder.buildSession(config);
      state = state.copyWith(lastArtifact: artifact, isGenerating: false);
      return artifact;
    } catch (e) {
      state = state.copyWith(isGenerating: false);
      rethrow;
    }
  }
}

final sessionProvider =
    NotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);
