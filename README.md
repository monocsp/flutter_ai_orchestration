# AI Orchestration Workbench

AI CLI(Claude, Codex, Gemini 등)를 활용한 **다단계 기술 분석 오케스트레이션** 데스크톱 앱입니다.

기획서나 이슈 문서를 넣으면, 여러 AI를 조합하여 분석 → 비판 → 보강 → 재비판 → 최종 계획을 자동으로 생성합니다.

## 주요 기능

### 순차 오케스트레이션 (5단계)
하나의 문서를 기반으로 분석 AI와 검토 AI가 번갈아 5단계를 자동 수행합니다.

| 단계 | 역할 | 설명 |
|------|------|------|
| Step 1 | 1차 분석 | 기준 문서 기반 초기 분석, 우선순위 보드, 리스크 정리 |
| Step 2 | 1차 비판 검토 | 분석의 오류/누락 지적, 대안 제시 |
| Step 3 | 분석 보강 | 비판 반영하여 분석 보강 |
| Step 4 | 2차 비판 검토 | 최종 관문 — GO/HOLD/NO-GO 판정 |
| Step 5 | 최종 종합안 | 바로 착수 가능한 실행 계획서 |

### 병렬 비교
동일한 문서와 프롬프트를 **여러 AI에 동시에 실행**하여 결과를 비교합니다.

### 기타
- Agent 설치 상태 자동 탐지 (하단 상태 바)
- 프롬프트 템플릿 편집 및 커스텀 저장
- 결과 Markdown 뷰어 (선택/복사 가능)
- 오케스트레이션 중단 버튼
- 에러 로그 자동 저장 (`app/logs/`)
- 사용법 튜토리얼 오버레이

## 스크린샷 구조

```
┌────┬──────────────────────────────────────────────┐
│ +  │ [순차 오케스트레이션] [병렬 비교]              │
│────│──────────────────────────────────────────────│
│ ①  │ 설정 패널  │  단계 편집기  │  입력/결과 뷰어  │
│ ②  │           │              │                  │
│ ⓟ  │           │              │                  │
│    │           │              │                  │
│ ?  │           │              │                  │
├────┴──────────────────────────────────────────────┤
│ Codex ● Claude ● Gemini ● Copilot ✗              │
└───────────────────────────────────────────────────┘
```

- **좌측 사이드 레일**: [+] 새 오케스트레이션, 스레드 목록 (진행률 링), [?] 사용법
- **중앙**: 모드에 따라 설정/편집기 또는 스레드 진행 뷰
- **우측**: 입력 문서/프롬프트 탭 + 결과 탭
- **하단**: Agent 설치 상태

## 빠른 시작

