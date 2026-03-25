import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/agent_provider.dart';

class ConfigLoaderService {
  final String configDirPath;

  ConfigLoaderService({required this.configDirPath});

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

  Future<String> loadTemplate(String templateName) async {
    final templateDir = p.join(p.dirname(configDirPath), 'templates');
    final file = File(p.join(templateDir, templateName));
    if (await file.exists()) {
      return file.readAsString();
    }
    return '';
  }
}
