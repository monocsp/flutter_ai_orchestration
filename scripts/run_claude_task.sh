#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
사용법:
  ai/scripts/run_claude_task.sh \
    --prompt-file <프롬프트 파일> \
    --output-file <출력 파일> \
    [--provider <claude|codex|gemini>] \
    [--repo-root <저장소 루트>] \
    [--log-file <로그 파일>] \
    [--dry-run]

설명:
  - Claude 단계용 멀티 프로바이더 실행 래퍼입니다.
  - 프롬프트 파일 내용을 읽어 결과를 출력 파일에 저장합니다.
  - provider 기본값은 claude 입니다.

종료 코드:
  0  성공
  2  인자 오류
  3  입력 파일 오류
  4  선택한 CLI 미설치
  20 provider 실행 실패
  21 Claude fallback 가능 상태
USAGE
}

prompt_file=""
output_file=""
log_file=""
dry_run=0
provider=""
repo_root="$(pwd)"
script_dir="$(cd "$(dirname "$0")" && pwd -P)"
run_codex_script="$script_dir/run_codex_task.sh"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --prompt-file)
      prompt_file="$2"
      shift 2
      ;;
    --output-file)
      output_file="$2"
      shift 2
      ;;
    --provider)
      provider="$2"
      shift 2
      ;;
    --repo-root)
      repo_root="$2"
      shift 2
      ;;
    --log-file)
      log_file="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[오류] 알 수 없는 인자입니다: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "$prompt_file" ] || [ -z "$output_file" ]; then
  echo "[오류] --prompt-file, --output-file는 필수입니다." >&2
  usage >&2
  exit 2
fi

if [ ! -f "$prompt_file" ]; then
  echo "[오류] 프롬프트 파일이 없습니다: $prompt_file" >&2
  exit 3
fi

if [ ! -d "$repo_root" ]; then
  echo "[오류] repo 루트가 존재하지 않습니다: $repo_root" >&2
  exit 3
fi

prompt_abs="$(cd "$(dirname "$prompt_file")" && pwd -P)/$(basename "$prompt_file")"
repo_root_abs="$(cd "$repo_root" && pwd -P)"

mkdir -p "$(dirname "$output_file")"
if [ -n "$log_file" ]; then
  mkdir -p "$(dirname "$log_file")"
fi

timestamp() {
  date '+%Y-%m-%d %H:%M:%S %z'
}

append_log() {
  if [ -n "$log_file" ]; then
    printf '%s %s\n' "$(timestamp)" "$1" >> "$log_file"
  fi
}

provider_label() {
  case "$1" in
    claude) printf 'Claude\n' ;;
    codex) printf 'Codex\n' ;;
    gemini) printf 'Gemini\n' ;;
    *) printf '%s\n' "$1" ;;
  esac
}

resolve_provider() {
  if [ -n "$provider" ]; then
    printf '%s\n' "$provider"
    return 0
  fi

  if [ -n "${AI_PROVIDER:-}" ]; then
    printf '%s\n' "$AI_PROVIDER"
    return 0
  fi

  printf 'claude\n'
}

find_gemini_cmd() {
  if [ -n "${GEMINI_CMD:-}" ]; then
    printf '%s\n' "$GEMINI_CMD"
    return 0
  fi

  if command -v gemini >/dev/null 2>&1; then
    printf 'gemini\n'
    return 0
  fi

  if command -v gemini-cli >/dev/null 2>&1; then
    printf 'gemini-cli\n'
    return 0
  fi

  return 1
}

if [ "$dry_run" -eq 1 ]; then
  provider="$(resolve_provider)"
  append_log "[DRY-RUN] provider=$provider prompt=$prompt_file output=$output_file"
  echo "[DRY-RUN] $provider 실행 생략"
  exit 0
fi

provider="$(resolve_provider)"

case "$provider" in
  claude|codex|gemini) ;;
  *)
    echo "[오류] 지원하지 않는 provider 입니다: $provider" >&2
    exit 2
    ;;
esac

