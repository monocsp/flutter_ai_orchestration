#!/usr/bin/env bash
set -euo pipefail

handle_interrupt() {
  printf '\n\n[중단] Ctrl+C로 취소되었습니다.\n' >&2
  exit 130
}
trap 'handle_interrupt' INT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$SCRIPT_DIR/templates"
OUTPUT_ROOT="${1:-$SCRIPT_DIR/output}"

timestamp="$(date '+%Y%m%d_%H%M%S')"
created_at="$(date '+%Y-%m-%d %H:%M:%S')"

write_utf8_file() {
  local path="$1"
  local content="$2"
  mkdir -p "$(dirname "$path")"
  printf '%s' "$content" > "$path"
}

read_required_text() {
  local prompt="$1"
  local value=""

  while true; do
    printf '%s: ' "$prompt" >&2
    IFS= read -r value
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    if [[ -n "$value" ]]; then
      printf '%s\n' "$value"
      return 0
    fi
    printf '값이 필요합니다. 다시 입력하세요.\n' >&2
  done
}

read_existing_path() {
  local prompt="$1"
  local value=""

  while true; do
    value="$(read_required_text "$prompt")"
    if [[ -e "$value" ]]; then
      if [[ -d "$value" ]]; then
        (cd "$value" && pwd)
      else
        local dir base
        dir="$(cd "$(dirname "$value")" && pwd)"
        base="$(basename "$value")"
        printf '%s/%s\n' "$dir" "$base"
      fi
      return 0
    fi
    printf '존재하는 파일 경로를 입력하세요.\n' >&2
  done
}

read_text_with_default() {
  local prompt="$1"
  local default_value="$2"
  local value=""

  printf '%s [기본값: %s]: ' "$prompt" "$default_value" >&2
  IFS= read -r value
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  if [[ -z "$value" ]]; then
    printf '%s\n' "$default_value"
  else
    printf '%s\n' "$value"
  fi
}

read_choice() {
  local title="$1"
  local default_index="$2"
  shift 2
  local choices=("$@")
  local raw="" idx=1

  printf '\n%s\n' "$title" >&2
  for choice in "${choices[@]}"; do
    printf '  [%d] %s\n' "$idx" "$choice" >&2
    idx=$((idx + 1))
  done

  while true; do
    printf '선택하세요 [1-%d] (기본값: %d): ' "${#choices[@]}" "$((default_index + 1))" >&2
    IFS= read -r raw
    raw="${raw#"${raw%%[![:space:]]*}"}"
    raw="${raw%"${raw##*[![:space:]]}"}"

    if [[ -z "$raw" ]]; then
      printf '%s\n' "${choices[$default_index]}"
      return 0
    fi

    if [[ "$raw" =~ ^[0-9]+$ ]] && (( raw >= 1 && raw <= ${#choices[@]} )); then
      printf '%s\n' "${choices[$((raw - 1))]}"
      return 0
    fi

    for choice in "${choices[@]}"; do
      if [[ "$choice" == "$raw" ]]; then
        printf '%s\n' "$choice"
        return 0
      fi
    done

    printf '지원하지 않는 선택입니다. 번호 또는 표시된 값을 사용하세요.\n' >&2
  done
}

provider_setup_text() {
  case "$1" in
    "Codex CLI")
      cat <<'EOF'
- 프로젝트 루트에서 Codex CLI를 실행하세요.
- 가능하면 대상 저장소를 열어 둔 상태에서 시작하세요.
- 프롬프트는 라운드별로 하나씩 붙여넣고, 이전 라운드 결과는 요약하지 말고 그대로 함께 제공하세요.
EOF
      ;;
    "Claude CLI")
      cat <<'EOF'
- 프로젝트 루트 또는 관련 문서가 보이는 위치에서 Claude CLI를 실행하세요.
- 긴 프롬프트는 한 번에 통째로 붙여넣고, 문서와 이전 결과를 함께 제공하세요.
- 답변이 유려해 보여도 파일 근거가 약하면 반드시 재검증을 요구하세요.
EOF
      ;;
    "Gemini CLI")
      cat <<'EOF'
- 프로젝트와 기준 문서에 접근 가능한 상태에서 Gemini CLI를 실행하세요.
- 각 라운드 프롬프트와 필요한 문서를 함께 붙여넣으세요.
- 이전 라운드 결과는 핵심만 재진술하지 말고 원문 기준으로 다시 검토하게 하세요.
EOF
      ;;
    "GitHub Copilot CLI")
      cat <<'EOF'
- 프로젝트 루트에서 Copilot CLI를 실행하세요 (COPILOT_GITHUB_TOKEN 또는 GH_TOKEN 필요).
- 프롬프트는 라운드별로 하나씩 붙여넣고, 이전 결과를 함께 제공하세요.
- 답변이 간결하면 파일 경로와 호출 체인을 추가로 요구하세요.
EOF
      ;;
    *)
      cat <<'EOF'
