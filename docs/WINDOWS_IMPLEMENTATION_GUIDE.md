# Windows 구현 가이드

이 문서는 macOS에서 동작하는 AI Orchestration Flutter 데스크톱 앱을 Windows에서 완전히 동일하게 동작하도록 만들기 위한 기능 명세서입니다.

Windows 컴퓨터에서 Claude에게 이 문서를 제공하고, `feature-windows` 브랜치에서 작업하도록 하세요.

---

## 1. 현재 프로젝트 구조

```
app/
├── lib/
│   ├── main.dart                          # 엔트리포인트
│   ├── app.dart                           # MaterialApp 루트
│   ├── core/
│   │   ├── data/
│   │   │   └── builtin_templates.dart     # 15개 프롬프트 템플릿 내장 (코드에 하드코딩)
│   │   ├── models/
│   │   │   ├── agent_provider.dart        # AI CLI 정의 (codex, claude, gemini, copilot)
│   │   │   ├── orchestration_preset.dart  # 3/5/7단계 프리셋
│   │   │   ├── orchestration_stage.dart   # 단계 모델 + 프리셋별 단계 정의
│   │   │   ├── orchestration_thread.dart  # 실행 스레드/단계 상태 모델
│   │   │   ├── parallel_comparison.dart   # 병렬 비교 모델
│   │   │   ├── session_config.dart        # 세션 설정 + 도움말 텍스트 + 자동 설정 프롬프트
│   │   │   └── template_preset.dart       # 템플릿 프리셋 (developer/planner/executive/custom)
│   │   ├── services/
│   │   │   ├── agent_detection_service.dart  # ⚠️ macOS 전용: CLI 감지
│   │   │   ├── agent_runner_service.dart     # ⚠️ macOS 전용: AI CLI 실행
│   │   │   ├── config_loader_service.dart    # 템플릿 로드 (커스텀 → 파일 → 내장)
│   │   │   ├── error_log_service.dart        # 에러 로그 저장
│   │   │   ├── sample_template_service.dart  # 샘플 문서 생성
│   │   │   ├── session_builder_service.dart  # 세션 폴더/프롬프트 생성
│   │   │   └── template_renderer_service.dart # {{변수}} 치환
│   │   └── theme/
│   │       └── app_theme.dart             # 테마 (라이트만)
│   ├── features/
│   │   ├── agent_status/agent_status_bar.dart
│   │   ├── documents/
│   │   │   ├── documents_panel.dart       # ⚠️ 부분 macOS 전용: 폴더 열기
│   │   │   └── markdown_viewer.dart
│   │   ├── parallel/
│   │   │   ├── parallel_result_view.dart
│   │   │   └── parallel_setup_panel.dart
│   │   ├── session_setup/session_setup_panel.dart
│   │   ├── stage_editor/
│   │   │   ├── stage_card.dart
│   │   │   └── stage_editor_panel.dart
│   │   ├── thread/
│   │   │   ├── stage_thread_card.dart
│   │   │   ├── thread_detail_view.dart
│   │   │   └── thread_list_panel.dart
│   │   ├── tutorial/tutorial_overlay.dart
│   │   └── workbench/workbench_screen.dart
│   └── providers/
│       ├── agent_providers.dart
│       ├── session_providers.dart
│       └── thread_providers.dart           # 오케스트레이션 실행 루프
├── macos/                                  # macOS 네이티브
├── pubspec.yaml
└── user_handoff_kit/                       # 프롬프트 템플릿 (파일 시스템)
    ├── config/
    ├── templates/
    └── templates_custom/
```

---

## 2. 수정이 필요한 파일 (3개만)

나머지 파일은 플랫폼 무관 코드이므로 수정 불필요합니다.

### 2-1. `agent_detection_service.dart` — CLI 감지 (핵심)

**현재 macOS 구현:**
```dart
// 셸 결정
final shell = Platform.environment['SHELL'] ?? '/bin/zsh';

// 로그인 셸에서 PATH 가져오기
Process.run(shell, ['-l', '-i', '-c', 'echo \$PATH']);

// PATH 구분자
[...extraPaths, currentPath].join(':');

// 폴백 경로
'/opt/homebrew/bin', '/usr/local/bin', '$home/.local/bin', ...

// CLI 위치 찾기
Process.run(shell, ['-c', 'export PATH="$loginPath:\$PATH"; which $exe']);

// 버전 확인
Process.start(shell, ['-c', 'export PATH="$loginPath:\$PATH"; $exe --version']);

// 미설치 판별 문자열
'cannot find', 'command not found', 'not installed'
```

