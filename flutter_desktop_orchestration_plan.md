# Flutter Desktop Orchestration 계획서

## 1. 목표

`user_handoff_kit/run.sh`와 `run.ps1`가 담당하던 프롬프트 생성, 세션 산출물 생성, AI CLI 선택, 결과 정리 흐름을 Flutter 데스크톱 앱으로 옮긴다.

목표 플랫폼은 아래 2개다.

- macOS
- Windows

핵심 방향은 `bash`/`PowerShell` 스크립트를 Flutter에서 호출해서 감싸는 것이 아니라, 현재 스크립트의 로직을 Dart로 흡수해서 OS별 분기와 인코딩 문제를 줄이는 것이다.

## 2. 현재 상태 정리

현재 저장소 기준으로 확인한 내용은 아래와 같다.

- [`user_handoff_kit/run.sh`](/Users/pcs/Documents/GitHub/flutter_ai_orchestration/user_handoff_kit/run.sh)는 macOS/Unix 기준의 질문형 프롬프트 생성기다.
- [`user_handoff_kit/run.ps1`](/Users/pcs/Documents/GitHub/flutter_ai_orchestration/user_handoff_kit/run.ps1)는 Windows용 버전이지만, `run.sh`와 완전히 동일한 기능까지는 아직 아니다.
- [`user_handoff_kit/config/codex.json`](/Users/pcs/Documents/GitHub/flutter_ai_orchestration/user_handoff_kit/config/codex.json), [`user_handoff_kit/config/claude.json`](/Users/pcs/Documents/GitHub/flutter_ai_orchestration/user_handoff_kit/config/claude.json), [`user_handoff_kit/config/gemini.json`](/Users/pcs/Documents/GitHub/flutter_ai_orchestration/user_handoff_kit/config/gemini.json), [`user_handoff_kit/config/other.json`](/Users/pcs/Documents/GitHub/flutter_ai_orchestration/user_handoff_kit/config/other.json)에 provider별 안내 문구가 이미 분리되어 있다.
- 현재 산출물 구조는 `output/session_날짜_시간_문서명/` 아래에 세션 요약, 프롬프트, 실행 가이드, 결과 Markdown 파일들을 생성하는 방식이다.
- 아직 Flutter 프로젝트 골격은 없다.

즉, Flutter 앱의 첫 번째 목적은 "새 UI를 만드는 것"이 아니라 "이미 검증된 handoff 규칙을 일관된 데스크톱 워크플로우로 재구성하는 것"이다.

## 3. 요구사항 해석

요청한 필수 UI 요구사항은 아래처럼 해석하면 된다.

### 3-1. 각 5단계에서 프롬프트 설정창

앱 내부 모델을 항상 "5단계 오케스트레이션" 기준으로 통일한다.

1. Step 1: 1차 분석
2. Step 2: 1차 비판 검토
3. Step 3: 분석 보강 또는 재분석
4. Step 4: 2차 비판 검토
5. Step 5: 최종 종합안 작성

현재 `run.sh`는 3개의 주요 프롬프트 파일만 만들지만, 앱에서는 5단계 모두를 개별 설정 가능하게 두고, 필요하면 "legacy export"에서 기존 3-프롬프트 구조로 합성한다.

### 3-2. 어떤 오케스트레이션을 진행할건지 선택

단순히 모델만 고르는 것이 아니라 "오케스트레이션 프리셋"을 선택하게 해야 한다.

초기 프리셋 제안:

- 기본 5단계 비판형
- 빠른 3단계 경량형
- QA/버그 대응형
- 기능 기획 검증형
- 리팩터링 계획형

### 3-3. 오케스트레이션 진행 후 결과 md 파일들

앱은 세션 단위 산출물을 파일시스템에 그대로 남겨야 한다.

- 사용자는 앱 안에서 결과를 미리보기 할 수 있어야 한다.
- 동시에 실제 `.md` 파일 경로도 보여줘야 한다.
- 결과 폴더를 Finder/Explorer에서 바로 열 수 있어야 한다.

### 3-4. 기획서 md 파일 drag and drop + 파일찾기

입력 문서는 드래그앤드롭과 파일 다이얼로그 둘 다 지원해야 한다.

### 3-5. 가져온 파일을 보여주는 창

가져온 파일 목록과 현재 선택된 파일의 Markdown 미리보기가 필요하다.

### 3-6. run.sh 에서 설정 가능한 웬만한 모든 것

적어도 아래 항목은 UI에서 노출해야 한다.

