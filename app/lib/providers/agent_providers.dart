import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/agent_provider.dart';
import '../core/services/agent_detection_service.dart';

final agentDetectionServiceProvider = Provider<AgentDetectionService>((ref) {
  return AgentDetectionService();
});

final agentStatusProvider =
    FutureProvider<List<AgentInstallStatus>>((ref) async {
  final service = ref.watch(agentDetectionServiceProvider);
  return service.detectAll();
});