- 대상 프로젝트와 기준 문서에 접근 가능한 환경에서 CLI를 실행하세요.
- 라운드별 프롬프트를 순서대로 넣고, 각 라운드의 결과를 다음 라운드 입력으로 넘기세요.
- 툴 특성이 다르더라도 파일 근거, 호출 체인, 회귀 위험 검증은 동일하게 요구하세요.
EOF
      ;;
  esac
}

provider_paste_advice_text() {
  case "$1" in
    "Codex CLI")
      cat <<'EOF'
- 모델이 추상적으로 답하면 직접 수정 파일과 간접 영향 파일을 표로 다시 쓰게 하세요.
- 모델이 파일 검증 없이 결론 내리면 실제 경로와 호출 체인을 다시 확인하라고 요구하세요.
EOF
      ;;
    "Claude CLI")
      cat <<'EOF'
- 문장이 좋더라도 실제 경로, 호출 체인, 회귀 포인트가 없으면 다시 쓰게 하세요.
- 입력 문서를 단순 요약하는 답변이 나오면 코드 기준 재분석을 요구하세요.
EOF
      ;;
    "Gemini CLI")
      cat <<'EOF'
- 모델이 대안을 충분히 비교하지 않으면 더 안전한 대안과 더 단순한 대안을 둘 다 쓰게 하세요.
- 답변에 테스트 계획이 빠지면 코드 검증과 수동 검증 순서를 추가하게 하세요.
EOF
      ;;
    "GitHub Copilot CLI")
      cat <<'EOF'
- 답변이 짧고 추상적이면 수정 파일과 영향 범위를 표로 다시 쓰게 하세요.
- 파일 검증 없이 결론 내리면 실제 경로와 호출 체인을 다시 확인하라고 요구하세요.
EOF
      ;;
    *)
      cat <<'EOF'
- 답변이 추상적이면 파일 경로와 검증 근거를 반드시 추가하게 하세요.
- 입력 문서를 복사한 수준이면 실제 수정 대상과 리스크를 다시 분리하게 하세요.
EOF
      ;;
  esac
}

provider_follow_up_text() {
  case "$1" in
    "Codex CLI")
      cat <<'EOF'
- 답변에 confirmed / assumed 구분이 없으면 사실과 가정을 분리해 달라고 요청하세요.
- 회귀 위험이 약하면 상태 관리, 라이프사이클, 공통 컴포넌트 영향을 다시 검토하게 하세요.
EOF
      ;;
    "Claude CLI")
      cat <<'EOF'
- 모호한 부분이 남으면 확인 필요 항목을 따로 표로 분리하라고 요청하세요.
- 최종안에는 구현 순서와 검증 순서가 모두 있어야 한다고 다시 상기시키세요.
EOF
      ;;
    "Gemini CLI")
      cat <<'EOF'
