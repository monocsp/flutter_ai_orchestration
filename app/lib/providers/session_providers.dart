import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../core/models/agent_provider.dart';
import '../core/models/orchestration_preset.dart';
import '../core/models/orchestration_stage.dart';
import '../core/models/session_config.dart';
import '../core/services/config_loader_service.dart';
import '../core/services/session_builder_service.dart';
import '../core/services/template_renderer_service.dart';

// Handoff kit path detection
final handoffKitPathProvider = Provider<String>((ref) {
  // flutter run 시 cwd는 app/ 디렉터리
  final cwd = Directory.current.path;
  final candidates = [
    p.join(cwd, 'user_handoff_kit'),              // app/user_handoff_kit
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
  final fallback = p.normalize(p.join(cwd, '..', 'user_handoff_kit'));
  debugPrint('[CONFIG] handoff kit fallback: $fallback (cwd=$cwd)');
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
  final String runObjective;
  final String criticismLevel;
  final String riskFocus;
  final String outputFormat;
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
    this.runObjective = '자동',
    this.criticismLevel = '자동',
    this.riskFocus = '',
    this.outputFormat = '',
    this.importedFiles = const [],
    this.lastArtifact,
    this.isGenerating = false,
  })  : outputRootPath =
            outputRootPath ?? p.join(Directory.current.path, 'output'),
        analysisAgent = analysisAgent ?? AgentProvider.builtIn[1],
        criticAgent = criticAgent ?? AgentProvider.builtIn[0],
        preset = preset ?? OrchestrationPreset.defaults[0],
        stages = stages ?? OrchestrationPreset.defaults[0].stages;

  SessionState copyWith({
    String? sourceDocumentPath,
    String? sourceDocumentContent,
    String? projectRootPath,
    String? outputRootPath,
    AgentProvider? analysisAgent,
    AgentProvider? criticAgent,
    OrchestrationPreset? preset,
    List<OrchestrationStage>? stages,
    String? runObjective,
    String? criticismLevel,
    String? riskFocus,
    String? outputFormat,
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
      runObjective: runObjective ?? this.runObjective,
      criticismLevel: criticismLevel ?? this.criticismLevel,
      riskFocus: riskFocus ?? this.riskFocus,
      outputFormat: outputFormat ?? this.outputFormat,
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

  Future<SessionArtifact?> generateSession() async {
    if (state.sourceDocumentPath == null) return null;

    state = state.copyWith(isGenerating: true);
    try {
      final builder = ref.read(sessionBuilderProvider);
      final config = SessionConfig(
        sourceDocumentPath: state.sourceDocumentPath!,
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
