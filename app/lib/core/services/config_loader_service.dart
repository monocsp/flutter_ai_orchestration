import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/agent_provider.dart';

class ConfigLoaderService {
  final String configDirPath;

  ConfigLoaderService({required this.configDirPath});

  /// 커스텀 템플릿이 저장되는 디렉터리
  String get _customTemplateDir =>
      p.join(p.dirname(configDirPath), 'templates_custom');

  Future<Map<String, AgentProvider>> loadProviderConfigs() async {
    final configs = <String, AgentProvider>{};
    final dir = Directory(configDirPath);
    if (!await dir.exists()) return configs;

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final provider = AgentProvider.fromJson(json);
          configs[provider.id] = provider;
        } catch (_) {}
      }
    }
    return configs;
  }

  /// 템플릿 로드: 커스텀 버전이 있으면 우선, 없으면 기본 템플릿
  Future<String> loadTemplate(String templateName) async {
    // 1. 커스텀 템플릿 확인
    final customFile = File(p.join(_customTemplateDir, templateName));
    if (await customFile.exists()) {
      return customFile.readAsString();
    }
    // 2. 기본 템플릿
    final templateDir = p.join(p.dirname(configDirPath), 'templates');
    final file = File(p.join(templateDir, templateName));
    if (await file.exists()) {
      return file.readAsString();
    }
    return '';
  }

  /// 커스텀 템플릿 저장
  Future<void> saveCustomTemplate(
      String templateName, String content) async {
    final dir = Directory(_customTemplateDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    await File(p.join(_customTemplateDir, templateName))
        .writeAsString(content);
  }

  /// 커스텀 템플릿이 존재하는지 확인
  Future<bool> hasCustomTemplate(String templateName) async {
    return File(p.join(_customTemplateDir, templateName)).exists();
  }

  /// 커스텀 템플릿 삭제 (기본으로 되돌리기)
  Future<void> deleteCustomTemplate(String templateName) async {
    final file = File(p.join(_customTemplateDir, templateName));
    if (await file.exists()) {
      await file.delete();
    }
  }
}
