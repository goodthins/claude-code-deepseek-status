#!/usr/bin/env bash
#==============================================================================
# deepseek-status.sh — Claude Code status line plugin for DeepSeek
#==============================================================================
# Displays:  mod:v4-pro  bal:¥17.38  syn@14:32  ef:MAX
#
# ENVIRONMENT VARIABLES (all optional for default install):
#   DEEPSEEK_API_KEY  – DeepSeek API key                        [required]
#   DEEPSEEK_MODEL    – model name override                     [falls back to ANTHROPIC_MODEL]
#   CLAUDE_EFFORT     – effort level: max / high / medium / low [auto-detect]
#   NO_COLOR          – set to 1 to disable ANSI colors         [off]
#
# USAGE:
#   ./deepseek-status.sh [--api-key KEY] [--model NAME] [--effort LVL] [--no-color]
#
# INSTALL (in Claude Code settings.json):
#   "env": {
#     "DEEPSEEK_API_KEY": "sk-your-key-here",
#     "CLAUDE_EFFORT": "max"
#   },
#   "statusLine": {
#     "type": "command",
#     "command": "bash ~/.claude/skills/deepseek-status/deepseek-status.sh"
#   }
#==============================================================================

set -o pipefail

# ---- args -------------------------------------------------------------------
API_KEY="${DEEPSEEK_API_KEY:-}"
MODEL="${DEEPSEEK_MODEL:-${ANTHROPIC_MODEL:-}}"
EFFORT="${CLAUDE_EFFORT:-}"
NO_COLOR="${NO_COLOR:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-key) API_KEY="$2"; shift 2 ;;
    --model)   MODEL="$2";   shift 2 ;;
    --effort)  EFFORT="$2";  shift 2 ;;
    --no-color) NO_COLOR=1;  shift ;;
    *) shift ;;
  esac
done

# ---- ANSI colors ------------------------------------------------------------
if [[ "$NO_COLOR" == "1" ]]; then
  CLR_M=''; CLR_B=''; CLR_T=''; CLR_E=''; CLR_S=''; RST=''
else
  CLR_M='\033[1;36m'   # model:   bold cyan
  CLR_B='\033[1;32m'   # balance: bold green (rich) / yellow (low)
  CLR_T='\033[0;37m'   # time:    white
  CLR_E='\033[1;35m'   # effort:  bold magenta
  CLR_S='\033[0;90m'   # sep:     gray
  RST='\033[0m'
fi

# ---- model ------------------------------------------------------------------
shorten_model() {
  local m="${1:-}"
  m="${m#deepseek-}"          # deepseek-v4-pro[1m] → v4-pro[1m]
  m="${m%%[*}"                # strip [...] suffix
  printf '%s' "${m:-?}"
}

MODEL_DISPLAY=$(shorten_model "$MODEL")

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

# ---- time -------------------------------------------------------------------
UPDATE_TIME=$(date '+%H:%M')

# ---- effort -----------------------------------------------------------------
effort_icon() {
  case "${1,,}" in
    max)    printf 'MAX'   ;;
    high)   printf 'HIGH'  ;;
    medium) printf 'MED'   ;;
    low)    printf 'LOW'   ;;
    *)      printf '%s' "${1:-?}" ;;
  esac
}

EFFORT_DISPLAY=$(effort_icon "$EFFORT")

# ---- color logic ------------------------------------------------------------
# warn when balance < 5 CNY
BALANCE_NUM=$(printf '%s' "$BALANCE" | sed 's/[^0-9.]//g')
if [[ -z "$BALANCE" ]]; then
  BALANCE_COLOR="$CLR_M"   # use model color for unknown
  BALANCE_TEXT="?"
elif [[ -n "$BALANCE_NUM" ]] && awk "BEGIN {exit !($BALANCE_NUM < 5)}" 2>/dev/null; then
  BALANCE_COLOR='\033[1;33m'  # bold yellow warning
  BALANCE_TEXT="¥${BALANCE}"
else
  BALANCE_COLOR="$CLR_B"
  BALANCE_TEXT="¥${BALANCE}"
fi
[[ "$NO_COLOR" == "1" ]] && BALANCE_COLOR=''

# ---- output:  mod:v4-pro  bal:¥17.13  syn@10:35  ef:MAX ------------------
# label=gray  value=colored  pairs separated by double space
printf "%bmod:%b%b%s%b  %bbal:%b%b%s%b  %bsyn@%b%b%s%b  %bef:%b%b%s%b\n" \
  "$CLR_S" "$RST" "$CLR_M"         "$MODEL_DISPLAY"  "$RST" \
  "$CLR_S" "$RST" "$BALANCE_COLOR" "$BALANCE_TEXT"   "$RST" \
  "$CLR_S" "$RST" "$CLR_T"         "$UPDATE_TIME"    "$RST" \
  "$CLR_S" "$RST" "$CLR_E"         "$EFFORT_DISPLAY" "$RST"
