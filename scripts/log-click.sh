#!/usr/bin/env bash
# Atomic append a click event to data/click-logs/<platform>-<YYYY-MM>.jsonl
#
# Usage:
#   bash scripts/log-click.sh \
#     --platform facebook \
#     --draft-id 20260501-152300 \
#     --run-id r-a3f9 \
#     --step 2_click_create_post \
#     --method role_name \
#     --args '{"role":"button","name":"建立貼文"}' \
#     --url "https://www.facebook.com/yichao.shih" \
#     --ok true \
#     --ms 3440 \
#     [--error "timeout waiting for button"]
#
# Notes:
#   - Output dir/file auto-created.
#   - flock-protected against parallel writers (5 platforms publishing in parallel).
#   - --args MUST be valid compact JSON (no newlines).
#   - Schema fields: ts, platform, draft_id, run_id, step, method, args, url, ok, ms, [error]
set -euo pipefail

platform=""
draft_id=""
run_id=""
step=""
method=""
args="{}"
url=""
ok=""
ms="0"
error=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)  platform="$2"; shift 2 ;;
    --draft-id)  draft_id="$2"; shift 2 ;;
    --run-id)    run_id="$2"; shift 2 ;;
    --step)      step="$2"; shift 2 ;;
    --method)    method="$2"; shift 2 ;;
    --args)      args="$2"; shift 2 ;;
    --url)       url="$2"; shift 2 ;;
    --ok)        ok="$2"; shift 2 ;;
    --ms)        ms="$2"; shift 2 ;;
    --error)     error="$2"; shift 2 ;;
    *)           echo "log-click: unknown flag $1" >&2; exit 2 ;;
  esac
done

for required in platform draft_id run_id step method url ok; do
  if [[ -z "${!required}" ]]; then
    echo "log-click: missing --${required//_/-}" >&2
    exit 2
  fi
done

case "$ok" in
  true|false) ;;
  *) echo "log-click: --ok must be true|false (got '$ok')" >&2; exit 2 ;;
esac

if ! command -v jq >/dev/null 2>&1; then
  echo "log-click: jq is required" >&2
  exit 2
fi

month=$(date -u +%Y-%m)
dir="data/click-logs"
file="${dir}/${platform}-${month}.jsonl"
mkdir -p "$dir"

# Millisecond UTC timestamp. macOS `date` doesn't support %3N reliably, so use python.
ts=$(python3 -c 'from datetime import datetime,timezone
n=datetime.now(timezone.utc)
print(n.strftime("%Y-%m-%dT%H:%M:%S.")+f"{n.microsecond//1000:03d}Z")')

if [[ -n "$error" ]]; then
  line=$(jq -nc \
    --arg ts "$ts" --arg p "$platform" --arg d "$draft_id" --arg r "$run_id" \
    --arg s "$step" --arg m "$method" --argjson a "$args" --arg u "$url" \
    --argjson ok "$ok" --argjson ms "$ms" --arg e "$error" \
    '{ts:$ts,platform:$p,draft_id:$d,run_id:$r,step:$s,method:$m,args:$a,url:$u,ok:$ok,ms:$ms,error:$e}')
else
  line=$(jq -nc \
    --arg ts "$ts" --arg p "$platform" --arg d "$draft_id" --arg r "$run_id" \
    --arg s "$step" --arg m "$method" --argjson a "$args" --arg u "$url" \
    --argjson ok "$ok" --argjson ms "$ms" \
    '{ts:$ts,platform:$p,draft_id:$d,run_id:$r,step:$s,method:$m,args:$a,url:$u,ok:$ok,ms:$ms}')
fi

# POSIX append (`>>`) for writes < PIPE_BUF (typ. 4KB) is atomic at the kernel level —
# each line is well under that, so 5 parallel publish-* writers won't interleave bytes
# even when writing the same file. No flock needed.
echo "$line" >> "$file"
