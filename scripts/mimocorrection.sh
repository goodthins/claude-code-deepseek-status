#!/usr/bin/env bash
# Write MiMo Token Plan calibration data for deepseek-status.sh.

set -o pipefail

usage() {
  printf 'Usage: %s USED_CREDITS / TOTAL_CREDITS\n' "${0##*/}" >&2
  printf 'Example: %s 20,720,328 / 700,000,000\n' "${0##*/}" >&2
}

num_only() {
  printf '%s' "${1:-}" | sed 's/[^0-9]//g'
}

detect_credit_multiplier() {
  local model="${1:-}"
  local override="${MIMO_CREDIT_MULTIPLIER:-}"
  if [[ -n "$override" ]]; then
    printf '%s' "$override"
    return
  fi
  case "$model" in
    *omni*)   printf '1' ;;
    *v2.5*)   printf '2' ;;
    *v2-pro*) printf '2' ;;
    *)        printf '2' ;;
  esac
}

compute_mimo_tokens() {
  local audit_base="$HOME/.claude/projects"
  if [[ ! -d "$audit_base" ]]; then
    printf '0'
    return
  fi

  grep -rhE '"model"[[:space:]]*:[[:space:]]*"mimo-' "$audit_base" 2>/dev/null | \
    grep -oE '"input_tokens"[[:space:]]*:[[:space:]]*[0-9]+|"output_tokens"[[:space:]]*:[[:space:]]*[0-9]+' | \
    awk -F: '{s+=$2} END {printf "%.0f", s}'
}

if [[ $# -lt 2 ]]; then
  usage
  exit 2
fi

USED=$(num_only "$1")
if [[ "${2:-}" == "/" ]]; then
  TOTAL=$(num_only "${3:-}")
else
  TOTAL=$(num_only "$2")
fi

if [[ -z "$USED" ]] || [[ -z "$TOTAL" ]] || [[ "$TOTAL" -le 0 ]] 2>/dev/null; then
  usage
  exit 2
fi

MODEL="${DEEPSEEK_MODEL:-${ANTHROPIC_MODEL:-mimo-v2.5-pro}}"
MULTIPLIER=$(detect_credit_multiplier "$MODEL")
TOKENS=$(compute_mimo_tokens)
TOKENS="${TOKENS:-0}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/deepseek-status"
CAL_FILE="$CACHE_DIR/mimo-calibration.json"

if ! mkdir -p "$CACHE_DIR" 2>/dev/null; then
  printf 'mimocorrection: cannot create cache directory: %s\n' "$CACHE_DIR" >&2
  exit 1
fi

cat > "$CAL_FILE" <<EOF
{
  "credits_used_at_calibration": $USED,
  "total_credits": $TOTAL,
  "tokens_at_calibration": $TOKENS,
  "multiplier": $MULTIPLIER,
  "model": "$MODEL",
  "created_at": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}
EOF

printf 'MiMo calibration saved: used=%s total=%s tokens=%s multiplier=%s\n' \
  "$USED" "$TOTAL" "$TOKENS" "$MULTIPLIER"
