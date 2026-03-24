#!/usr/bin/env bash
# =============================================================================
# AI 오케스트레이션 스크립트 (Claude CLI + Codex CLI)
#
# 입력 md 파일을 넣으면 Claude↔Codex 3회 오케스트레이션으로 최종 계획서를 반환.
#
# 사용법:
#   ai/scripts/orchestrate_ai.sh --issues-file ai/inbox/jira_issues.md
#   ai/scripts/orchestrate_ai.sh --task-file ai/inbox/task.md
#   ai/scripts/orchestrate_ai.sh --issues-file ai/inbox/jira_issues.md --resume
#   ai/scripts/orchestrate_ai.sh --issues-file ai/inbox/jira_issues.md --dry-run
# =============================================================================

set -euo pipefail

# ─── 중첩 세션 우회 (Claude Code 내부에서 실행 시) ───
unset CLAUDECODE 2>/dev/null || true

# ─── 색상/스타일 ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── 중단 처리 ───
handle_interrupt() {
  echo ""
  echo -e "${YELLOW}[중단] Ctrl+C로 오케스트레이션이 중단되었습니다.${NC}"
  echo -e "${YELLOW}이어서 실행하려면 --resume 옵션을 추가하세요.${NC}"
  exit 130
}
trap 'handle_interrupt' INT

# ─── 경로 설정 ───
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
AI_DIR="$REPO_ROOT/ai"

PROMPTS_DIR="$AI_DIR/prompts"
RESULT_DIR="$AI_DIR/result"
LOG_DIR="$AI_DIR/log"
STATE_DIR="$AI_DIR/state"
STATE_FILE="$STATE_DIR/orchestrate.state"

ORCHESTRATE_LOG="$LOG_DIR/orchestrate.log"
RUN_CLAUDE="$SCRIPT_DIR/run_claude_task.sh"
RUN_CODEX="$SCRIPT_DIR/run_codex_task.sh"
R1_ANALYSIS_RESULT=""
R2_ANALYSIS_RESULT=""
FINAL_RESULT_PATH=""

usage() {
  cat <<'USAGE'
사용법:
  ai/scripts/orchestrate_ai.sh --issues-file <path> [--provider <ai>] [--reviewer <ai>] [--repo-root <path>] [--resume] [--dry-run]
  ai/scripts/orchestrate_ai.sh --task-file <path> [--provider <ai>] [--reviewer <ai>] [--repo-root <path>] [--resume] [--dry-run]

옵션:
  --issues-file <path>  Jira/QA 입력 md 파일
  --task-file <path>    일반 작업 지시 md 파일
  --provider <name>     분석 단계 AI (Step 1, 3, 5), 기본값 claude
  --reviewer <name>     검토 단계 AI (Step 2, 4), 기본값 codex
                        지원값: claude | codex | gemini | copilot
  --repo-root <path>    AI가 참고할 프로젝트 폴더 (기본값: 스크립트 기준 두 단계 상위)
  --resume              이전 state 기준 재개
  --dry-run             실제 CLI 호출 없이 프롬프트/흐름만 점검
  -h, --help            도움말 출력
USAGE
}

prompt_ai_selection() {
  local title="$1"
  local default_val="$2"

  if [[ ! -t 0 ]]; then
    printf '%s\n' "$default_val"
    return 0
  fi

  printf '\n' > /dev/tty
  printf '%s\n' "$title" > /dev/tty
  printf '%s\n' "  1) claude" > /dev/tty
  printf '%s\n' "  2) codex" > /dev/tty
  printf '%s\n' "  3) gemini" > /dev/tty
  printf '%s\n' "  4) copilot" > /dev/tty

  while true; do
    printf '%s' "선택 [1-4] (기본값: $default_val): " > /dev/tty
    read -r selection < /dev/tty || true

    [[ -z "$selection" ]] && { printf '%s\n' "$default_val"; return 0; }
    [[ "$selection" == "1" || "$selection" == "claude" ]]  && { printf 'claude\n';  return 0; }
    [[ "$selection" == "2" || "$selection" == "codex" ]]   && { printf 'codex\n';   return 0; }
    [[ "$selection" == "3" || "$selection" == "gemini" ]]  && { printf 'gemini\n';  return 0; }
    [[ "$selection" == "4" || "$selection" == "copilot" ]] && { printf 'copilot\n'; return 0; }

    printf '%s\n' "지원하지 않는 선택입니다. 1~4 중에서 고르세요." > /dev/tty
  done
}