**Windows에서 변경해야 할 것:**
| macOS | Windows |
|-------|---------|
| `$SHELL` → `/bin/zsh` | `cmd.exe` 또는 `powershell.exe` |
| `zsh -l -i -c 'echo $PATH'` | Windows는 PATH 가져오기 불필요 (시스템 PATH 그대로 상속됨) |
| PATH 구분자 `:` | PATH 구분자 `;` |
| `which exe` | `where.exe exe` |
| `export PATH="..."; cmd` | `set "PATH=...;%PATH%" && cmd` 또는 그냥 직접 실행 |
| `/opt/homebrew/bin` 등 | `%USERPROFILE%\AppData\Roaming\npm`, `C:\Program Files\nodejs` 등 |
| 미설치: `command not found` | 미설치: `is not recognized`, `could not be found` |

**권장 구현 방식:**
```dart
static Future<String> getLoginShellPath() async {
  if (Platform.isWindows) {
    // Windows는 .exe 번들에서도 시스템 PATH를 상속받으므로
    // 별도 로그인 셸 PATH 가져오기가 불필요
    final currentPath = Platform.environment['PATH'] ?? '';
    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    final extraPaths = [
      '$userProfile\\AppData\\Roaming\\npm',
      '$userProfile\\.local\\bin',
      'C:\\Program Files\\nodejs',
      'C:\\Program Files\\Git\\cmd',
    ];
    _cachedPath = [...extraPaths, currentPath].join(';');
    return _cachedPath!;
  }
  // ... 기존 macOS 코드
}

Future<AgentInstallStatus> _detect(AgentProvider agent) async {
  if (Platform.isWindows) {
    for (final exe in agent.executableNames) {
      try {
        // where.exe로 경로 확인
        final whichResult = await Process.run(
          'where.exe', [exe],
        ).timeout(const Duration(seconds: 10));
        if (whichResult.exitCode != 0) continue;

        final path = (whichResult.stdout as String).trim().split('\n').first;
        if (path.isEmpty) continue;

        // --version 실행
        final vResult = await Process.run(exe, ['--version'])
            .timeout(const Duration(seconds: 8));
        // ... 결과 처리
      } catch (_) { continue; }
    }
  }
  // ... 기존 macOS 코드
}
```

### 2-2. `agent_runner_service.dart` — AI CLI 실행 (핵심)

**현재 macOS 구현:**
```dart
// 셸
final shell = Platform.environment['SHELL'] ?? '/bin/zsh';

// PATH 보강
final wrappedCmd = 'export PATH="$loginPath:\$PATH"; $cmd';

// 셸 실행
Process.run(shell, ['-c', wrappedCmd], workingDirectory: workingDir);

// CLI별 명령 생성
'cat \'$promptFilePath\' | claude -p --dangerously-skip-permissions'
'codex exec "\$(cat \'$promptFilePath\')"'
'gemini -p "\$(cat \'$promptFilePath\')"'
'cat \'$promptFilePath\' | $agentId'
```

**Windows에서 변경해야 할 것:**
| macOS | Windows |
|-------|---------|
| `cat 'file'` | `type "file"` |
| `\$(cat 'file')` | cmd에서는 `for /f` 또는 PowerShell에서 `$(Get-Content file)` |
| `export PATH=...; cmd` | `set "PATH=...;%PATH%" && cmd` |
| `shell -c "cmd"` | `cmd.exe /c "cmd"` |
| 작은따옴표 `'file'` | 큰따옴표 `"file"` |

**권장 구현 방식:**
```dart
String _buildCommand(String agentId, String promptFilePath) {
  if (Platform.isWindows) {
    switch (agentId) {
      case 'claude':
        return 'type "$promptFilePath" | claude -p --dangerously-skip-permissions';
      case 'codex':
        return 'codex exec "type "$promptFilePath""';
      case 'gemini':
        return 'gemini -p "type "$promptFilePath""';
      default:
        return 'type "$promptFilePath" | $agentId';
    }
  }
  // ... 기존 macOS 코드
}

// 실행부
if (Platform.isWindows) {
  final wrappedCmd = 'set "PATH=$loginPath;%PATH%" && $cmd';
  result = await Process.run(
    'cmd.exe', ['/c', wrappedCmd],
    workingDirectory: workingDir,
  ).timeout(timeout);
} else {
  // ... 기존 macOS 코드
}
```

**주의: Windows에서 프롬프트 파일을 파이프로 전달하는 것이 복잡할 수 있음.**
더 안전한 대안: 프롬프트 파일 경로를 직접 인자로 전달하거나, Dart에서 파일을 읽어 stdin으로 직접 전달.

