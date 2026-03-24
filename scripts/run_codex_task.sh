#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
사용법:
  ai/scripts/run_codex_task.sh \
    --prompt-file <프롬프트 파일> \
    --output-file <출력 파일> \
    [--timeout-sec <초>] \
    [--repo-root <저장소 루트>] \
    [--log-file <로그 파일>] \
    [--dry-run]

설명:
  - Codex CLI 비대화식 실행 래퍼입니다.
  - 저장소 외부 파일 출력은 차단합니다.

종료 코드:
  0  성공
  2  인자 오류
  3  입력 파일 오류
  4  codex CLI 미설치
  5  경로 안전성 위반
USAGE
}

prompt_file=""
output_file=""
repo_root="$(pwd)"
log_file=""
dry_run=0
timeout_sec="600"

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
    --repo-root)
      repo_root="$2"
      shift 2
      ;;
    --timeout-sec)
      timeout_sec="$2"
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

case "$timeout_sec" in
  ''|*[!0-9]*)
    echo "[오류] --timeout-sec는 0 이상의 정수여야 합니다: $timeout_sec" >&2
    exit 2
    ;;
esac

abs_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s/%s\n' "$(pwd)" "$1" ;;
  esac
}

repo_root_abs="$(cd "$repo_root" && pwd -P)"
prompt_abs="$(abs_path "$prompt_file")"
output_abs="$(abs_path "$output_file")"

mkdir -p "$(dirname "$output_abs")"
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

if [ "$dry_run" -eq 1 ]; then
  append_log "[DRY-RUN] Codex 실행 생략: prompt=$prompt_abs output=$output_abs"
  echo "[DRY-RUN] Codex 실행 생략"
  exit 0
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "[오류] codex CLI를 찾을 수 없습니다." >&2
  exit 4
fi

stdout_tmp="$(mktemp)"
stderr_tmp="$(mktemp)"
trap 'rm -f "$stdout_tmp" "$stderr_tmp"' EXIT

append_log "[시작] Codex 작업 실행"
append_log "[입력] prompt=$prompt_abs"
append_log "[입력] auto-consent=enabled"
append_log "[설정] timeout_sec=$timeout_sec"
append_log "[출력] result=$output_abs"

if [ "$timeout_sec" -eq 0 ]; then
  codex_shell_cmd="cat '$prompt_abs' | codex exec --cd '$repo_root_abs' --full-auto --skip-git-repo-check --output-last-message '$output_abs' -"
else
  codex_shell_cmd="cat '$prompt_abs' | perl -e 'alarm shift; exec @ARGV' '$timeout_sec' codex exec --cd '$repo_root_abs' --full-auto --skip-git-repo-check --output-last-message '$output_abs' -"
fi

if /bin/zsh -lic "export LANG=en_US.UTF-8; export LC_ALL=en_US.UTF-8; $codex_shell_cmd" >"$stdout_tmp" 2>"$stderr_tmp"; then
  append_log "[완료] Codex 작업 성공"
else
  rc="$?"
  if [ "$rc" -eq 142 ]; then
    append_log "[실패] Codex 타임아웃 발생 (timeout_sec=$timeout_sec)"
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
  cat "$stderr_tmp" >&2 || true
  echo "[오류] Codex 작업 실행에 실패했습니다." >&2
  exit "$rc"
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

echo "[완료] Codex 작업 성공: $output_abs"