- 기준 문서 경로
- 참고 프로젝트 루트 경로
- 출력 루트 경로
- 분석용 agent
- 비판 검토용 agent
- 실행 목적
- 비판 강도
- 리스크 포커스
- 결과 형식
- 단계별 프롬프트 본문
- provider별 운영 가이드 문구
- 세션 파일명 규칙
- legacy 호환 출력 여부

### 3-7. 각 agent 설치 여부 확인

최소 아래 executable 탐지가 필요하다.

- `codex`
- `claude`
- `gemini`
- `gemini-cli`
- `copilot`

가능하면 `--version` 또는 유사 명령까지 확인해서 "경로만 존재"와 "실행 가능"을 구분한다.

## 4. 제품 방향

앱의 정체성은 아래 둘을 동시에 만족해야 한다.

- 비전문 사용자도 쓸 수 있는 데스크톱 워크벤치
- 기존 handoff 규칙을 깨지 않는 운영 도구

따라서 1차 버전은 "예쁜 폼"보다 아래를 우선해야 한다.

- 세션 생성 규칙의 재현성
- 파일 기반 결과물의 신뢰성
- macOS/Windows 동작 일관성
- agent 설치 상태와 실행 가능성의 가시화

## 5. 추천 UX 구조

단일 화면 워크벤치가 가장 적합하다.

### 5-1. 전체 레이아웃

3패널 구조를 권장한다.

- 좌측: 세션/오케스트레이션 설정
- 중앙: 5단계 프롬프트 편집 및 실행 제어
- 우측: 입력 문서 미리보기, 결과 파일 목록, 결과 Markdown 뷰어

하단에는 공통 로그/상태 바를 둔다.

- 설치 상태
- 현재 세션 경로
- 마지막 실행 시각
- 실행 로그

### 5-2. 화면 섹션

#### A. Session Setup 패널

- 기준 문서 drag and drop 영역
- 파일 찾기 버튼
- 프로젝트 루트 선택 버튼
- 출력 루트 선택 버튼
- 오케스트레이션 프리셋 선택
- primary agent 선택
- critic agent 선택
- 실행 목적
- 비판 강도
- 리스크 포커스
- 결과 형식

#### B. Stage Editor 패널

5개의 단계 카드를 둔다.

- Step 이름
- 담당 agent
- 입력으로 참조하는 파일
- 출력 파일명
- 프롬프트 템플릿 편집기
- 단계 활성화/비활성화 토글

권장 UI는 "세로 타임라인 + 선택된 단계 상세 편집"이다.
탭보다 현재 흐름을 파악하기 쉽고, 5단계 요구사항과 잘 맞는다.

#### C. Documents & Results 패널

- 가져온 입력 Markdown 파일 목록
- 현재 선택한 입력 파일 미리보기
- 세션 결과 파일 목록
- 선택한 결과 파일 Markdown 렌더링
- 원본 열기 / 폴더 열기 버튼

#### D. Agent Status 패널

상단 우측 또는 좌측 하단에 상시 표시한다.

- agent 이름
- 설치 여부
- 실행 가능 여부
- 탐지된 경로
- 버전 문자열
- 인증 필요 여부 메모

## 6. UI 스타일 제안

이 앱은 일반적인 폼 앱처럼 만들면 금방 지루해진다. 데스크톱 툴답게 "편집기 + 운영 콘솔" 느낌으로 가는 편이 맞다.

디자인 방향 제안:

- 밝은 베이지/슬레이트 계열 배경
- 채도가 높은 강조색은 오렌지 또는 청록 계열 1개만 사용
- 단계 카드마다 번호 배지와 상태색을 부여
- Markdown 뷰어는 종이 문서 느낌, 설정 패널은 콘솔 느낌으로 대비
- macOS/Windows에서 둘 다 어색하지 않게 Flutter 기본 Material 3를 베이스로 하되 커스텀 테마를 강하게 입힘

즉, Windows 전용 Fluent처럼 보이게 하기보다 "크로스플랫폼용 AI 오케스트레이션 워크벤치" 정체성을 따로 만드는 것이 낫다.

## 7. 기술 설계

## 7-1. 핵심 원칙

- 스크립트 호출 의존을 최소화하고 Dart 도메인 로직으로 흡수
- 결과는 반드시 파일시스템에 남김
- UI 상태와 세션 산출물 생성을 분리
- provider별 차이는 설정 파일 기반으로 흡수

## 7-2. 권장 레이어

### Domain

- `OrchestrationPreset`
- `OrchestrationStage`
- `AgentProvider`
- `SessionConfig`
- `SessionArtifact`
- `AgentInstallStatus`

### Application

- `SessionBuilderService`
- `PromptRendererService`
- `ArtifactWriterService`
- `AgentDetectionService`
- `SessionRunnerService`
- `SettingsService`