stdout_tmp="$(mktemp)"
stderr_tmp="$(mktemp)"
trap 'rm -f "$stdout_tmp" "$stderr_tmp"' EXIT

run_ok=0

run_claude_attempt() {
  local mode="$1"
  local shell_cmd=""

  case "$mode" in
    "print_no_mcp")
      shell_cmd="prompt_text=\$(cat '$prompt_abs'); claude -p --no-mcp \"\$prompt_text\""
      ;;
    "print")
      shell_cmd="prompt_text=\$(cat '$prompt_abs'); claude -p \"\$prompt_text\""
      ;;
    "legacy_print_no_mcp")
      shell_cmd="prompt_text=\$(cat '$prompt_abs'); claude --print --no-mcp \"\$prompt_text\""
      ;;
    "legacy_print")
      shell_cmd="prompt_text=\$(cat '$prompt_abs'); claude --print \"\$prompt_text\""
      ;;
    "plain_no_mcp")
      shell_cmd="prompt_text=\$(cat '$prompt_abs'); claude --no-mcp \"\$prompt_text\""
      ;;
    "plain")
      shell_cmd="prompt_text=\$(cat '$prompt_abs'); claude \"\$prompt_text\""
      ;;
    *)
      return 1
      ;;
  esac

  /bin/zsh -lic "export LANG=en_US.UTF-8; export LC_ALL=en_US.UTF-8; $shell_cmd" >"$stdout_tmp" 2>"$stderr_tmp"
}

run_gemini_attempt() {
  local mode="$1"
  local gemini_cmd="$2"
  local shell_cmd=""

  case "$mode" in
    "print")
      shell_cmd="prompt_text=\$(cat '$prompt_abs'); $gemini_cmd -p \"\$prompt_text\""
      ;;
    "prompt")
      shell_cmd="prompt_text=\$(cat '$prompt_abs'); $gemini_cmd --prompt \"\$prompt_text\""
      ;;
    "plain")
      shell_cmd="prompt_text=\$(cat '$prompt_abs'); $gemini_cmd \"\$prompt_text\""
      ;;
    *)
      return 1
      ;;
  esac

  /bin/zsh -lic "export LANG=en_US.UTF-8; export LC_ALL=en_US.UTF-8; $shell_cmd" >"$stdout_tmp" 2>"$stderr_tmp"
}

should_prompt_fallback() {
  local combined_output=""

  combined_output="$(
    {
      cat "$stdout_tmp"
      printf '\n'
      cat "$stderr_tmp"
    } 2>/dev/null
  )"

  case "$combined_output" in
    *"You've hit your limit"*|*"hit your limit"*|*"limit · resets"*|*"fallback"*|*"Not logged in"*|*"Please run /login"*|*"overloaded"*|*"quota"*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

run_codex_provider() {
  if [ ! -x "$run_codex_script" ]; then
    echo "[오류] codex 래퍼를 찾을 수 없거나 실행 권한이 없습니다: $run_codex_script" >&2
    exit 4
  fi

  "$run_codex_script" \
    --prompt-file "$prompt_abs" \
    --output-file "$output_file" \
    --repo-root "$repo_root_abs" \
    --log-file "$log_file"
}

run_copilot_attempt() {
  local mode="$1"
  local shell_cmd=""
  case "$mode" in
    "silent")
      shell_cmd="prompt_text=\$(cat '$prompt_abs'); copilot -p \"\$prompt_text\" -s"
      ;;
    "plain")
      shell_cmd="prompt_text=\$(cat '$prompt_abs'); copilot -p \"\$prompt_text\""
      ;;
    *)
      return 1
      ;;
  esac
  /bin/zsh -lic "export LANG=en_US.UTF-8; export LC_ALL=en_US.UTF-8; $shell_cmd" >"$stdout_tmp" 2>"$stderr_tmp"
}