prompt_provider_selection() {
  prompt_ai_selection "분석 AI를 선택하세요 (Step 1, 3, 5):" "claude"
}

prompt_reviewer_selection() {
  prompt_ai_selection "검토 AI를 선택하세요 (Step 2, 4):" "codex"
}

# ─── 인수 파싱 ───
INPUT_FILE=""
RESUME=false
DRY_RUN=false
PROVIDER=""
REVIEWER=""
REPO_ROOT_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issues-file|--task-file)
      INPUT_FILE="$2"; shift 2 ;;
    --resume)
      RESUME=true; shift ;;
    --provider)
      PROVIDER="$2"; shift 2 ;;
    --reviewer)
      REVIEWER="$2"; shift 2 ;;
    --repo-root)
      REPO_ROOT_OVERRIDE="$2"; shift 2 ;;
    --dry-run)
      DRY_RUN=true; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo -e "${RED}알 수 없는 옵션: $1${NC}"; exit 1 ;;
  esac
done

if [[ -n "$REPO_ROOT_OVERRIDE" ]]; then
  if [[ ! -d "$REPO_ROOT_OVERRIDE" ]]; then
    echo -e "${RED}--repo-root 경로가 존재하지 않습니다: $REPO_ROOT_OVERRIDE${NC}"
    exit 1
  fi
  REPO_ROOT="$(cd "$REPO_ROOT_OVERRIDE" && pwd)"
fi

if [[ -z "$INPUT_FILE" ]]; then
  usage
  exit 1
fi

if [[ ! -f "$REPO_ROOT/$INPUT_FILE" && ! -f "$INPUT_FILE" ]]; then
  echo -e "${RED}입력 파일을 찾을 수 없습니다: $INPUT_FILE${NC}"
  exit 1
fi

# 절대 경로 변환
if [[ -f "$REPO_ROOT/$INPUT_FILE" ]]; then
  INPUT_PATH="$REPO_ROOT/$INPUT_FILE"
else
  INPUT_PATH="$(cd "$(dirname "$INPUT_FILE")" && pwd)/$(basename "$INPUT_FILE")"
fi

if [[ ! -x "$RUN_CLAUDE" || ! -x "$RUN_CODEX" ]]; then
  echo -e "${RED}실행 스크립트를 찾을 수 없거나 실행 권한이 없습니다.${NC}"
  echo -e "${RED}- $RUN_CLAUDE${NC}"
  echo -e "${RED}- $RUN_CODEX${NC}"
  exit 1
fi

# ─── Codex 작업 디렉터리 설정 ───
# 프로젝트 경로를 명시한 경우: 해당 경로에서 실행 (코드 파일 탐색 가능)
# 명시하지 않은 경우: task 파일만 있는 격리 임시 폴더에서 실행 (다른 inbox 파일 오염 방지)
CODEX_WORKDIR=""
_codex_tmpdir=""
if [[ -n "$REPO_ROOT_OVERRIDE" ]]; then
  CODEX_WORKDIR="$REPO_ROOT"
else
  _codex_tmpdir="$(mktemp -d)"
  CODEX_WORKDIR="$_codex_tmpdir"
  cp "$INPUT_PATH" "$CODEX_WORKDIR/" 2>/dev/null || true
fi

_cleanup_codex_tmpdir() {
  [[ -n "$_codex_tmpdir" ]] && rm -rf "$_codex_tmpdir"
}
trap '_cleanup_codex_tmpdir' EXIT

# ─── 디렉터리 생성 ───
mkdir -p "$RESULT_DIR/round1" "$RESULT_DIR/round2" "$RESULT_DIR/final"
mkdir -p "$LOG_DIR" "$STATE_DIR"

# ─── 유틸 함수 ───
timestamp() {
  date '+%Y-%m-%d %H:%M:%S %z'
}

log() {
  local msg="$(timestamp) $1"
  echo "$msg" >> "$ORCHESTRATE_LOG"
  echo -e "$msg"
}

log_box() {
  local msg="$1"
  local line
  line=$(printf '═%.0s' $(seq 1 42))
  log "╔${line}╗"
  log "║   ${msg}"
  log "╚${line}╝"
}

