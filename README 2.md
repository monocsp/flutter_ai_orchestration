# AI 오케스트레이션 실행 가이드

이 문서는 `ai/` 폴더의 오케스트레이션을 다시 실행하거나, 기능 요청/QA 이슈를 입력으로 넣어 결과를 만드는 방법을 정리합니다.

## 개요

입력 Markdown 파일을 기반으로 아래 5단계를 순서대로 실행합니다.

1. Round 1 분석
2. Round 1 Codex 비판 검토
3. Round 2 심화 분석
4. Round 2 Codex 비판 검토
5. Final 최종 실행 계획 작성

여기서 `분석 단계`는 기본적으로 `claude`로 시작합니다.
단, Claude가 사용량 한도나 fallback 가능 상태로 실패하면 자동으로 `codex`로 재시도합니다.

## 각 라운드 정책

### Round 1

- 목적:
  입력 문서의 작업 대상을 구조화하고, 관련 파일과 간접 영향 파일을 최대한 넓게 찾습니다.
- 입력:
  원본 입력 문서
- 출력:
  `ai/result/round1/round1_<provider>_result.md`

### Round 1 Codex 검토

- 목적:
  Round 1 분석을 비판적으로 검증하고, 잘못된 가정과 누락된 파일을 찾습니다.
- 입력:
  Round 1 분석 결과 + 원본 입력 문서
- 출력:
  `ai/result/round1/round1_codex_review.md`

### Round 2

- 목적:
  Round 1 분석과 Codex 반박을 반영해 더 정교한 분석으로 압축합니다.
- 입력:
  원본 입력 문서 + Round 1 분석 결과 + Round 1 Codex 검토
- 출력:
  `ai/result/round2/round2_<provider>_result.md`

### Round 2 Codex 검토

- 목적:
  Round 2 결과를 다시 반박하고, 남은 누락과 회귀 위험을 정리합니다.
- 입력:
  Round 2 분석 결과 + 원본 입력 문서
- 출력:
  `ai/result/round2/round2_codex_review.md`

### Final

- 목적:
  앞선 라운드의 주장과 반박을 종합해 실행 가능한 최종 계획서를 만듭니다.
- 입력:
  원본 입력 문서 + Round 1 전체 + Round 2 전체
- 출력:
  `ai/result/final/final_<provider>_result.md`

## 결과물 저장 정책

분석 단계는 실제 적용된 provider 이름을 파일명에 넣습니다.

- Round 1:
  `ai/result/round1/round1_<provider>_result.md`
- Round 2:
  `ai/result/round2/round2_<provider>_result.md`
- Final:
  `ai/result/final/final_<provider>_result.md`

예시:

- `round1_claude_result.md`
- `round1_codex_result.md`
- `round2_codex_result.md`
- `final_codex_result.md`

Codex 비판 검토 라운드는 고정 파일명을 사용합니다.

- `ai/result/round1/round1_codex_review.md`
- `ai/result/round2/round2_codex_review.md`

프롬프트 조립용 중간 파일도 함께 남습니다.

- `ai/result/round1/round1_claude_prompt.md`
- `ai/result/round1/round1_codex_prompt.md`
- `ai/result/round2/round2_claude_prompt.md`
- `ai/result/round2/round2_codex_prompt.md`
- `ai/result/final/final_claude_prompt.md`

## 주요 파일

- `ai/scripts/orchestrate_ai.sh`
  오케스트레이션 엔트리포인트입니다.
- `ai/scripts/run_claude_task.sh`
  분석 단계 실행 래퍼입니다.
  기본은 `claude`로 시작하고 필요 시 자동 fallback 됩니다.
- `ai/scripts/run_codex_task.sh`
  Codex 비판 검토 단계 실행 래퍼입니다.
- `ai/prompts/claude_analyze.md`
  Round 1, Round 2 분석용 프롬프트 템플릿입니다.
- `ai/prompts/codex_critical_review.md`
  Codex 비판 검토용 프롬프트 템플릿입니다.
- `ai/prompts/claude_final_plan.md`
  Final 최종 계획서용 프롬프트 템플릿입니다.

## 입력 파일

대표 입력 파일은 아래 두 가지입니다.

- `ai/inbox/jira_issues.md`
  QA/Jira 이슈를 정리한 입력 파일입니다.
- `ai/inbox/task.md`
  기능 추가, 정책 변경, 리팩터링, 버그 수정 요청 등 범용 입력 템플릿입니다.

## 기능 요청용 Markdown 작성 방법

