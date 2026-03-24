# AI 오케스트레이션 가이드 (Claude CLI + Codex CLI)

## 목적
입력 md 파일을 넣으면 Claude↔Codex 3회 오케스트레이션으로 최종 계획서를 반환합니다.

## 실행 흐름

```
Round 1
  Step 1) Claude: 원본 md 분석            → result/round1/round1_claude_analysis.md
  Step 2) Codex:  원본 + Claude를 비판적 검토 → result/round1/round1_codex_review.md

Round 2
  Step 3) Claude: 원본 + Round1 결과 심화 분석 → result/round2/round2_claude_analysis.md
  Step 4) Codex:  원본 + Claude를 비판적 검토  → result/round2/round2_codex_review.md

Final
  Step 5) Claude: 원본 + Round1 + Round2 → result/final/final_action_plan.md
```

## 디렉터리 구조
```
ai/
  inbox/              입력 파일
  result/
    round1/           Round 1 결과
      round1_claude_prompt.md       Step 1 런타임 프롬프트
      round1_claude_analysis.md     Step 1 Claude 분석
      round1_codex_prompt.md        Step 2 런타임 프롬프트
      round1_codex_review.md        Step 2 Codex 비판적 검토
    round2/           Round 2 결과
      round2_claude_prompt.md       Step 3 런타임 프롬프트
      round2_claude_analysis.md     Step 3 Claude 심화 분석
      round2_codex_prompt.md        Step 4 런타임 프롬프트
      round2_codex_review.md        Step 4 Codex 비판적 검토
    final/            최종 결과
      final_claude_prompt.md        Step 5 런타임 프롬프트
      final_action_plan.md          최종 계획서
  log/
    orchestrate.log                 통합 진행 로그
    step1_round1_claude.log         Step 1 CLI 출력
    step2_round1_codex.log          Step 2 CLI 출력
    step3_round2_claude.log         Step 3 CLI 출력
    step4_round2_codex.log          Step 4 CLI 출력
    step5_final_claude.log          Step 5 CLI 출력
  state/              오케스트레이터 상태
  prompts/            프롬프트 템플릿
    claude_analyze.md               Claude 분석용 (Round 1, 2 공용)
    codex_critical_review.md        Codex 비판적 검토용 (Round 1, 2 공용)
    claude_final_plan.md            Final 계획서용
```

## 실행 예시
```bash
ai/scripts/orchestrate_ai.sh --issues-file ai/inbox/jira_issues.md
ai/scripts/orchestrate_ai.sh --task-file ai/inbox/task.md
ai/scripts/orchestrate_ai.sh --issues-file ai/inbox/jira_issues.md --resume
ai/scripts/orchestrate_ai.sh --issues-file ai/inbox/jira_issues.md --dry-run
```

## 재실행 동작
- `--resume` 없이 → 기존 result/, log/ 전부 덮어씀
- `--resume` → 실패 지점부터 이어서 실행

## 핵심 원칙
- Claude: 분석/계획 (`--no-mcp`)
- Codex: 비판적 검토 + 코드 검증 (`--approval-mode full-auto`)
- Codex는 Claude의 분석을 맹목적으로 수용하지 않고, 실제 코드와 대조하여 검증
- 재실행 시 덮어쓰기