log_separator() {
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

provider_label() {
  case "$1" in
    claude)  printf 'Claude' ;;
    codex)   printf 'Codex' ;;
    gemini)  printf 'Gemini' ;;
    copilot) printf 'Copilot' ;;
    *)       printf '%s' "$1" ;;
  esac
}

run_and_capture() {
  local step_log="$1"
  shift
  local rc=0

  "$@" || rc=$?

  if [[ -f "$step_log" ]]; then
    awk '/^[0-9]{4}-[0-9]{2}-[0-9]{2} / {print}' "$step_log" >> "$ORCHESTRATE_LOG"
  fi

  return "$rc"
}

find_stage_result() {
  local dir="$1"
  local prefix="$2"

  if [[ -n "${3:-}" && -f "$3" ]]; then
    printf '%s\n' "$3"
    return 0
  fi

  local found=""
  found="$(find "$dir" -maxdepth 1 -type f -name "${prefix}_*_result.md" | sort | head -n 1)"
  if [[ -n "$found" ]]; then
    printf '%s\n' "$found"
    return 0
  fi

  return 1
}

run_claude_stage_with_fallback() {
  local prompt_file="$1"
  local output_dir="$2"
  local output_prefix="$3"
  local output_file=""
  local step_log="$4"
  local selected_provider="$PROVIDER"
  local rc=0

  while true; do
    : > "$step_log"
    rc=0
    output_file="$output_dir/${output_prefix}_${selected_provider}_result.md"

    run_and_capture "$step_log" \
      "$RUN_CLAUDE" \
      --prompt-file "$prompt_file" \
      --output-file "$output_file" \
      --provider "$selected_provider" \
      --repo-root "$REPO_ROOT" \
      --log-file "$step_log" || rc=$?

    if [[ "$rc" -eq 0 ]]; then
      LAST_STAGE_PROVIDER="$selected_provider"
      LAST_STAGE_OUTPUT="$output_file"
      return 0
    fi

    if [[ "$rc" -ne 21 || "$selected_provider" != "claude" ]]; then
      return "$rc"
    fi

    selected_provider="codex"
    log "[대체] Claude 실패로 provider=$selected_provider 재시도"
    rc=0
  done
}

run_reviewer_stage() {
  local prompt_file="$1"
  local output_file="$2"
  local step_log="$3"
  local rc=0

  : > "$step_log"
  run_and_capture "$step_log" \
    "$RUN_CLAUDE" \
    --prompt-file "$prompt_file" \
    --output-file "$output_file" \
    --provider "$REVIEWER" \
    --repo-root "$CODEX_WORKDIR" \
    --log-file "$step_log" || rc=$?

  return "$rc"
}

save_state() {
  echo "$1" > "$STATE_FILE"
}

get_state() {
  if [[ -f "$STATE_FILE" ]]; then
    cat "$STATE_FILE"
  else
    echo "0"
  fi
}

# 프롬프트 템플릿에서 변수 치환
render_prompt() {
  local template="$1"
  sed \
    -e "s|__REPO_ROOT__|$REPO_ROOT|g" \
    -e "s|__TIMESTAMP__|$(timestamp)|g" \
    "$template"
}

# ─── 상태 복원 (--resume) ───
START_STEP=1
if $RESUME; then
  START_STEP=$(get_state)
  if [[ "$START_STEP" -ge 6 ]]; then
    echo -e "${GREEN}이미 모든 단계가 완료되었습니다.${NC}"
    exit 0
  fi
  echo -e "${YELLOW}Step $START_STEP 부터 재개합니다.${NC}"
fi

if [[ -z "$PROVIDER" ]]; then
  if [[ -n "${AI_PROVIDER:-}" ]]; then
    PROVIDER="$AI_PROVIDER"
  else
    PROVIDER="$(prompt_provider_selection)"
  fi
fi

if [[ -z "$REVIEWER" ]]; then
  if [[ -n "${AI_REVIEWER:-}" ]]; then
    REVIEWER="$AI_REVIEWER"
  else
    REVIEWER="$(prompt_reviewer_selection)"
  fi
fi

for _ai_val in "$PROVIDER" "$REVIEWER"; do
  case "$_ai_val" in
    claude|codex|gemini|copilot) ;;
    *)
      echo -e "${RED}지원하지 않는 AI 값입니다: $_ai_val${NC}"
      exit 1
      ;;
  esac
done
unset _ai_val