`ai/inbox/task.md` 에 아래 관점이 들어가면 가장 좋습니다.

- 작업 배경
- 구현 목표
- 사용자 시나리오
- 화면/기능 범위
- 변경이 예상되는 정책
- 완료 조건
- 확인 필요 항목

이 오케스트레이션은 Jira/QA 전용이 아니므로, 아래 같은 요청도 넣을 수 있습니다.

- 신규 기능 추가
- 특정 화면 UX 변경
- 상태 관리 구조 개편
- 공통 컴포넌트 리팩터링
- 정책/문구 변경
- 특정 버그 재현 및 수정

## 실행 방법

### 1. Jira/QA 입력 기준 실행

```bash
ai/scripts/orchestrate_ai.sh --issues-file ai/inbox/jira_issues.md
```

### 2. 기능 요청 입력 기준 실행

```bash
ai/scripts/orchestrate_ai.sh --task-file ai/inbox/task.md
```

### 3. 이전 state 기준 재실행

```bash
ai/scripts/orchestrate_ai.sh --issues-file ai/inbox/jira_issues.md --resume
```

### 4. 실제 CLI 호출 없이 흐름만 점검

```bash
ai/scripts/orchestrate_ai.sh --task-file ai/inbox/task.md --dry-run
```

### 5. 도움말

```bash
ai/scripts/orchestrate_ai.sh --help
```

## Provider 동작

분석 단계는 기본적으로 `claude`로 시작합니다.

- 기본값: `claude`
- 강제 지정 가능: `--provider claude|codex|gemini`
- 환경변수 지정 가능: `AI_PROVIDER=codex`

예시:

```bash
ai/scripts/orchestrate_ai.sh --task-file ai/inbox/task.md --provider codex
```

```bash
AI_PROVIDER=gemini ai/scripts/orchestrate_ai.sh --task-file ai/inbox/task.md
```

## Claude 실패 시 fallback 정책

기본 실행은 `claude`입니다.

실행 중 Claude에서 아래와 비슷한 상태가 감지되면 자동으로 `codex`로 재시도합니다.

- 사용량 한도 초과
- fallback 관련 오류
- 로그인 필요
- quota 초과
- overloaded 상태

즉, 현재 구조에서는 수동 선택 없이 `claude -> codex` 자동 fallback 정책을 사용합니다.

## Gemini 사용 시

`gemini` provider는 아래 순서로 실행 명령을 찾습니다.

1. `GEMINI_CMD` 환경변수
2. `gemini`
3. `gemini-cli`

예시:

```bash
GEMINI_CMD=gemini-cli ai/scripts/orchestrate_ai.sh --task-file ai/inbox/task.md --provider gemini
```

## 로그 정책

메인 로그:

- `ai/log/orchestrate.log`

이 파일에는 전체 raw 출력이 아니라 아래 같은 상위 흐름만 남기는 것이 정책입니다.

- 단계 시작
- 단계 종료
- fallback 발생
- 타임아웃
- 성공/실패
- 실제 사용된 결과 파일

단계별 상세 로그:

- `ai/log/step1_round1_claude.log`
- `ai/log/step2_round1_codex.log`
- `ai/log/step3_round2_claude.log`
- `ai/log/step4_round2_codex.log`
- `ai/log/step5_final_claude.log`

실제 LLM/CLI 출력 전문은 단계별 로그에서 보고,
전체 진행 상황은 `orchestrate.log` 에서 보는 것이 정책입니다.

## 상태 파일

- `ai/state/orchestrate.state`

`--resume` 실행 시 이 파일을 기준으로 다음 단계부터 이어서 실행합니다.

## 개별 실행기 사용법

분석 단계 실행기:

```bash
ai/scripts/run_claude_task.sh \
  --prompt-file ai/prompts/claude_analyze.md \
  --output-file ai/result/tmp_analysis_output.md
```

Codex 실행기:

```bash
ai/scripts/run_codex_task.sh \
  --prompt-file ai/prompts/codex_critical_review.md \
  --output-file ai/result/tmp_codex_output.md \
  --repo-root .
```

## 주의사항

- `claude`, `codex`, `gemini` CLI는 일반 터미널 로그인 환경 기준으로 동작합니다.
- Codex 샌드박스 안에서 보이는 인증 상태와 사용자의 실제 터미널 로그인 상태는 다를 수 있습니다.
- 실제 오류 확인은 일반 터미널에서 실행한 뒤 `ai/log/orchestrate.log` 와 단계별 로그를 함께 보는 것이 가장 안전합니다.
