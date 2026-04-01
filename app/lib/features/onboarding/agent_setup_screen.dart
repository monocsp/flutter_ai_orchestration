import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/agent_providers.dart';

class AgentSetupScreen extends ConsumerStatefulWidget {
  const AgentSetupScreen({super.key});

  @override
  ConsumerState<AgentSetupScreen> createState() => _AgentSetupScreenState();
}

class _AgentSetupScreenState extends ConsumerState<AgentSetupScreen> {
  int _currentStep = 0; // 0: npm 확인, 1: agent 설치, 2: 완료
  bool _checkingNpm = false;
  bool _npmInstalled = false;
  bool _installingAgent = false;
  String? _installLog;
  String? _installError;
  String _selectedAgent = 'claude';

  @override
  void initState() {
    super.initState();
    _checkNpm();
  }

  Future<void> _checkNpm() async {
    setState(() => _checkingNpm = true);
    try {
      final result = await Process.run(
        Platform.isWindows ? 'cmd.exe' : 'bash',
        Platform.isWindows ? ['/c', 'npm --version'] : ['-c', 'npm --version'],
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _npmInstalled = result.exitCode == 0;
        _checkingNpm = false;
        if (_npmInstalled) _currentStep = 1;
      });
    } catch (_) {
      setState(() {
        _npmInstalled = false;
        _checkingNpm = false;
      });
    }
  }

  Future<void> _installAgent() async {
    setState(() {
      _installingAgent = true;
      _installLog = null;
      _installError = null;
    });

    final installCmd = _getInstallCommand(_selectedAgent);

    try {
      final result = await Process.run(
        Platform.isWindows ? 'cmd.exe' : 'bash',
        Platform.isWindows ? ['/c', installCmd] : ['-c', installCmd],
      ).timeout(const Duration(minutes: 5));

      final stdout = (result.stdout as String).trim();
      final stderr = (result.stderr as String).trim();

      if (result.exitCode == 0) {
        setState(() {
          _installingAgent = false;
          _installLog = '설치 완료!\n$stdout';
          _currentStep = 2;
        });
        // Agent 상태 새로고침
        ref.invalidate(agentStatusProvider);
      } else {
        setState(() {
          _installingAgent = false;
          _installError = '설치 실패 (exit code: ${result.exitCode})\n$stderr\n$stdout';
        });
      }
    } catch (e) {
      setState(() {
        _installingAgent = false;
        _installError = '설치 중 오류: $e';
      });
    }
  }

  String _getInstallCommand(String agentId) {
    switch (agentId) {
      case 'claude':
        return 'npm install -g @anthropic-ai/claude-code';
      case 'codex':
        return 'npm install -g @openai/codex';
      case 'gemini':
        return 'npm install -g @anthropic-ai/claude-code'; // gemini는 별도
      default:
        return 'npm install -g @anthropic-ai/claude-code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(40),
            children: [
              // Header
              const Icon(Icons.rocket_launch, size: 56, color: Color(0xFF0D9488)),
              const SizedBox(height: 16),
              const Text(
                'AI Orchestration 시작하기',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'AI Agent를 설치하면 문서를 자동으로 분석할 수 있습니다',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Step indicator
              _buildStepIndicator(),
              const SizedBox(height: 32),

              // Step content
              if (_currentStep == 0) _buildNpmStep(),
              if (_currentStep == 1) _buildAgentInstallStep(),
              if (_currentStep == 2) _buildCompleteStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepBadge(0, 'Node.js 확인'),
        Expanded(child: Container(height: 2, color: _currentStep > 0 ? const Color(0xFF0D9488) : Colors.grey.shade300)),
        _stepBadge(1, 'Agent 설치'),
        Expanded(child: Container(height: 2, color: _currentStep > 1 ? const Color(0xFF0D9488) : Colors.grey.shade300)),
        _stepBadge(2, '완료'),
      ],
    );
  }

  Widget _stepBadge(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF0D9488) : Colors.grey.shade300,
          ),
          child: Center(
            child: isActive && _currentStep > step
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text('${step + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade500, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? const Color(0xFF0D9488) : Colors.grey.shade400)),
      ],
    );
  }

  Widget _buildNpmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          icon: Icons.terminal,
          title: 'Step 1: Node.js / npm 설치',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_checkingNpm)
                const Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('npm 설치 여부 확인 중...', style: TextStyle(fontSize: 13)),
                  ],
                )
              else if (_npmInstalled)
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                    const SizedBox(width: 8),
                    const Text('npm이 설치되어 있습니다!', style: TextStyle(fontSize: 13, color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
                  ],
                )
              else ...[
                const Text(
                  'AI Agent를 설치하려면 Node.js가 필요합니다.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),

                // 설치 방법
                _instructionCard(
                  step: '1',
                  title: 'Node.js 공식 사이트에서 다운로드',
                  content: 'https://nodejs.org 에서 LTS 버전을 다운로드하세요.',
                  action: ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('https://nodejs.org')),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Node.js 다운로드'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _instructionCard(
                  step: '2',
                  title: '설치 완료 후 이 버튼을 눌러주세요',
                  content: '설치 프로그램의 기본 설정으로 "다음"을 누르면 됩니다.',
                  action: OutlinedButton.icon(
                    onPressed: _checkNpm,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('npm 설치 확인'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgentInstallStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          icon: Icons.smart_toy,
          title: 'Step 2: AI Agent 설치',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '사용할 AI Agent를 선택하고 설치하세요. Claude를 추천합니다.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),

              // Agent 선택
              _agentOption('claude', 'Claude CLI', '가장 범용적이며 문서 분석에 강합니다', true),
              const SizedBox(height: 8),
              _agentOption('codex', 'Codex CLI', '코드 분석과 실행에 특화되어 있습니다', false),
              const SizedBox(height: 16),

              // 설치 명령어 안내
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '터미널 명령어:',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      _getInstallCommand(_selectedAgent),
                      style: const TextStyle(fontSize: 13, color: Colors.white, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 설치 버튼
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _installingAgent ? null : _installAgent,
                  icon: _installingAgent
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download, size: 20),
                  label: Text(_installingAgent ? '설치 중... (최대 2분 소요)' : '자동 설치'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              if (_installLog != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(_installLog!, style: const TextStyle(fontSize: 11, color: Color(0xFF166534), fontFamily: 'monospace')),
                  ),
                ),

              if (_installError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_installError!, style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B), fontFamily: 'monospace')),
                        const SizedBox(height: 8),
                        const Text(
                          '직접 설치하려면 터미널을 열고 위 명령어를 실행하세요.',
                          style: TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              // 수동 설치 안내
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('직접 설치하는 방법', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                children: [
                  _instructionCard(
                    step: '1',
                    title: '터미널(명령 프롬프트)을 열어주세요',
                    content: Platform.isWindows
                        ? 'Windows: 시작 메뉴 → "cmd" 검색 → 명령 프롬프트 실행'
                        : 'macOS: Spotlight(⌘+Space) → "Terminal" 검색',
                  ),
                  const SizedBox(height: 8),
                  _instructionCard(
                    step: '2',
                    title: '아래 명령어를 입력하세요',
                    content: _getInstallCommand(_selectedAgent),
                  ),
                  const SizedBox(height: 8),
                  _instructionCard(
                    step: '3',
                    title: '설치 후 인증하세요',
                    content: _selectedAgent == 'claude'
                        ? 'claude login 을 실행하여 Anthropic 계정으로 로그인하세요.'
                        : 'codex login 을 실행하여 OpenAI 계정으로 로그인하세요.',
                  ),
                  const SizedBox(height: 8),
                  _instructionCard(
                    step: '4',
                    title: '이 앱으로 돌아와서 확인',
                    content: '아래 버튼을 눌러 설치를 확인하세요.',
                    action: OutlinedButton.icon(
                      onPressed: () {
                        ref.invalidate(agentStatusProvider);
                        setState(() => _currentStep = 2);
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('설치 확인'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    final agentStatus = ref.watch(agentStatusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          icon: Icons.check_circle,
          title: 'Step 3: 설치 확인',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              agentStatus.when(
                data: (statuses) {
                  final installed = statuses.where((s) => s.installed).toList();
                  if (installed.isEmpty) {
                    return Column(
                      children: [
                        const Text('아직 설치된 Agent가 감지되지 않았습니다.', style: TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            ref.invalidate(agentStatusProvider);
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('다시 확인'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() => _currentStep = 1),
                          child: const Text('← Agent 설치로 돌아가기'),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...installed.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                            const SizedBox(width: 8),
                            Text('${s.displayName} 설치됨', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            if (s.version != null) ...[
                              const SizedBox(width: 8),
                              Text(s.version!, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontFamily: 'monospace')),
                            ],
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),
                      const Text(
                        '설치가 완료되었습니다! 이제 문서를 분석할 수 있습니다.',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // agentStatusProvider를 새로고침하면 workbench가 자동으로 전환됨
                            ref.invalidate(agentStatusProvider);
                          },
                          icon: const Icon(Icons.arrow_forward, size: 20),
                          label: const Text('시작하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Agent 감지 중...', style: TextStyle(fontSize: 13)),
                  ],
                ),
                error: (e, _) => Text('Agent 감지 실패: $e', style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _agentOption(String id, String name, String description, bool recommended) {
    final isSelected = _selectedAgent == id;
    return Material(
      color: isSelected ? const Color(0xFF0D9488).withValues(alpha: 0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _selectedAgent = id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade400,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF334155))),
                        if (recommended) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('추천', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    Text(description, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF0D9488)),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _instructionCard({required String step, required String title, required String content, Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0D9488)),
            child: Center(child: Text(step, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                SelectableText(content, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
                if (action != null) ...[const SizedBox(height: 8), action],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