```dart
// 대안: Process.start로 stdin 직접 전달 (플랫폼 무관)
final process = await Process.start(
  'claude', ['-p', '--dangerously-skip-permissions'],
  workingDirectory: workingDir,
);
process.stdin.write(wrappedPrompt);
await process.stdin.close();
final stdout = await process.stdout.transform(utf8.decoder).join();
```

이 방식이 `cat`/`type` 파이프 문제를 완전히 회피할 수 있어 **가장 권장**됩니다.

### 2-3. `documents_panel.dart` — 폴더 열기 (minor)

**현재 코드 (이미 부분 처리됨):**
```dart
Future<void> _openFolder(String path) async {
  if (Platform.isMacOS) {
    await Process.run('open', [path]);
  } else if (Platform.isWindows) {
    await Process.run('explorer', [path]);  // 이미 있음. explorer.exe로 변경 권장
  }
}
```

**변경:** `explorer` → `explorer.exe` 또는 그대로 유지 (동작은 함).

---

## 3. Windows 프로젝트 생성

Windows 컴퓨터에서 아래 명령 실행:

```powershell
cd app
flutter create --platforms=windows .
```

이렇게 하면 `windows/` 디렉터리가 자동 생성됩니다. macOS에서는 이 명령이 동작하지 않으므로 반드시 Windows에서 실행해야 합니다.

---

## 4. 수정이 필요 없는 파일들 (참고)

다음 파일들은 `dart:io`의 `Platform.pathSeparator`, `Directory`, `File` 등 크로스플랫폼 API만 사용하므로 수정 불필요:

- `main.dart`, `app.dart` — 플랫폼 무관
- `builtin_templates.dart` — 순수 문자열 상수
- 모든 모델 파일 (`session_config.dart`, `orchestration_*.dart` 등) — 순수 Dart
- `config_loader_service.dart` — `File`, `Directory` 사용 (크로스플랫폼)
- `session_builder_service.dart` — 동일
- `error_log_service.dart` — 동일
- `template_renderer_service.dart` — 순수 문자열 치환
- 모든 UI 파일 (`workbench_screen.dart`, `session_setup_panel.dart` 등) — Flutter 위젯
- 모든 provider 파일 — Riverpod 상태 관리
- `pubspec.yaml` — 사용 패키지 모두 Windows 지원 (flutter_riverpod, file_picker, shared_preferences, path_provider, desktop_drop, flutter_markdown, url_launcher)

---

## 5. 의존성 패키지 Windows 지원 현황

| 패키지 | Windows 지원 |
|--------|-------------|
| flutter_riverpod | ✅ |
| file_picker | ✅ |
| shared_preferences | ✅ |
| path_provider | ✅ |
| desktop_drop | ✅ |
| flutter_markdown | ✅ |
| url_launcher | ✅ |
| path | ✅ |
| cupertino_icons | ✅ |

---

## 6. 빌드 및 테스트

```powershell
# Windows 프로젝트 생성 (최초 1회)
flutter create --platforms=windows .

# 분석
flutter analyze

# 개발 모드 실행
flutter run -d windows

# 릴리즈 빌드
flutter build windows --release

# 결과물 위치
# build\windows\x64\runner\Release\ai_orchestration.exe
```

---

## 7. Windows 설치 배포 (선택)

릴리즈 빌드 후 `build\windows\x64\runner\Release\` 폴더 전체를 zip으로 압축하면 배포 가능.
MSIX 패키지나 Inno Setup으로 설치 프로그램을 만들 수도 있음.

---

## 8. 작업 체크리스트

```
[ ] flutter create --platforms=windows . 실행
[ ] agent_detection_service.dart에 Platform.isWindows 분기 추가
    [ ] getLoginShellPath(): Windows PATH 폴백 (npm, nodejs 등)
    [ ] _detect(): where.exe 사용, 미설치 판별 문자열 추가
[ ] agent_runner_service.dart에 Platform.isWindows 분기 추가
    [ ] _buildCommand(): cat → type 또는 stdin 직접 전달
    [ ] run(): cmd.exe /c 또는 Process.start stdin 방식
[ ] documents_panel.dart: explorer.exe 확인
[ ] flutter analyze 에러 없음
[ ] flutter run -d windows 정상 실행
[ ] CLI 감지 테스트 (claude, codex, gemini 설치 후)
[ ] 오케스트레이션 실행 테스트 (문서 넣고 5단계 돌리기)
[ ] flutter build windows --release 정상 빌드
```

---

## 9. 브랜치 정보

- 작업 브랜치: `feature-windows`
- 기반: `main` (macOS 구현 완료 상태)
- main과 동일한 커밋에서 분기됨
