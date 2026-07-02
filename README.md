# AI Orchestration Workbench

> 만든 이유: 단일 AI의 답을 그대로 믿기 어려워서, 한 모델이 분석하면 다른 모델이 그 결과를 검증하도록 왕복시키는 도구가 필요했습니다.

> 여러 AI CLI(Claude · Codex · Gemini)를 **분석가**와 **비평가**로 나눠 문서 하나를 다단계로 분석·검증하고 바로 실행 가능한 계획서를 만들어 주는 Flutter 데스크톱 앱.

![platform](https://img.shields.io/badge/platform-macOS%20%7C%20Windows-blue)
![Flutter](https://img.shields.io/badge/Flutter-desktop-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-%5E3.11-0175C2?logo=dart)
![state](https://img.shields.io/badge/state-Riverpod%203-00C4B4)
![version](https://img.shields.io/badge/version-1.0.0-informational)
![license](https://img.shields.io/badge/license-MIT-green)
<!-- [TODO] pub.dev 미배포(publish_to: none)라 pub 배지 없음. license 배지는 실제 LICENSE 파일 추가 후 확정 -->

기획서·QA 이슈·경영진 피드백 같은 문서를 넣으면 서로 다른 AI에게 **분석 → 비판 → 보강 → 재비판 → 최종 계획**을 자동으로 돌려 실행 계획서를 생성합니다. 이 앱은 단일 AI에 의존하지 않습니다. 한 모델이 분석하면 **다른 모델이 그 결과를 신뢰하지 않고 재검증**하고 앱은 그 왕복을 오케스트레이션하면서 각 단계의 프롬프트·결과·추론 메모를 파일로 남깁니다. 결과 비교가 필요할 때는 같은 프롬프트를 여러 AI에 동시에 던지는 **병렬 비교** 모드도 제공합니다.


## 무엇을 오케스트레이션하나

이 앱이 조율하는 대상은 **로컬에 설치된 AI CLI 프로세스**입니다. 각 AI에 역할을 부여하고 앱은 그 사이의 데이터 흐름·재시도·산출물 저장을 관리합니다.

| 역할 | 담당 단계 | 하는 일 |
|------|-----------|---------|
| **분석 Agent** | Step 1 · 3 · 5 (7단계 시 7) | 문서 기반 분석, 비판 반영 보강, 최종 계획 작성 |
| **비평 Agent** | Step 2 · 4 (7단계 시 6) | 이전 분석을 신뢰하지 않고 재검증, 누락·과범위·잘못된 가정 지적 |
| **오케스트레이터(앱)** | 전 과정 | 단계 순서 제어, 이전 결과 주입, 프로세스 실행/중단, 실패 시 대체 모델 폴백, 산출물 저장 |

분석과 비평에 **서로 다른 모델**을 배정하면 한 모델의 편향을 다른 모델이 교차 검증합니다. (예: 분석 Claude, 비평 Codex)

## ✨ Features

- **다단계 순차 오케스트레이션** — 3단계(빠른 분석) / 5단계(기본) / 7단계(정밀 심화) 프리셋. 분석↔비평 모델이 번갈아 실행되며 이전 단계 결과가 다음 프롬프트에 자동 주입됩니다.
- **병렬 비교** — 동일 프롬프트를 여러 AI에 동시 실행하고 결과를 Agent별 탭으로 비교.
- **AI 기반 자동 설정** — 실행 전, AI가 문서를 읽어 (1) 분석 모드(코드/기획/경영진 피드백/프롬프트 엔지니어링)를 추천하고 (2) 실행 목적·비판 강도·리스크 포커스·결과 형식·전문가 페르소나·핵심 분석 포인트를 구조화 JSON으로 도출해 세션에 적용합니다.
- **추론 메모 강제** — 모든 AI 호출 앞에 래퍼 프롬프트를 주입해 본론 전에 "분석 과정 메모"(핵심 쟁점·판단 근거·불확실한 부분)를 남기게 하고 파일에 저장하지 말고 응답에 전문을 출력하도록 강제합니다.
- **모델 자동 폴백** — 한 단계가 실패하면 설치된 다른 AI(우선순위 claude → gemini → codex)로 자동 재시도.
- **Agent 자동 탐지** — 로그인 셸 PATH를 해석해 설치된 CLI와 버전을 감지(하단 상태 바). `.app`/설치본을 Finder로 실행해도 CLI를 찾습니다.
- **다양한 입력 포맷** — `md · txt · csv · pdf · docx · xlsx` 등을 텍스트로 변환해 입력.
- **프롬프트 템플릿 프리셋** — 개발자용 / 기획자용 / 경영진 피드백용 / 프롬프트 엔지니어링용 / 직접입력. 단계별로 편집·커스텀 저장 가능.
- **구조화된 세션 산출물** — 실행마다 `results/ · prompts/ · memos/ · meta/` 폴더로 정리 저장.
- **중단 · 재시도** — 실행 중 프로세스 강제 종료, 실패 단계부터 이어서 재시도.

## 🛠 Tech Stack

- **Flutter (데스크톱)** + **Dart SDK `^3.11.0`** · macOS(최소 10.15) / Windows
- **Riverpod 3** (`flutter_riverpod ^3.3.1`) — `Notifier` 기반 상태 관리
- **desktop_drop** (드래그앤드롭), **file_picker** (파일 선택)
- **flutter_markdown** (결과 렌더링), **url_launcher**
- **docx_to_text**, **excel** (docx/xlsx → 텍스트 변환)
- **shared_preferences**, **path_provider**, **path**
- Material 3 커스텀 라이트 테마

### AI-Native 구현 포인트

- **비대화형 CLI 오케스트레이션**: 프롬프트를 임시 파일로 쓰고 각 CLI를 논-인터랙티브 모드로 실행 — `cat prompt | claude -p --dangerously-skip-permissions`, `codex exec --skip-git-repo-check -`, `gemini -p`. stdout/stderr를 동시 소비해 파이프 교착을 방지하고 단계당 20분 타임아웃을 둡니다.
- **크로스플랫폼 PATH 해석**: macOS/Linux는 로그인 셸(`$SHELL -l -i -c 'echo $PATH'`)에서, Windows는 시스템 PATH + npm/nodejs 경로 보강으로 CLI를 탐지.
- **AI가 AI를 설정**: 실행 파라미터 자체를 LLM이 문서를 읽고 JSON으로 결정 → 앱이 파싱해 적용(파싱 실패 시 안전 기본값 폴백).
- **결과 파싱**: 응답에서 "## 분석 과정 메모" 섹션을 정규식으로 분리해 `memos/`에, 본문은 `results/`에 저장.

## 🚀 Getting Started

### 요구사항

- Flutter SDK (데스크톱 지원, Dart `^3.11.0`)
- AI CLI **최소 1개** 설치. 순차 오케스트레이션은 분석·비평 두 역할이 모두 필요하므로 **2개 이상 권장**. 앱이 탐지하는 실행 파일명은 `claude` · `codex` · `gemini` · `copilot` 입니다.

| Agent | 실행 파일 | 참고 |
|-------|-----------|------|
| Claude Code | `claude` | https://docs.anthropic.com/en/docs/claude-code |
| OpenAI Codex CLI | `codex` | https://github.com/openai/codex |
| Gemini CLI | `gemini` | https://github.com/google-gemini/gemini-cli |
| GitHub Copilot CLI | `copilot` | 탐지 지원, 실행 연동은 예정 |

> 각 CLI 설치 방법과 로그인은 위 공식 문서를 따르세요.

### 실행

```bash
git clone https://github.com/monocsp/flutter_ai_orchestration.git
cd flutter_ai_orchestration/app

# 데스크톱 활성화(최초 1회) — 플랫폼에 맞게
flutter config --enable-macos-desktop     # 또는 --enable-windows-desktop

flutter pub get
flutter run -d macos                       # 또는 -d windows
```

### 빌드 / 배포

```bash
flutter build macos      # build/macos/Build/Products/Release/*.app
flutter build windows    # build/windows/x64/runner/Release/
```

Windows 설치본은 리포지토리 루트의 `installer.iss`(Inno Setup)로 패키징합니다.

> 세션 결과는 `~/Documents/AI Orchestration/`, 에러 로그는 `~/Documents/AI Orchestration/logs/`(`error_YYYYMMDD_HHMMSS_<단계>.log`)에 저장됩니다.

## 📖 Usage

### 앱에서

1. **[+]** 로 새 오케스트레이션 생성 → **순차 오케스트레이션** 또는 **병렬 비교** 탭 선택.
2. 분석할 문서를 드래그하거나 선택(선택적으로 참고 프로젝트 폴더 지정).
3. 프리셋·분석/비평 Agent를 고르거나 "자동" 그대로 둡니다. (자동이면 AI가 설정을 추천)
4. **시작** — 진행 상황과 각 단계 결과를 스레드 뷰에서 실시간 확인. 실패 시 해당 단계부터 재시도.

### 코드에서 (핵심 공개 API)

단일 AI CLI를 비대화형으로 실행:

```dart
final runner = AgentRunnerService();
final result = await runner.run(
  agentId: 'claude',            // 'claude' | 'codex' | 'gemini'
  promptContent: promptText,
  workingDir: projectRoot,      // 선택
  timeout: const Duration(minutes: 20),
);
print(result.success ? result.output : result.error);
```

Riverpod Notifier로 오케스트레이션 트리거:

```dart
// 순차 오케스트레이션 시작
ref.read(threadListProvider.notifier)
   .startOrchestration(customTitle: '로그인 리팩터링');

// 병렬 비교 시작
ref.read(threadListProvider.notifier).startParallelComparison(
  agentIds: ['claude', 'codex', 'gemini'],
  promptContent: promptText,
);

// 실행 중단 / 실패 단계부터 재시도
ref.read(threadListProvider.notifier).stopOrchestration();
ref.read(threadListProvider.notifier).retryFromStage(threadId, stageIndex);
```

### 세션 산출물 구조

```
~/Documents/AI Orchestration/session_<timestamp>_<문서명>/
├── results/   # 단계별 분석/검토 결과 본문
├── prompts/   # 각 단계에 사용된 프롬프트
├── memos/     # AI의 "분석 과정 메모"
└── meta/      # 세션 요약, 실행 가이드, Agent 확인·설정 분석
```

## 🧩 Project Structure

```
flutter_ai_orchestration/
├── app/                         # Flutter 데스크톱 앱 (메인)
│   └── lib/
│       ├── core/
│       │   ├── models/          # SessionConfig, OrchestrationStage/Preset, AgentProvider ...
│       │   ├── services/        # agent_runner, agent_detection, session_builder,
│       │   │                    #   config_loader, file_converter, error_log ...
│       │   ├── data/            # builtin_templates (프롬프트 내장 기본값)
│       │   └── theme/
│       ├── features/            # workbench, session_setup, stage_editor, thread,
│       │   │                    #   parallel, documents, agent_status, tutorial, onboarding
│       └── providers/           # Riverpod (thread/session/agent/parallel)
├── user_handoff_kit/            # 앱 없이 쓰는 스탠드얼론 CLI 키트 (run.sh / run.ps1)
│   ├── config/                  # Agent별 설정(JSON)
│   ├── templates/               # 역할별 프롬프트 템플릿 (dev/plan/exec/pe)
│   └── templates_custom/        # 사용자 커스텀 템플릿
├── scripts/                     # 초기 셸 기반 오케스트레이션 파이프라인 (레거시)
├── prompts/                     # 레거시 스크립트용 프롬프트
├── docs/                        # 제품 소개·구현 가이드
└── installer.iss                # Windows 인스톨러 (Inno Setup)
```

- **`app/`** 가 제품의 본체입니다.
- **`user_handoff_kit/`** 는 앱을 쓰지 않고 프롬프트 시퀀스를 생성해 직접 AI CLI에 붙여넣는 대화형 키트입니다.
- **`scripts/`** 는 앱 이전의 Bash 기반 Claude↔Codex 파이프라인으로, 자세한 내용은 [`AI_ORCHESTRATION.md`](AI_ORCHESTRATION.md) 참고. (경로 규약이 현재 앱과 다른 초기 버전입니다.)

## 📄 License

MIT
<!-- [TODO] 리포지토리에 LICENSE 파일이 없습니다. MIT로 확정하려면 LICENSE 파일 추가 필요 -->

## 배운 점

- CLI를 비대화형으로 실행할 때 stdout만 읽으면 stderr 버퍼에서 프로세스가 멈추는 문제가 있어, 두 스트림을 동시에 소비하도록 처리했습니다.
- 실행 환경마다 PATH가 달라 CLI를 못 찾는 문제가 있어, 로그인 셸 기준으로 PATH를 해석하도록 정리했습니다.
- 한 단계가 실패하면 설치된 다른 AI로 폴백해 중간에 멈추지 않도록 했습니다.