- 파일이 후보인지 실제 사용 경로인지 구분해서 다시 쓰라고 요청하세요.
- 최종안에 선확인 항목이 빠지면 정책/디자인 확인 항목을 따로 분리하게 하세요.
EOF
      ;;
    "GitHub Copilot CLI")
      cat <<'EOF'
- 모호한 부분이 남으면 확인 필요 항목을 표로 분리하라고 요청하세요.
- 최종안에는 구현 순서와 검증 순서가 모두 있어야 합니다.
EOF
      ;;
    *)
      cat <<'EOF'
- 코드 미검증이면 그 사실을 숨기지 말고 명시하게 하세요.
- 최종 계획에는 우선순위, 직접 수정 파일, 검증 계획이 모두 있어야 합니다.
EOF
      ;;
  esac
}

render_template() {
  local template_path="$1"
  local output_path="$2"

  TEMPLATE_PATH="$template_path" \
  OUTPUT_PATH="$output_path" \
  SOURCE_DOCUMENT_PATH="$source_document_path" \
  PROVIDER_NAME="$provider_name" \
  RUN_OBJECTIVE="$run_objective" \
  CRITICISM_LEVEL="$criticism_level" \
  RISK_FOCUS="$risk_focus" \
  OUTPUT_FORMAT="$output_format" \
  SESSION_CREATED_AT="$created_at" \
  ANALYSIS_RESULT_PATH="$analysis_result_path" \
  CRITICAL_REVIEW_RESULT_PATH="$critical_review_result_path" \
  FINAL_RESULT_PATH="$final_result_path" \
  ruby <<'RUBY'
template = File.read(ENV.fetch("TEMPLATE_PATH"))
variables = {
  "SOURCE_DOCUMENT_PATH" => ENV.fetch("SOURCE_DOCUMENT_PATH"),
  "PROVIDER_NAME" => ENV.fetch("PROVIDER_NAME"),
  "RUN_OBJECTIVE" => ENV.fetch("RUN_OBJECTIVE"),
  "CRITICISM_LEVEL" => ENV.fetch("CRITICISM_LEVEL"),
  "RISK_FOCUS" => ENV.fetch("RISK_FOCUS"),
  "OUTPUT_FORMAT" => ENV.fetch("OUTPUT_FORMAT"),
  "SESSION_CREATED_AT" => ENV.fetch("SESSION_CREATED_AT"),
  "ANALYSIS_RESULT_PATH" => ENV.fetch("ANALYSIS_RESULT_PATH"),
  "CRITICAL_REVIEW_RESULT_PATH" => ENV.fetch("CRITICAL_REVIEW_RESULT_PATH"),
  "FINAL_RESULT_PATH" => ENV.fetch("FINAL_RESULT_PATH")
}

variables.each do |key, value|
  template = template.gsub("{{#{key}}}", value)
end

File.write(ENV.fetch("OUTPUT_PATH"), template)
RUBY
}

new_result_placeholder() {
  local title="$1"
  local path="$2"
  local file_name
  file_name="$(basename "$path")"
  local content
  content=$(
    cat <<EOF
# $title

이 파일에는 AI CLI에서 받은 결과를 붙여넣으세요.

- 생성 시각: $created_at
- 저장 파일: $file_name
EOF
  )
  write_utf8_file "$path" "$content"
}

sanitize_name() {
  printf '%s' "$1" | LC_ALL=C tr -cs '[:alnum:]_.-' '_'
}

printf 'AI 오케스트레이션 전달용 프롬프트 생성기를 시작합니다.\n'
printf '질문에 답하면 어떤 AI CLI에서도 재사용 가능한 라운드별 프롬프트와 실행 가이드를 만들어 줍니다.\n'

source_document_path="$(read_existing_path '1) 기준 문서 파일 경로를 입력하세요')"

# ─── CLI 가용성 확인 ───
printf '\n사용 가능한 AI 확인 중...' >&2

