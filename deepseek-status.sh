#!/usr/bin/env bash
#==============================================================================
# deepseek-status.sh — Claude Code status line plugin (DeepSeek + MiMo)
#==============================================================================
# DeepSeek mode:  mod:v4-pro  bal:¥17.38  syn@14:32  ef:MAX
# MiMo TokenPlan: mod:v2.5-pro  [██████░░░░]  syn@14:32  ef:HIGH
#
# MiMo has NO public balance API. Credits are tracked by parsing Claude Code's
# own audit logs (~/.claude/projects/*/*.jsonl), which record every API call's
# model + token usage automatically. Tokens × model multiplier = credits used.
# This means tracking is per-machine and starts from first Claude Code usage.
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
# MiMo has no public balance/credits API. Instead, we parse Claude Code's local
# audit logs (~/.claude/projects/*/*.jsonl) — every API call is recorded there
# with model name + token usage. We sum all MiMo model tokens and convert to
# credits via the model-specific multiplier. A file-mtime cache avoids
# re-scanning all JSONL files on every status-line refresh (~30s interval).
compute_mimo_credits() {
  local audit_base="$HOME/.claude/projects"

  if [[ ! -d "$audit_base" ]]; then
    printf '0'
    return
  fi

  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/deepseek-status"
  local cache_file="$cache_dir/mimo-tokens.cache"

  # Use cache if no JSONL file is newer than the cache snapshot
  if [[ -f "$cache_file" ]]; then
    local newer_files
    newer_files=$(find "$audit_base" -name "*.jsonl" -newer "$cache_file" 2>/dev/null)
    if [[ $? -eq 0 ]] && [[ -z "$newer_files" ]]; then
      head -1 "$cache_file"
      return
    fi
  fi

  local total_tokens
  total_tokens=$(grep -rhE '"model"[[:space:]]*:[[:space:]]*"mimo-' "$audit_base" 2>/dev/null | \
    grep -oE '"input_tokens"[[:space:]]*:[[:space:]]*[0-9]+|"output_tokens"[[:space:]]*:[[:space:]]*[0-9]+' | \
    awk -F: '{s+=$2} END {printf "%.0f", s}')

  local result="${total_tokens:-0}"
  if mkdir -p "$cache_dir" 2>/dev/null; then
    printf '%s\n' "$result" > "$cache_file" 2>/dev/null || true
  fi
  printf '%s' "$result"
}

# ---- calibrated MiMo credits (with calibration file support) -----------------
# If a calibration file exists (~/.cache/deepseek-status/mimo-calibration.json),
# compute credits as: cal_credits_used + (delta_tokens * multiplier).
# Otherwise fall back to: total_tokens * multiplier (legacy behavior).
compute_mimo_credits_calibrated() {
  local cal_file="${XDG_CACHE_HOME:-$HOME/.cache}/deepseek-status/mimo-calibration.json"
  local current_tokens
  current_tokens=$(compute_mimo_credits)

  if [[ -f "$cal_file" ]]; then
    local cal_credits cal_tokens cal_mult
    cal_credits=$(sed -n 's/.*"credits_used_at_calibration":\s*\([0-9]*\).*/\1/p' "$cal_file" | head -1)
    cal_tokens=$(sed -n 's/.*"tokens_at_calibration":\s*\([0-9]*\).*/\1/p' "$cal_file" | head -1)
    cal_mult=$(sed -n 's/.*"multiplier":\s*\([0-9]*\).*/\1/p' "$cal_file" | head -1)

    if [[ -n "$cal_credits" ]] && [[ -n "$cal_tokens" ]] && [[ -n "$cal_mult" ]]; then
      local delta=$(( current_tokens - cal_tokens ))
      (( delta < 0 )) && delta=0
      local credits_used=$(( cal_credits + delta * cal_mult ))
      printf '%s' "$credits_used"
      return
    fi
  fi

  # Fallback: no calibration file — use legacy computation
  local mult
  mult=$(detect_credit_multiplier "$MODEL")
  printf '%s' "$(( current_tokens * mult ))"
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

  # Try reading total_credits from calibration file if env var is not set
  if [[ -z "$TOTAL_CREDITS" ]] || [[ "$TOTAL_CREDITS" -le 0 ]] 2>/dev/null; then
    _cal_file="${XDG_CACHE_HOME:-$HOME/.cache}/deepseek-status/mimo-calibration.json"
    if [[ -f "$_cal_file" ]]; then
      TOTAL_CREDITS=$(sed -n 's/.*"total_credits":\s*\([0-9]*\).*/\1/p' "$_cal_file" | head -1)
    fi
  fi

  if [[ -n "$TOTAL_CREDITS" ]] && [[ "$TOTAL_CREDITS" -gt 0 ]] 2>/dev/null; then
    CREDITS_USED=$(compute_mimo_credits_calibrated)

    # Reverse bar: full → empty as credits are consumed (fuel gauge style)
    REMAINING=$(( TOTAL_CREDITS - CREDITS_USED ))
    (( REMAINING < 0 )) && REMAINING=0
    FILLED=$(( REMAINING * 12 / TOTAL_CREDITS ))
    (( FILLED > 12 )) && FILLED=12

    # Low credits warning: < 10% remaining
    if (( REMAINING * 10 < TOTAL_CREDITS )); then
      if [[ "$NO_COLOR" != "1" ]]; then
        # Override rainbow with red warning bar
        bar=""
        for (( i=0; i<12; i++ )); do
          if [[ $i -lt $FILLED ]]; then
            bar+="\033[1;31m█"
          else
            bar+="\033[90m░"
          fi
        done
        BAR="\033[90m[\033[0m${bar}\033[90m]\033[0m"
      else
        BAR=$(render_rainbow_bar "$FILLED")
      fi
    else
      BAR=$(render_rainbow_bar "$FILLED")
    fi
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
