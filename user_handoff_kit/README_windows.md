# AI 오케스트레이션 전달용 패키지

이 폴더는 특정 AI CLI 하나에 종속되지 않습니다.
목표는 사용자가 몇 가지 질문에 답하면, `Codex CLI`, `Claude CLI`, `Gemini CLI` 또는 기타 AI CLI에 순서대로 넣을 수 있는 프롬프트와 실행 가이드를 자동으로 만드는 것입니다.

즉, 이 패키지는 직접 AI를 호출하는 도구라기보다 `질문형 프롬프트 생성기 + 실행 가이드`입니다.

## 폴더 구조

```text
user_handoff_kit/
  templates/
    analysis_prompt.md
    critical_review_prompt.md
    final_plan_prompt.md
  examples/
    sample_request.md
    sample_generated_execution_guide.md
    sample_final_plan_excerpt.md
  config/
    codex.json
    claude.json
    gemini.json
    other.json
  output/
  run.sh
  run.ps1
  README_windows.md
```

## 준비물

- Windows PowerShell 또는 PowerShell 7, 또는 macOS 기본 셸 환경
- 기준 문서 1개
  - 예: 기획서, QA 이슈 문서, Jira 정리, 버그 리포트, 정책 문서
- 사용할 AI CLI
  - 예: `codex`, `claude`, `gemini`
- 가능하면 대상 프로젝트 폴더를 함께 열 수 있는 환경

## 실행 방법

### Windows
PowerShell에서 이 폴더로 이동한 뒤 아래처럼 실행합니다.

```powershell
.\run.ps1
```

스크립트 실행이 막혀 있으면 현재 세션에서만 우회할 수 있습니다.

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\run.ps1
```

### macOS
터미널에서 이 폴더로 이동한 뒤 아래처럼 실행합니다.

```bash
chmod +x run.sh
./run.sh
```

## 스크립트가 물어보는 것

`run.ps1`와 `run.sh`는 아래 질문을 같은 순서로 받습니다.

1. 어떤 문서를 기준으로 분석할지
2. 어떤 AI를 사용할지
3. 이번 실행 목적이 무엇인지
4. 얼마나 비판적으로 검토할지
5. 꼭 확인해야 하는 리스크가 무엇인지
6. 결과물을 어떤 형식으로 받을지

답변을 마치면 `output/session_날짜_시간_문서명/` 폴더가 생성되고, 아래 파일이 만들어집니다.

- `00_session_summary.md`
- `01_analysis_prompt.md`
- `02_critical_review_prompt.md`
- `03_final_plan_prompt.md`
- `04_execution_guide.md`
- `11_analysis_result.md`
- `12_critical_review_result.md`
- `13_final_plan_result.md`

## 사용 순서

1. AI CLI에서 대상 프로젝트를 열거나, 최소한 기준 문서와 관련 코드에 접근 가능한 상태를 만듭니다.
2. `01_analysis_prompt.md`를 기준 문서와 함께 넣습니다.
3. 응답을 `11_analysis_result.md`에 저장합니다.
4. `02_critical_review_prompt.md`, 기준 문서, `11_analysis_result.md`를 함께 넣습니다.
5. 응답을 `12_critical_review_result.md`에 저장합니다.
6. `03_final_plan_prompt.md`, 기준 문서, 앞선 두 결과를 함께 넣습니다.
7. 응답을 `13_final_plan_result.md`에 저장합니다.

## 대화 시 유의사항

- 답변이 추상적이면 직접 수정 파일과 간접 영향 파일을 다시 쓰게 하세요.
- 파일 경로나 호출 체인이 없으면 실제 경로 검증을 다시 요구하세요.
- 사실과 가정이 섞여 있으면 분리해서 다시 작성하게 하세요.
- 공통 컴포넌트 영향, 라이프사이클, 상태 관리, 회귀 포인트가 빠지면 보완하게 하세요.
- 최종 결과에는 구현 순서와 검증 순서가 모두 있어야 합니다.

## 왜 skills가 아닌가

이 패키지의 핵심은 특정 에이전트에 규칙을 주입하는 것이 아니라, 비전문 사용자도 같은 절차로 프롬프트를 생성하고 실행하도록 돕는 것입니다.
그래서 `skills` 패키지보다 `질문형 실행기 + 템플릿 + 가이드` 구조가 더 적합합니다.

## 권장 운영 방식

- 내부 운영용 오케스트레이션은 기존 `ai/` 폴더를 유지합니다.
- 외부 전달용은 이 `user_handoff_kit/`만 따로 배포합니다.
- 사용자가 생성한 `output/session_*` 폴더만 다시 회수해도 실행 이력과 결과를 파악할 수 있습니다.