cli_codex_ok=false;   command -v codex   >/dev/null 2>&1 && cli_codex_ok=true
cli_claude_ok=false;  command -v claude  >/dev/null 2>&1 && cli_claude_ok=true
cli_gemini_ok=false;  { command -v gemini >/dev/null 2>&1 || command -v gemini-cli >/dev/null 2>&1; } && cli_gemini_ok=true
cli_copilot_ok=false; command -v copilot >/dev/null 2>&1 && cli_copilot_ok=true

printf ' 완료\n' >&2

label_codex="Codex CLI";              $cli_codex_ok   || label_codex="Codex CLI (설치 안됨)"
label_claude="Claude CLI";            $cli_claude_ok  || label_claude="Claude CLI (설치 안됨)"
label_gemini="Gemini CLI";            $cli_gemini_ok  || label_gemini="Gemini CLI (설치 안됨)"
label_copilot="GitHub Copilot CLI";   $cli_copilot_ok || label_copilot="GitHub Copilot CLI (설치 안됨)"

select_ai_with_check() {
  local question="$1"
  local result=""
  while true; do
    result="$(read_choice "$question" 0 \
      "$label_codex" "$label_claude" "$label_gemini" "$label_copilot" '기타 AI CLI')"
    if [[ "$result" == *"(설치 안됨)"* ]]; then
      printf '해당 CLI가 설치되어 있지 않습니다. 다른 항목을 선택하세요.\n' >&2
      continue
    fi
    break
  done
  case "$result" in
    Codex*)           result="Codex CLI" ;;
    Claude*)          result="Claude CLI" ;;
    Gemini*)          result="Gemini CLI" ;;
    "GitHub Copilot"*) result="GitHub Copilot CLI" ;;
  esac
  printf '%s\n' "$result"
}

provider_name="$(select_ai_with_check '2) 분석 AI를 선택하세요 (Step 1, 3, 5)')"
reviewer_name="$(select_ai_with_check '3) 검토 AI를 선택하세요 (Step 2, 4)')"
run_objective="$(read_choice '4) 이번 실행 목적을 선택하세요' 0 '비판 검토 포함 실행 계획' 'QA/버그 대응 분석' '기능 기획 검증' '리팩터링 계획' '기타')"
if [[ "$run_objective" == "기타" ]]; then
  run_objective="$(read_required_text '실제 실행 목적을 입력하세요')"
fi
criticism_level="$(read_choice '5) 비판 검토 강도를 선택하세요' 2 '낮음' '보통' '높음' '매우 높음')"
risk_focus="$(read_text_with_default '6) 꼭 확인해야 하는 리스크를 입력하세요(쉼표 구분 가능)' '공통 컴포넌트 영향, 상태 관리, 라이프사이클, 회귀 위험')"
output_format="$(read_choice '7) 원하는 결과 형식을 선택하세요' 1 '간결한 실행 계획' '상세 실행 계획' '리스크 중심 검토서' 'QA 체크리스트 포함 결과' '의사결정 로그 포함 결과')"

