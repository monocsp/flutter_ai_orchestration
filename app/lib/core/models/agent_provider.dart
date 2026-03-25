class AgentProvider {
  final String id;
  final String displayName;
  final List<String> sessionSetup;
  final List<String> pasteAdvice;
  final List<String> followUpAdvice;
  final List<String> executableNames;

  const AgentProvider({
    required this.id,
    required this.displayName,
    this.sessionSetup = const [],
    this.pasteAdvice = const [],
    this.followUpAdvice = const [],
    this.executableNames = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentProvider && other.id == id;

  @override
  int get hashCode => id.hashCode;

  factory AgentProvider.fromJson(Map<String, dynamic> json) {
    return AgentProvider(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      sessionSetup: (json['sessionSetup'] as List?)?.cast<String>() ?? [],
      pasteAdvice: (json['pasteAdvice'] as List?)?.cast<String>() ?? [],
      followUpAdvice: (json['followUpAdvice'] as List?)?.cast<String>() ?? [],
    );
  }

  static const List<AgentProvider> builtIn = [
    AgentProvider(
      id: 'codex',
      displayName: 'Codex CLI',
      executableNames: ['codex'],
    ),
    AgentProvider(
      id: 'claude',
      displayName: 'Claude CLI',
      executableNames: ['claude'],
    ),
    AgentProvider(
      id: 'gemini',
      displayName: 'Gemini CLI',
      executableNames: ['gemini', 'gemini-cli'],
    ),
    AgentProvider(
      id: 'copilot',
      displayName: 'GitHub Copilot CLI',
      executableNames: ['copilot'],
    ),
    AgentProvider(
      id: 'other',
      displayName: '기타 AI CLI',
      executableNames: [],
    ),
  ];
}

class AgentInstallStatus {
  final String agentId;
  final String displayName;
  final bool installed;
  final bool executable;
  final String? detectedPath;
  final String? version;

  const AgentInstallStatus({
    required this.agentId,
    required this.displayName,
    this.installed = false,
    this.executable = false,
    this.detectedPath,
    this.version,
  });
}
