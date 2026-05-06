#!/usr/bin/env bash
#==============================================================================
# deepseek-status.sh — Claude Code status line plugin (DeepSeek + MiMo)
#==============================================================================
# DeepSeek mode:  mod:v4-pro  bal:¥17.38  syn@14:32  ef:MAX
# MiMo TokenPlan: mod:v2.5-pro  [██████░░░░]  syn@14:32  ef:HIGH
#
# ENVIRONMENT VARIABLES:
#   DEEPSEEK_API_KEY               – DeepSeek API key                    [DeepSeek]
#   MIMO_TOKEN_PLAN_TOTAL_CREDITS  – Token Plan total credits            [MiMo]
#   MIMO_CREDIT_MULTIPLIER         – Token→Credit multiplier             [MiMo; auto]
#   DEEPSEEK_MODEL                 – model name override                 [optional]
#   CLAUDE_CODE_EFFORT_LEVEL       – effort: xhigh/high/medium/low       [optional]
#   CLAUDE_EFFORT                  – fallback effort var (legacy)        [optional]
#   NO_COLOR                       – set to 1 to disable ANSI colors     [optional]
#
# USAGE:
#   ./deepseek-status.sh [--api-key KEY] [--model NAME] [--effort LVL]
#                        [--total-credits N] [--no-color]
#==============================================================================

set -o pipefail

# ---- args -------------------------------------------------------------------
API_KEY="${DEEPSEEK_API_KEY:-}"
MODEL="${DEEPSEEK_MODEL:-${ANTHROPIC_MODEL:-}}"
EFFORT="${CLAUDE_CODE_EFFORT_LEVEL:-${CLAUDE_EFFORT:-}}"
NO_COLOR="${NO_COLOR:-}"
TOTAL_CREDITS="${MIMO_TOKEN_PLAN_TOTAL_CREDITS:-}"
CREDIT_MULTIPLIER="${MIMO_CREDIT_MULTIPLIER:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-key)       API_KEY="$2";          shift 2 ;;
    --model)         MODEL="$2";            shift 2 ;;
    --effort)        EFFORT="$2";           shift 2 ;;
    --total-credits) TOTAL_CREDITS="$2";    shift 2 ;;
    --no-color)      NO_COLOR=1;            shift   ;;
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

# ---- provider detection -----------------------------------------------------
detect_provider() {
  case "${1:-}" in
    mimo-*)   printf 'mimo'    ;;
    deepseek-*) printf 'deepseek' ;;
    *)        printf 'deepseek' ;;   # default to deepseek for unknown
  esac
}

PROVIDER=$(detect_provider "$MODEL")

# ---- model ------------------------------------------------------------------
shorten_model() {
  local m="${1:-}"
  m="${m#deepseek-}"
  m="${m#mimo-}"
  m="${m%%[*}"
  printf '%s' "${m:-?}"
}

MODEL_DISPLAY=$(shorten_model "$MODEL")

# ---- credit multiplier (MiMo) -----------------------------------------------
detect_credit_multiplier() {
  if [[ -n "$CREDIT_MULTIPLIER" ]]; then
    printf '%s' "$CREDIT_MULTIPLIER"
    return
  fi
  case "${1:-}" in
    *omni*)   printf '1' ;;   # MiMo-V2-Omni: 1 Token = 1 Credit
    *v2.5*)   printf '2' ;;   # MiMo-V2.5-Pro: 1 Token = 2 Credits
    *v2-pro*) printf '2' ;;   # MiMo-V2-Pro:   1 Token = 2 Credits (legacy)
    *)        printf '2' ;;   # default 2x
  esac
}

# ---- compute MiMo credits from audit logs -----------------------------------
compute_mimo_credits() {
  local audit_base="$HOME/.claude/projects"

  if [[ ! -d "$audit_base" ]]; then
    printf '0'
    return
  fi

  local total_tokens
  total_tokens=$(grep -rh '"model":"mimo-' "$audit_base" 2>/dev/null | \
    grep -oE '"input_tokens":[0-9]+|"output_tokens":[0-9]+' | \
    awk -F: '{s+=$2} END {printf "%.0f", s}')

  printf '%s' "${total_tokens:-0}"
}

# ---- rainbow progress bar ---------------------------------------------------
# $1 = number of filled chars (0-12)
render_rainbow_bar() {
  local filled="${1:-0}"
  local width=12

  (( filled < 0 ))   && filled=0
  (( filled > width )) && filled=$width

  local rainbow=(196 202 208 220 226 46 49 51 33 93 129 201)

  local bar=""
  local i
  for (( i=0; i<width; i++ )); do
    if [[ $i -lt $filled ]]; then
      if [[ "$NO_COLOR" == "1" ]]; then
        bar+='▓'
      else
        bar+="$(printf '\033[38;5;%dm█' "${rainbow[$i]}")"
      fi
    else
      if [[ "$NO_COLOR" == "1" ]]; then
        bar+='░'
      else
        bar+='\033[90m░'
      fi
    fi
  done

  # wrap in gray brackets
  if [[ "$NO_COLOR" == "1" ]]; then
    printf '[%s]' "$bar"
  else
    printf '\033[90m[\033[0m%b\033[90m]\033[0m' "$bar"
  fi
}

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

# ---- time -------------------------------------------------------------------
UPDATE_TIME=$(date '+%H:%M')

# ══════════════════════════════════════════════════════════════════════════════
# DEEPSEEK PATH
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$PROVIDER" == "deepseek" ]]; then

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

# ══════════════════════════════════════════════════════════════════════════════
# MIMO PATH
# ══════════════════════════════════════════════════════════════════════════════
else

  BAR=""

  if [[ -n "$TOTAL_CREDITS" ]] && [[ "$TOTAL_CREDITS" -gt 0 ]] 2>/dev/null; then
    TOKENS_USED=$(compute_mimo_credits)
    MULT=$(detect_credit_multiplier "$MODEL")
    CREDITS_USED=$(( TOKENS_USED * MULT ))

    # filled = credits_used * width / total_credits  (avoids integer truncation)
    FILLED=0
    if [[ "$CREDITS_USED" -gt 0 ]] 2>/dev/null; then
      FILLED=$(( CREDITS_USED * 12 / TOTAL_CREDITS ))
      (( FILLED > 12 )) && FILLED=12
    fi

    BAR=$(render_rainbow_bar "$FILLED")
  else
    # No Token Plan config — show placeholder
    if [[ "$NO_COLOR" == "1" ]]; then
      BAR="[?]"
    else
      BAR="$(printf '\033[90m[?]\033[0m')"
    fi
  fi

  printf "%bmod:%b%b%s%b  %s%b  %bsyn@%b%b%s%b  %bef:%b%b%s%b\n" \
    "$CLR_S" "$RST" "$CLR_M"  "$MODEL_DISPLAY" "$RST" \
             "$BAR"            "$RST" \
    "$CLR_S" "$RST" "$CLR_T"  "$UPDATE_TIME"    "$RST" \
    "$CLR_S" "$RST" "$CLR_E"  "$EFFORT_DISPLAY" "$RST"

fi