run_gemini_provider() {
  local gemini_cmd=""
  gemini_cmd="$(find_gemini_cmd || true)"

  if [ -z "$gemini_cmd" ]; then
    echo "[오류] gemini CLI를 찾을 수 없습니다. GEMINI_CMD 환경변수 또는 gemini/gemini-cli 설치를 확인하세요." >&2
    exit 4
  fi

  if run_gemini_attempt "print" "$gemini_cmd"; then
    run_ok=1
    append_log "[정보] $gemini_cmd -p 방식 사용"
    return 0
  fi

  if run_gemini_attempt "prompt" "$gemini_cmd"; then
    run_ok=1
    append_log "[정보] $gemini_cmd --prompt 방식 사용"
    return 0
  fi

  if run_gemini_attempt "plain" "$gemini_cmd"; then
    run_ok=1
    append_log "[정보] $gemini_cmd <prompt> 방식 사용"
    return 0
  fi

  return 1
}

append_log "[시작] provider=$provider 작업 실행"
append_log "[입력] prompt=$prompt_file"

if [ "$provider" = "claude" ]; then
  if ! command -v claude >/dev/null 2>&1; then
    echo "[오류] claude CLI를 찾을 수 없습니다. 일반 터미널에서 설치/경로를 확인하세요." >&2
    exit 4
  fi

  if run_claude_attempt "print_no_mcp"; then
    run_ok=1
    append_log "[정보] claude -p --no-mcp 방식 사용"
  else
    if run_claude_attempt "print"; then
      run_ok=1
      append_log "[정보] claude -p 방식 사용"
    else
      if run_claude_attempt "legacy_print_no_mcp"; then
        run_ok=1
        append_log "[정보] claude --print --no-mcp 방식 사용"
      else
        if run_claude_attempt "legacy_print"; then
          run_ok=1
          append_log "[정보] claude --print 방식 사용"
        else
          if run_claude_attempt "plain_no_mcp"; then
            run_ok=1
            append_log "[정보] claude --no-mcp <prompt> 방식 사용"
          else
            if run_claude_attempt "plain"; then
              run_ok=1
              append_log "[정보] claude <prompt> 방식 사용"
            fi
          fi
        fi
      fi
    fi
  fi
fi

if [ "$provider" = "codex" ]; then
  if run_codex_provider; then
    append_log "[완료] provider=codex 작업 성공: output=$output_file"
    echo "[완료] Codex 작업 성공: $output_file"
    exit 0
  fi

  echo "[오류] Codex provider 실행에 실패했습니다." >&2
  exit 20
fi

if [ "$provider" = "gemini" ]; then
  run_gemini_provider || true
fi

if [ "$provider" = "copilot" ]; then
  if ! command -v copilot >/dev/null 2>&1; then
    echo "[오류] copilot CLI를 찾을 수 없습니다. 설치 후 다시 시도하세요." >&2
    exit 4
  fi

  if run_copilot_attempt "silent"; then
    run_ok=1
    append_log "[정보] copilot -p -s 방식 사용"
  elif run_copilot_attempt "plain"; then
    run_ok=1
    append_log "[정보] copilot -p 방식 사용"
  fi
fi

if [ "$run_ok" -ne 1 ]; then
  if [ "$provider" = "claude" ] && should_prompt_fallback; then
    append_log "[대기] Claude fallback 가능 상태 감지"
    echo "[FALLBACK_REQUIRED] claude" >&2
    exit 21
  fi

  if [ -n "$log_file" ]; then
    {
      echo "----- STDOUT -----"
      cat "$stdout_tmp"
      echo "----- STDERR -----"
      cat "$stderr_tmp"
      echo "------------------"
    } >> "$log_file"
  fi
  cat "$stdout_tmp" >&2 || true
  cat "$stderr_tmp" >&2 || true
  echo "[오류] $provider CLI 실행에 실패했습니다. 로그인 상태와 사용량 한도를 확인하세요." >&2
  exit 20
fi

cat "$stdout_tmp" > "$output_file"

if [ -n "$log_file" ]; then
  {
    echo "----- STDOUT -----"
    cat "$stdout_tmp"
    echo "----- STDERR -----"
    cat "$stderr_tmp"
    echo "------------------"
  } >> "$log_file"
fi

append_log "[완료] Claude 작업 성공: output=$output_file"
echo "[완료] $(provider_label "$provider") 작업 성공: $output_file"