# ─── 덮어쓰기 (--resume 없이) ───
if ! $RESUME; then
  # 기존 결과/로그 정리
  rm -f "$RESULT_DIR/round1/"*.md "$RESULT_DIR/round2/"*.md "$RESULT_DIR/final/"*.md
  rm -f "$LOG_DIR/step"*.log
  : > "$ORCHESTRATE_LOG"
fi

# ─── 시작 ───
log_box "AI 오케스트레이션 시작 (3회)"
if [[ -n "$REPO_ROOT_OVERRIDE" ]]; then
  log "[설정] input=$INPUT_FILE mode=wrapper-shell provider=$PROVIDER reviewer=$REVIEWER codex-workdir=${CODEX_WORKDIR#$REPO_ROOT/}"
else
  log "[설정] input=$INPUT_FILE mode=wrapper-shell provider=$PROVIDER reviewer=$REVIEWER codex-workdir=isolated(task only)"
fi
log_separator

INPUT_CONTENT="$(cat "$INPUT_PATH")"

# =============================================================================
# Step 1: Round 1 — 분석
# =============================================================================
run_step1() {
  local prompt_out="$RESULT_DIR/round1/round1_${PROVIDER}_prompt.md"
  local step_log="$LOG_DIR/step1_round1_${PROVIDER}.log"

  log "[Step 1/5] Round1 $(provider_label "$PROVIDER") 분석"
  log "  입력: $INPUT_FILE"
  log "  출력: ai/result/round1/round1_${PROVIDER}_result.md"

  if $DRY_RUN; then
    log "  [DRY-RUN] 스킵"; return 0
  fi

  # 프롬프트 조립: 템플릿 + 원본 입력
  {
    render_prompt "$PROMPTS_DIR/claude_analyze.md"
    echo ""
    echo "## 분석 대상 입력"
    echo ""
    echo "--- 원본 입력 ---"
    echo "$INPUT_CONTENT"
  } > "$prompt_out"

  run_claude_stage_with_fallback "$prompt_out" "$RESULT_DIR/round1" "round1" "$step_log"
  R1_ANALYSIS_RESULT="$LAST_STAGE_OUTPUT"

  log "[Step 1 성공] Round1 $(provider_label "$LAST_STAGE_PROVIDER") 분석 완료"
  log "  결과 파일: ${R1_ANALYSIS_RESULT#$REPO_ROOT/}"
  save_state 2
}

# =============================================================================
# Step 2: Round 1 — 비판적 검토
# =============================================================================
run_step2() {
  local analysis_result=""
  local output="$RESULT_DIR/round1/round1_${REVIEWER}_review.md"
  local prompt_out="$RESULT_DIR/round1/round1_${REVIEWER}_prompt.md"
  local step_log="$LOG_DIR/step2_round1_${REVIEWER}.log"

  log "[Step 2/5] Round1 $(provider_label "$REVIEWER") 비판적 검토"
  log "  입력: round1_${PROVIDER}_result.md + ${INPUT_FILE##*/}"
  log "  출력: ${output#$REPO_ROOT/}"

  if $DRY_RUN; then
    log "  [DRY-RUN] 스킵"; return 0
  fi

  analysis_result="$(find_stage_result "$RESULT_DIR/round1" "round1" "$R1_ANALYSIS_RESULT")" || {
    echo "[오류] Round1 분석 결과 파일을 찾을 수 없습니다." >&2
    return 1
  }
  log "  실제 입력: $(basename "$analysis_result")"

  {
    render_prompt "$PROMPTS_DIR/codex_critical_review.md"
    echo ""
    echo "## Round 1 $(provider_label "$REVIEWER") 비판적 검토 입력"
    echo ""
    echo "--- 원본 입력 ---"
    echo "$INPUT_CONTENT"
    echo ""
    echo "--- Round 1 $(provider_label "$PROVIDER") 분석 결과 ---"
    cat "$analysis_result"
  } > "$prompt_out"

  run_reviewer_stage "$prompt_out" "$output" "$step_log"

  local findings
  findings=$(grep -m3 '^\- ' "$output" 2>/dev/null | head -3 | tr '\n' ', ' || echo "결과 확인 필요")
  log "[Step 2 성공] Round1 $(provider_label "$REVIEWER") 비판적 검토 완료"
  log "  주요 발견: ${findings}"
  save_state 3
}