### Infrastructure

- file system access
- process execution
- markdown loading
- config json parsing

### Presentation

- desktop shell
- stage editor
- results viewer
- agent status board

## 7-3. 상태 관리

상태 관리는 `flutter_riverpod` 계열이 가장 무난하다.

이유:

- 데스크톱 폼 + 비동기 상태 + 파일시스템 로딩 + 실행 상태 추적이 섞인다.
- 프롬프트 편집, 파일 미리보기, 설치 체크, 세션 생성이 분리된 provider로 나뉘기 좋다.

## 7-4. 데이터 저장 전략

설정과 결과 저장을 분리한다.

- 앱 설정: 최근 사용 경로, 기본 preset, 마지막 agent 조합
- 세션 결과: 실제 output 폴더 내 Markdown 파일들

초기 버전은 DB 없이 아래만으로 충분하다.

- 앱 설정: `shared_preferences`
- 세션 이력: output 폴더 스캔

## 7-5. 실행 전략

실행 전략은 2단계로 나누는 것이 현실적이다.

### 1단계: Assisted Orchestration

앱이 아래를 담당한다.

- 세션 폴더 생성
- 프롬프트/결과 placeholder 파일 생성
- 각 단계별 입력 자료 정리
- 결과 Markdown 뷰어 제공
- agent 설치 상태 확인

이 단계에서는 사용자가 외부 CLI를 직접 열어 copy/paste로 진행해도 된다.

### 2단계: Semi-Automated Orchestration

앱이 아래를 추가로 담당한다.

- provider adapter를 통해 CLI 프로세스 실행
- stdout/stderr 수집
- 단계별 결과 파일 자동 저장
- 실패 단계 재시도

이 구조가 필요한 이유는 agent별 CLI 인증 방식과 인터랙션 방식이 다를 수 있기 때문이다.
처음부터 완전 자동 실행까지 한 번에 가면 Windows와 macOS 모두에서 불안정해질 가능성이 높다.

## 8. 현재 스크립트를 어떻게 이전할지

핵심은 `run.sh`와 `run.ps1`를 그대로 감싸지 않는 것이다.

이전 순서는 아래가 맞다.

1. `run.sh`의 기능 범위를 기준 spec으로 삼는다.
2. `run.ps1`의 Windows 대응 아이디어는 참고만 한다.
3. prompt template과 provider config json은 그대로 재사용한다.
4. 세션 폴더 생성 규칙과 파일명 규칙을 Dart에서 동일하게 구현한다.
5. 이후 필요하면 스크립트는 fallback 도구로만 남긴다.

이렇게 해야 quoting, 경로 구분자, UTF-8, clipboard, 실행 정책 문제를 앱 내부에서 통제할 수 있다.

## 9. 패키지 후보

2026-03-24 기준 후보는 아래 정도면 충분하다.

- `desktop_drop`: 데스크톱 파일 drag and drop
  - https://pub.dev/packages/desktop_drop
- `file_picker`: 파일/폴더 선택
  - https://pub.dev/packages/file_picker
- `process_run`: cross-platform process 실행 및 executable 탐색
  - https://pub.dev/packages/process_run
- `gpt_markdown` 또는 `flutter_markdown_plus`: Markdown 렌더링
  - https://pub.dev/packages/gpt_markdown
  - https://pub.dev/packages/flutter_markdown_plus
- `shared_preferences`: 최근 설정 저장
  - https://pub.dev/packages/shared_preferences
- `path_provider`: 앱 데이터 경로 관리
  - https://pub.dev/packages/path_provider

주의:

- drag and drop은 `desktop_drop`로 충분하지만, 결과 미리보기와 파일 목록은 직접 위젯을 설계하는 편이 낫다.
- Markdown 뷰어는 단순 렌더링보다 "선택/복사 가능한 문서 뷰"가 더 중요하다.

## 10. 파일 구조 제안

Flutter 앱을 추가한다면 아래 구조를 권장한다.

```text
app/
  pubspec.yaml
  lib/
    app/
    bootstrap/
    core/
      theme/
      utils/
    features/
      agent_status/
      orchestration/
      prompt_editor/
      session_files/
      settings/
    infrastructure/
      config/
      filesystem/
      process/
  test/
```

기존 자산은 아래처럼 유지한다.

```text
user_handoff_kit/
  templates/
  config/
  examples/
```

Flutter 앱은 이 폴더를 reference asset처럼 읽어들이거나, 초기 실행 시 앱 내부 작업 디렉터리로 복사해서 쓸 수 있다.