### 요구사항
- macOS (Flutter 데스크톱)
- Flutter SDK 3.11+
- AI CLI 중 하나 이상 설치:
  - [Claude CLI](https://docs.anthropic.com/en/docs/claude-code) — `brew install claude`
  - [Codex CLI](https://github.com/openai/codex) — `npm install -g @openai/codex`
  - [Gemini CLI](https://github.com/google-gemini/gemini-cli) — `npm install -g @anthropic-ai/gemini-cli`

### 설치 및 실행

```bash
# 저장소 클론
git clone https://github.com/your-repo/flutter_ai_orchestration.git
cd flutter_ai_orchestration

# macOS 데스크톱 활성화 (최초 1회)
flutter config --enable-macos-desktop

# 앱 실행
cd app
flutter run -d macos
```

### 첫 사용

1. 앱 실행 후 **[?] 사용법** 버튼으로 튜토리얼 확인
2. 또는 **"기본 템플릿으로 시작"** 버튼 클릭 → 샘플 문서 자동 로드
3. 설정 확인 후 **"오케스트레이션 시작"** 클릭
4. 5단계가 자동으로 진행됨 — 스레드 뷰에서 실시간 확인

## 사용법

### 순차 오케스트레이션

1. **[+]** 버튼 클릭 → "새 오케스트레이션" 화면
2. **[순차 오케스트레이션]** 탭 선택
3. 좌측 설정:
   - 제목 입력 (선택, 비워두면 자동 번호)
   - 계획서 파일 드래그 또는 클릭으로 선택
   - 프리셋 선택 (기본 5단계 비판형 / 3단계 경량형 / QA / 기획 / 리팩터링)
   - 분석 Agent, 검토 Agent 선택
   - 실행 목적, 비판 강도, 리스크 포커스, 결과 형식 설정
4. 중앙 단계 편집기에서 각 단계 확인/수정 (프롬프트 내용 확인 가능)
5. **"오케스트레이션 시작"** 클릭
6. 자동 진행:
   - Step 0: Agent 설치 상태 확인
   - Step 1~5: AI CLI 자동 실행 → 결과 수신 → 파일 저장 → 다음 단계

### 병렬 비교

1. **[+]** 버튼 클릭 → "새 오케스트레이션" 화면
2. **[병렬 비교]** 탭 선택
3. 계획서 파일 선택
4. 프롬프트 확인/수정
5. 실행할 Agent 체크 (2개 이상)
6. **"병렬 실행 시작"** 클릭
7. 각 Agent가 동시에 실행 → 결과를 Agent별 탭으로 비교

### 프롬프트 커스텀

1. 순차 오케스트레이션의 단계 편집기에서 **[편집]** 클릭
2. 프롬프트 내용 수정
3. **[저장]** → `user_handoff_kit/templates_custom/`에 커스텀 버전 저장
4. 다음 오케스트레이션부터 커스텀 버전이 자동 사용
5. **[기본값]** 으로 원래 템플릿 복원 가능

### 에러 발생 시

- 실패한 단계에 **"에러 복사"** 버튼으로 에러 내용 복사 가능
- `app/logs/` 디렉터리에 에러 로그 자동 저장
- 로그 파일: `error_YYYYMMDD_HHMMSS_단계이름.log`

## 프로젝트 구조

```
flutter_ai_orchestration/
├── app/                          # Flutter 데스크톱 앱
│   ├── lib/
│   │   ├── core/
│   │   │   ├── models/           # 도메인 모델
│   │   │   ├── services/         # 비즈니스 로직
│   │   │   └── theme/            # 테마
│   │   ├── features/
│   │   │   ├── workbench/        # 메인 레이아웃
│   │   │   ├── session_setup/    # 세션 설정 패널
│   │   │   ├── stage_editor/     # 단계 편집기
│   │   │   ├── documents/        # 문서/결과 뷰어
│   │   │   ├── thread/           # 스레드 진행 뷰
│   │   │   ├── parallel/         # 병렬 비교 뷰
│   │   │   ├── agent_status/     # Agent 상태 바
│   │   │   └── tutorial/         # 사용법 오버레이
│   │   └── providers/            # Riverpod 상태 관리
│   ├── macos/                    # macOS 네이티브 설정
│   └── output/                   # 생성된 세션 결과물
├── user_handoff_kit/
│   ├── config/                   # Agent별 설정 (JSON)
│   ├── templates/                # 기본 프롬프트 템플릿 (5개)
│   ├── templates_custom/         # 사용자 커스텀 템플릿
│   └── output/                   # CLI 버전 출력물
└── scripts/                      # 오케스트레이션 셸 스크립트 (레거시)
```

## 기술 스택

- **Flutter 3.41** + Dart 3.11
- **Riverpod 3.x** (상태 관리)
- **desktop_drop** (파일 드래그앤드롭)
- **flutter_markdown** (Markdown 렌더링)
- **file_picker** (파일 선택 다이얼로그)
- **Material 3** 커스텀 테마 (슬레이트 + 청록)

## 지원 AI CLI

| Agent | 실행 방식 | 비대화형 모드 |
|-------|----------|-------------|
| Claude CLI | `cat prompt \| claude -p --dangerously-skip-permissions` | stdin 파이프 |
| Codex CLI | `codex exec "$(cat prompt)"` | exec 서브커맨드 |
| Gemini CLI | `gemini -p "$(cat prompt)"` | -p 플래그 |
| GitHub Copilot CLI | 지원 예정 | - |

## 라이선스

MIT