printf '\n8) AI가 참고할 프로젝트 폴더 경로를 입력하세요\n' >&2
printf '   없으면 Enter로 건너뜁니다: ' >&2
IFS= read -r project_root_input
project_root_input="${project_root_input#"${project_root_input%%[![:space:]]*}"}"
project_root_input="${project_root_input%"${project_root_input##*[![:space:]]}"}"

project_root_path=""
if [[ -n "$project_root_input" ]]; then
  if [[ -d "$project_root_input" ]]; then
    project_root_path="$(cd "$project_root_input" && pwd)"
  else
    printf '폴더가 존재하지 않습니다. 프로젝트 경로 없이 진행합니다.\n' >&2
  fi
fi

source_base_name="$(basename "${source_document_path%.*}")"
safe_source_base_name="$(sanitize_name "$source_base_name")"
session_dir="$OUTPUT_ROOT/session_${timestamp}_${safe_source_base_name}"

mkdir -p "$session_dir"

session_summary_path="$session_dir/00_session_summary.md"
analysis_prompt_path="$session_dir/01_analysis_prompt.md"
critical_review_prompt_path="$session_dir/02_critical_review_prompt.md"
final_plan_prompt_path="$session_dir/03_final_plan_prompt.md"
execution_guide_path="$session_dir/04_execution_guide.md"
analysis_result_path="$session_dir/11_analysis_result.md"
critical_review_result_path="$session_dir/12_critical_review_result.md"
final_result_path="$session_dir/13_final_plan_result.md"

render_template "$TEMPLATE_ROOT/analysis_prompt.md" "$analysis_prompt_path"
render_template "$TEMPLATE_ROOT/critical_review_prompt.md" "$critical_review_prompt_path"
render_template "$TEMPLATE_ROOT/final_plan_prompt.md" "$final_plan_prompt_path"

session_summary=$(
  cat <<EOF
# 세션 요약

- 생성 시각: $created_at
- 기준 문서: $source_document_path
- 참고 프로젝트: ${project_root_path:-(없음)}
- 분석 AI (Step 1,3,5): $provider_name
- 검토 AI (Step 2,4): $reviewer_name
- 실행 목적: $run_objective
- 비판 검토 강도: $criticism_level
- 리스크 포커스: $risk_focus
- 결과 형식: $output_format

## 생성 파일
- 01_analysis_prompt.md
- 02_critical_review_prompt.md
- 03_final_plan_prompt.md
- 04_execution_guide.md
- 11_analysis_result.md
- 12_critical_review_result.md
- 13_final_plan_result.md
EOF
)

execution_guide=$(
  cat <<EOF
# 실행 가이드

## 1. 이번 세션 설정
- 기준 문서: $source_document_path
- 사용 AI: $provider_name
- 실행 목적: $run_objective
- 비판 검토 강도: $criticism_level
- 꼭 확인할 리스크: $risk_focus
- 원하는 결과 형식: $output_format

## 2. 세션 시작 전 준비
$(provider_setup_text "$provider_name")

## 3. 라운드별 실행 순서
1. AI CLI에서 대상 프로젝트를 열거나, 최소한 기준 문서와 관련 코드에 접근 가능한 상태를 만듭니다.
2. 01_analysis_prompt.md와 기준 문서를 함께 넣어 초기 분석을 받습니다.
3. 받은 답변을 11_analysis_result.md에 저장합니다.
4. 02_critical_review_prompt.md, 기준 문서, 11_analysis_result.md를 함께 넣어 비판 검토를 받습니다.
5. 받은 답변을 12_critical_review_result.md에 저장합니다.
6. 03_final_plan_prompt.md, 기준 문서, 11_analysis_result.md, 12_critical_review_result.md를 함께 넣어 최종 계획을 받습니다.
7. 받은 답변을 13_final_plan_result.md에 저장합니다.

## 4. 대화 중 반드시 지킬 운영 규칙
- 파일 경로를 추측으로 쓰지 말고 실제 경로인지 후보 경로인지 구분하게 하세요.
- 사실과 가정을 섞으면 다시 분리해서 작성하게 하세요.
- 공통 컴포넌트, 상태 관리, 라이프사이클, 비동기 타이밍, 회귀 포인트가 빠지면 보완하게 하세요.
- 코드에 직접 접근하지 못한 답변이면 코드 미검증 또는 검증 불가를 명시하게 하세요.
- 최종 결과에는 구현 순서와 검증 순서가 모두 있어야 합니다.

## 5. 답변 품질이 약할 때 바로 쓸 후속 요청
$(provider_paste_advice_text "$provider_name")

$(provider_follow_up_text "$provider_name")

## 6. 저장 규칙
- Round 1 결과 저장: 11_analysis_result.md
- Round 2 결과 저장: 12_critical_review_result.md
- Final 결과 저장: 13_final_plan_result.md
- 원문 요약본을 따로 만들지 말고, AI가 준 원문을 먼저 저장한 뒤 필요하면 사본을 만드세요.
EOF
)

write_utf8_file "$session_summary_path" "$session_summary"
write_utf8_file "$execution_guide_path" "$execution_guide"

new_result_placeholder 'Round 1 분석 결과' "$analysis_result_path"
new_result_placeholder 'Round 2 비판 검토 결과' "$critical_review_result_path"
new_result_placeholder 'Final 종합 계획 결과' "$final_result_path"

if command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "$analysis_prompt_path" || true
fi

printf '\n생성이 완료되었습니다.\n'
printf '세션 폴더: %s\n' "$session_dir"
printf '첫 번째 프롬프트: %s\n' "$analysis_prompt_path"
printf '실행 가이드: %s\n\n' "$execution_guide_path"

# ─── 오케스트레이션 실행 안내 ───
ORCHESTRATE_SCRIPT="$SCRIPT_DIR/../scripts/orchestrate_ai.sh"
ORCHESTRATE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

map_provider_flag() {
  case "$1" in
    "Codex CLI")           printf 'codex\n' ;;
    "Claude CLI")          printf 'claude\n' ;;
    "Gemini CLI")          printf 'gemini\n' ;;
    "GitHub Copilot CLI")  printf 'copilot\n' ;;
    *)                     printf 'codex\n' ;;
  esac
}