## 11. 세션 산출물 규칙 제안

기존 호환성을 위해 기본 출력은 유지한다.

```text
output/session_YYYYMMDD_HHMMSS_<doc_name>/
  00_session_summary.md
  01_analysis_prompt.md
  02_critical_review_prompt.md
  03_final_plan_prompt.md
  04_execution_guide.md
  11_analysis_result.md
  12_critical_review_result.md
  13_final_plan_result.md
```

동시에 앱 내부 확장 모델은 5단계를 보존한다.

- 필요하면 `session.json`을 추가해서 단계 메타데이터를 저장
- 결과 뷰에서는 5단계 기준으로 보여주되, 파일 export는 legacy 호환 가능

## 12. 개발 단계

## Phase 1. 기초 골격

- Flutter desktop 프로젝트 생성
- macOS, Windows 타깃 활성화
- 기본 워크벤치 레이아웃 구현
- 테마 및 typography 확정

## Phase 2. handoff 로직 이전

- config json 로더 구현
- template renderer 구현
- session output 생성기 구현
- 기존 `run.sh`와 동일한 기본 산출물 생성 검증

## Phase 3. 입력/미리보기

- Markdown drag and drop
- 파일 picker
- 입력 파일 목록 및 미리보기
- 프로젝트 루트/출력 루트 선택

## Phase 4. 5단계 편집기

- stage timeline UI
- 단계별 프롬프트 편집기
- preset 선택
- legacy export / expanded export 분기

## Phase 5. agent 상태 보드

- executable 탐지
- 버전 조회
- 상태 badge
- 경로 표시

## Phase 6. 실행 및 결과 관리

- 세션 생성
- 결과 파일 목록
- Markdown 결과 뷰어
- 폴더 열기 / 파일 열기

## Phase 7. 자동 실행 어댑터

- provider별 CLI adapter 설계
- 안전한 process 실행
- 로그 수집
- 단계 실패 복구

## 13. 우선순위

처음부터 다 만들기보다 아래 순서가 맞다.

1. Flutter 앱 골격 + 단일 화면 워크벤치
2. `run.sh`의 세션 생성 로직을 Dart로 동일 재현
3. drag and drop + 파일 미리보기
4. 5단계 프롬프트 편집기
5. agent 설치 확인
6. 결과 파일 뷰어
7. 자동 실행

즉, "실행 자동화"보다 "세션 규칙을 정확히 재현하는 것"이 먼저다.

## 14. 리스크

### 기술 리스크

- provider별 CLI가 비대화형 실행을 안정적으로 지원하지 않을 수 있다.
- Windows에서 PowerShell 정책, PATH, UTF-8 처리 차이가 발생할 수 있다.
- Markdown 렌더링과 대용량 파일 미리보기에서 성능 문제가 생길 수 있다.

### 제품 리스크

- 5단계 설정을 모두 노출하면 초보 사용자에게 너무 복잡할 수 있다.
- 반대로 설정을 너무 숨기면 `run.sh`에서 하던 세밀한 통제가 사라질 수 있다.

대응 전략:

- 기본값이 채워진 preset 중심 UX
- 상세 설정은 접이식 고급 옵션으로 분리
- legacy 호환 출력 유지

## 15. 완료 기준

아래를 만족하면 1차 목표 달성으로 본다.

- macOS와 Windows에서 같은 Flutter 앱이 실행된다.
- Markdown 기획서를 drag and drop 또는 파일 찾기로 가져올 수 있다.
- 가져온 파일의 내용을 앱 안에서 볼 수 있다.
- 오케스트레이션 preset을 선택할 수 있다.
- 5단계 각각의 프롬프트를 수정할 수 있다.
- `run.sh` 핵심 설정들을 UI에서 바꿀 수 있다.
- agent 설치 상태를 확인할 수 있다.
- 세션 산출물 Markdown 파일이 output 폴더에 생성된다.
- 생성된 결과 Markdown를 앱에서 확인할 수 있다.

## 16. 결론

이 작업은 "스크립트를 예쁘게 감싼 데스크톱 UI"로 가면 오래 못 간다.
정답은 현재 handoff 규칙을 Dart 도메인 로직으로 승격시키고, Flutter는 그 위에 올라가는 워크벤치가 되는 구조다.

가장 현실적인 출발점은 아래다.

1. Flutter 데스크톱 프로젝트 생성
2. `run.sh` 기능을 Dart로 재구현
3. 3패널 워크벤치 UI 구현
4. 5단계 프롬프트 편집기와 결과 Markdown 뷰어 연결
5. 이후 agent 자동 실행을 adapter 방식으로 확장