# =============================================================================
# Step 3: Round 2 — 심화 분석
# =============================================================================
run_step3() {
  local r1_analysis=""
  local r1_review="$RESULT_DIR/round1/round1_${REVIEWER}_review.md"
  local prompt_out="$RESULT_DIR/round2/round2_${PROVIDER}_prompt.md"
  local step_log="$LOG_DIR/step3_round2_${PROVIDER}.log"

  log "[Step 3/5] Round2 $(provider_label "$PROVIDER") 심화 분석"
  log "  입력: ${INPUT_FILE##*/} + round1 결과 전체"
  log "  출력: ai/result/round2/round2_${PROVIDER}_result.md"

  if $DRY_RUN; then
    log "  [DRY-RUN] 스킵"; return 0
  fi

  r1_analysis="$(find_stage_result "$RESULT_DIR/round1" "round1" "$R1_ANALYSIS_RESULT")" || {
    echo "[오류] Round1 분석 결과 파일을 찾을 수 없습니다." >&2
    return 1
  }
  log "  실제 입력: $(basename "$r1_analysis"), $(basename "$r1_review")"

  {
    render_prompt "$PROMPTS_DIR/claude_analyze.md"
    echo ""
    echo "## 심화 분석 지시"
    echo ""
    echo "이것은 Round 2 심화 분석입니다."
    echo "Round 1의 $(provider_label "$PROVIDER") 분석과 $(provider_label "$REVIEWER") 비판적 검토를 모두 반영하여 심화 분석을 수행하세요."
    echo "$(provider_label "$REVIEWER")가 지적한 사실 오류와 누락을 반드시 수용/반영하고, 수용 여부를 테이블로 명시하세요."
    echo ""
    echo "## 입력 자료"
    echo ""
    echo "--- 원본 입력 ---"
    echo "$INPUT_CONTENT"
    echo ""
    echo "--- Round 1 $(provider_label "$PROVIDER") 분석 결과 ---"
    cat "$r1_analysis"
    echo ""
    echo "--- Round 1 $(provider_label "$REVIEWER") 비판적 검토 결과 ---"
    cat "$r1_review"
  } > "$prompt_out"

  run_claude_stage_with_fallback "$prompt_out" "$RESULT_DIR/round2" "round2" "$step_log"
  R2_ANALYSIS_RESULT="$LAST_STAGE_OUTPUT"

  local accepted
  accepted=$(grep -c '수용' "$R2_ANALYSIS_RESULT" 2>/dev/null || echo "0")
  log "[Step 3 성공] Round2 $(provider_label "$LAST_STAGE_PROVIDER") 심화 분석 완료 ($(provider_label "$REVIEWER") 피드백 ${accepted}건 수용)"
  log "  결과 파일: ${R2_ANALYSIS_RESULT#$REPO_ROOT/}"
  save_state 4
}

# =============================================================================
# Step 4: Round 2 — 비판적 검토
# =============================================================================
run_step4() {
  local r2_analysis=""
  local output="$RESULT_DIR/round2/round2_${REVIEWER}_review.md"
  local prompt_out="$RESULT_DIR/round2/round2_${REVIEWER}_prompt.md"
  local step_log="$LOG_DIR/step4_round2_${REVIEWER}.log"

  log "[Step 4/5] Round2 $(provider_label "$REVIEWER") 비판적 검토"
  log "  입력: round2_${PROVIDER}_result.md + ${INPUT_FILE##*/}"
  log "  출력: ${output#$REPO_ROOT/}"

  if $DRY_RUN; then
    log "  [DRY-RUN] 스킵"; return 0
  fi

  r2_analysis="$(find_stage_result "$RESULT_DIR/round2" "round2" "$R2_ANALYSIS_RESULT")" || {
    echo "[오류] Round2 분석 결과 파일을 찾을 수 없습니다." >&2
    return 1
  }
  log "  실제 입력: $(basename "$r2_analysis")"

  {
    render_prompt "$PROMPTS_DIR/codex_critical_review.md"
    echo ""
    echo "## Round 2 $(provider_label "$REVIEWER") 비판적 검토 입력"
    echo ""
    echo "--- 원본 입력 ---"
    echo "$INPUT_CONTENT"
    echo ""
    echo "--- Round 2 $(provider_label "$PROVIDER") 분석 결과 ---"
    cat "$r2_analysis"
  } > "$prompt_out"

  run_reviewer_stage "$prompt_out" "$output" "$step_log"

  local findings
  findings=$(grep -m3 '^\- ' "$output" 2>/dev/null | head -3 | tr '\n' ', ' || echo "결과 확인 필요")
  log "[Step 4 성공] Round2 $(provider_label "$REVIEWER") 비판적 검토 완료"
  log "  주요 발견: ${findings}"
  save_state 5
}