provider_flag="$(map_provider_flag "$provider_name")"
reviewer_flag="$(map_provider_flag "$reviewer_name")"

rel_source=""
if [[ "$source_document_path" == "$ORCHESTRATE_ROOT/"* ]]; then
  rel_source="${source_document_path#$ORCHESTRATE_ROOT/}"
else
  rel_source="$source_document_path"
fi

repo_root_arg=""
if [[ -n "$project_root_path" ]]; then
  repo_root_arg="--repo-root '$project_root_path'"
fi

orchestrate_cmd="cd '$ORCHESTRATE_ROOT' && ai/scripts/orchestrate_ai.sh --task-file '$rel_source' --provider $provider_flag --reviewer $reviewer_flag${repo_root_arg:+ $repo_root_arg}"

if [[ -x "$ORCHESTRATE_SCRIPT" ]]; then
  printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  printf '오케스트레이션 실행 명령어\n'
  printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  printf '%s\n\n' "$orchestrate_cmd"
  printf '위 명령어를 터미널에 복사 붙여넣기해서 실행하세요.\n'
  printf '또는 지금 바로 실행하려면 Enter를 누르세요. (건너뛰려면 q 입력)\n'
  printf '선택: ' >&2
  IFS= read -r run_now
  run_now="${run_now#"${run_now%%[![:space:]]*}"}"
  run_now="${run_now%"${run_now##*[![:space:]]}"}"
  if [[ -z "$run_now" ]]; then
    printf '\n오케스트레이션을 시작합니다...\n\n'
    if [[ -n "$project_root_path" ]]; then
      (cd "$ORCHESTRATE_ROOT" && "$ORCHESTRATE_SCRIPT" --task-file "$rel_source" --provider "$provider_flag" --reviewer "$reviewer_flag" --repo-root "$project_root_path")
    else
      (cd "$ORCHESTRATE_ROOT" && "$ORCHESTRATE_SCRIPT" --task-file "$rel_source" --provider "$provider_flag" --reviewer "$reviewer_flag")
    fi
  else
    printf '\n아래 명령어를 터미널에서 실행하세요.\n\n'
    printf '%s\n' "$orchestrate_cmd"
  fi
else
  printf '\n다음 순서로 진행하세요.\n'
  printf '1. 선택한 AI CLI를 프로젝트와 함께 엽니다.\n'
  printf '2. 01_analysis_prompt.md를 기준 문서와 함께 넣습니다.\n'
  printf '3. 응답을 11_analysis_result.md에 저장합니다.\n'
  printf '4. 02_critical_review_prompt.md로 비판 검토를 진행합니다.\n'
  printf '5. 03_final_plan_prompt.md로 최종 계획을 받습니다.\n'
fi
