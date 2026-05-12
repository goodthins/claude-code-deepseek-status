#!/usr/bin/env bash
#==============================================================================
# deepseek-status.sh — Claude Code status line plugin for DeepSeek
#==============================================================================
# Display:
#   mod:v4-pro  bal:¥17.38  syn@14:32  ef:HIGH
#
# ENVIRONMENT VARIABLES:
#   DEEPSEEK_API_KEY          DeepSeek API key for balance queries
#   DEEPSEEK_MODEL            model name override
#   ANTHROPIC_MODEL           model name from Claude Code settings
#   CLAUDE_CODE_EFFORT_LEVEL  effort: xhigh/high/medium/low
#   CLAUDE_EFFORT             fallback effort var (legacy)
#   NO_COLOR                  set to 1 to disable ANSI colors
#
# USAGE:
#   ./deepseek-status.sh [--api-key KEY] [--model NAME] [--effort LVL] [--no-color]
#==============================================================================

set -o pipefail

# ---- statusLine input -------------------------------------------------------
# Claude Code sends status-line context as JSON on stdin. Environment variables
# remain supported for manual testing and older setups.
STDIN_JSON=""
if [[ ! -t 0 ]]; then
  STDIN_JSON=$(cat 2>/dev/null || true)
fi

json_string_value() {
  local key="${1:-}"
  local json="${2:-}"
  [[ -z "$key" ]] && return
  printf '%s' "$json" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
}

json_model_value() {
  local json="${1:-}"
  local v=""
  v=$(json_string_value "id" "$json")
  [[ -z "$v" ]] && v=$(json_string_value "display_name" "$json")
  [[ -z "$v" ]] && v=$(json_string_value "name" "$json")
  printf '%s' "$v"
}

json_effort_value() {
  local json="${1:-}"
  local v=""
  v=$(json_string_value "level" "$json")
  [[ -z "$v" ]] && v=$(json_string_value "effort" "$json")
  printf '%s' "$v"
}

# ---- args -------------------------------------------------------------------
API_KEY="${DEEPSEEK_API_KEY:-}"
MODEL="${DEEPSEEK_MODEL:-${ANTHROPIC_MODEL:-$(json_model_value "$STDIN_JSON")}}"
EFFORT="${CLAUDE_CODE_EFFORT_LEVEL:-${CLAUDE_EFFORT:-$(json_effort_value "$STDIN_JSON")}}"
NO_COLOR="${NO_COLOR:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-key)  API_KEY="${2:-}"; shift 2 ;;
    --model)    MODEL="${2:-}";   shift 2 ;;
    --effort)   EFFORT="${2:-}";  shift 2 ;;
    --no-color) NO_COLOR=1;       shift   ;;
    *) shift ;;
  esac
done

# ---- ANSI colors ------------------------------------------------------------
if [[ "$NO_COLOR" == "1" ]]; then
  CLR_M=''; CLR_B=''; CLR_T=''; CLR_E=''; CLR_S=''; RST=''
else
  CLR_M='\033[1;36m'   # model:   bold cyan
  CLR_B='\033[1;32m'   # balance: bold green / yellow when low
  CLR_T='\033[0;37m'   # time:    white
  CLR_E='\033[1;35m'   # effort:  bold magenta
  CLR_S='\033[0;90m'   # labels:  gray
  RST='\033[0m'
fi

shorten_model() {
  local m="${1:-}"
  m="${m#deepseek-}"
  m="${m%%[*}"
  printf '%s' "${m:-?}"
}

effort_icon() {
  case "${1,,}" in
    max)    printf 'MAX'  ;;
    xhigh)  printf 'XHIGH' ;;
    high)   printf 'HIGH' ;;
    medium) printf 'MED'  ;;
    low)    printf 'LOW'  ;;
    *)      printf '%s' "${1:-?}" ;;
  esac
}

MODEL_DISPLAY=$(shorten_model "$MODEL")
EFFORT_DISPLAY=$(effort_icon "$EFFORT")
UPDATE_TIME=$(date '+%H:%M')

# ---- balance ----------------------------------------------------------------
BALANCE=""
if [[ -n "$API_KEY" ]]; then
  RAW=$(curl -s --connect-timeout 2 --max-time 3 \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    "https://api.deepseek.com/user/balance" 2>/dev/null)

  if [[ -n "$RAW" ]]; then
    BALANCE=$(printf '%s' "$RAW" | \
      sed -n 's/.*"total_balance"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  fi
fi

BALANCE_NUM=$(printf '%s' "$BALANCE" | sed 's/[^0-9.]//g')
if [[ -z "$BALANCE" ]]; then
  BALANCE_COLOR="$CLR_M"
  BALANCE_TEXT="?"
elif [[ -n "$BALANCE_NUM" ]] && awk "BEGIN {exit !($BALANCE_NUM < 5)}" 2>/dev/null; then
  BALANCE_COLOR='\033[1;33m'
  BALANCE_TEXT="¥${BALANCE}"
else
  BALANCE_COLOR="$CLR_B"
  BALANCE_TEXT="¥${BALANCE}"
fi
[[ "$NO_COLOR" == "1" ]] && BALANCE_COLOR=''

printf "%bmod:%b%b%s%b  %bbal:%b%b%s%b  %bsyn@%b%b%s%b  %bef:%b%b%s%b\n" \
  "$CLR_S" "$RST" "$CLR_M"         "$MODEL_DISPLAY"  "$RST" \
  "$CLR_S" "$RST" "$BALANCE_COLOR" "$BALANCE_TEXT"   "$RST" \
  "$CLR_S" "$RST" "$CLR_T"         "$UPDATE_TIME"    "$RST" \
  "$CLR_S" "$RST" "$CLR_E"         "$EFFORT_DISPLAY" "$RST"