# =============================================================================
# Step 5: Final — 최종 계획서
# =============================================================================
run_step5() {
  local r1_analysis=""
  local r1_review="$RESULT_DIR/round1/round1_${REVIEWER}_review.md"
  local r2_analysis=""
  local r2_review="$RESULT_DIR/round2/round2_${REVIEWER}_review.md"
  local prompt_out="$RESULT_DIR/final/final_${PROVIDER}_prompt.md"
  local step_log="$LOG_DIR/step5_final_${PROVIDER}.log"

  log "[Step 5/5] Final $(provider_label "$PROVIDER") 최종 계획서"
  log "  입력: ${INPUT_FILE##*/} + round1 + round2 전체"
  log "  출력: ai/result/final/final_${PROVIDER}_result.md"

  if $DRY_RUN; then
    log "  [DRY-RUN] 스킵"; return 0
  fi

  r1_analysis="$(find_stage_result "$RESULT_DIR/round1" "round1" "$R1_ANALYSIS_RESULT")" || {
    echo "[오류] Round1 분석 결과 파일을 찾을 수 없습니다." >&2
    return 1
  }
  r2_analysis="$(find_stage_result "$RESULT_DIR/round2" "round2" "$R2_ANALYSIS_RESULT")" || {
    echo "[오류] Round2 분석 결과 파일을 찾을 수 없습니다." >&2
    return 1
  }
  log "  실제 입력: $(basename "$r1_analysis"), $(basename "$r1_review"), $(basename "$r2_analysis"), $(basename "$r2_review")"

  {
    render_prompt "$PROMPTS_DIR/claude_final_plan.md"
    echo ""
    echo "## 종합 입력 자료"
    echo ""
    echo "--- 원본 입력 ---"
    echo "$INPUT_CONTENT"
    echo ""
    echo "--- Round 1 $(provider_label "$PROVIDER") 분석 ---"
    cat "$r1_analysis"
    echo ""
    echo "--- Round 1 $(provider_label "$REVIEWER") 비판적 검토 ---"
    cat "$r1_review"
    echo ""
    echo "--- Round 2 $(provider_label "$PROVIDER") 심화 분석 ---"
    cat "$r2_analysis"
    echo ""
    echo "--- Round 2 $(provider_label "$REVIEWER") 비판적 검토 ---"
    cat "$r2_review"
  } > "$prompt_out"

  run_claude_stage_with_fallback "$prompt_out" "$RESULT_DIR/final" "final" "$step_log"
  FINAL_RESULT_PATH="$LAST_STAGE_OUTPUT"

  log "[Step 5 성공] 최종 결과 작성 완료 provider=$(provider_label "$LAST_STAGE_PROVIDER")"
  log "  결과 파일: ${FINAL_RESULT_PATH#$REPO_ROOT/}"
  save_state 6
}

# =============================================================================
# 실행
# =============================================================================
[[ $START_STEP -le 1 ]] && { run_step1; log_separator; }
[[ $START_STEP -le 2 ]] && { run_step2; log_separator; }
[[ $START_STEP -le 3 ]] && { run_step3; log_separator; }
[[ $START_STEP -le 4 ]] && { run_step4; log_separator; }
[[ $START_STEP -le 5 ]] && { run_step5; log_separator; }

# ─── 완료 ───
echo ""
log_box "오케스트레이션 완료"
log ""
log "결과물:"
log "  Round 1 $(provider_label "$PROVIDER") 분석:  ${R1_ANALYSIS_RESULT#$REPO_ROOT/}"
log "  Round 1 $(provider_label "$REVIEWER") 검토:  ai/result/round1/round1_${REVIEWER}_review.md"
log "  Round 2 $(provider_label "$PROVIDER") 분석:  ${R2_ANALYSIS_RESULT#$REPO_ROOT/}"
log "  Round 2 $(provider_label "$REVIEWER") 검토:  ai/result/round2/round2_${REVIEWER}_review.md"
log "  Final Result:         ${FINAL_RESULT_PATH#$REPO_ROOT/}"
