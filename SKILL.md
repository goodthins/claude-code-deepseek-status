---
name: deepseek-status
description: Real-time API balance/credits, model, and status display for Claude Code status line — supports DeepSeek (pay-per-use) and MiMo (Token Plan)
---

# AI Status Line Plugin (DeepSeek + MiMo)

Displays real-time API account info in Claude Code's status bar: current model, balance/credits, update time, and effort level — all color-coded. Auto-detects provider from model name.

## Supported Providers

| Provider | Billing Model | Display |
|----------|--------------|---------|
| **DeepSeek** | Pay-per-use (¥) | `mod:v4-pro  bal:¥17.38  syn@14:32  ef:HIGH` |
| **MiMo** | Token Plan (credits) | `mod:v2.5-pro  [██████░░░░]  syn@14:32  ef:HIGH` |

## Quick Install

```bash
mkdir -p ~/.claude/skills/deepseek-status
cp deepseek-status.sh ~/.claude/skills/deepseek-status/
chmod +x ~/.claude/skills/deepseek-status/deepseek-status.sh
```

---

## DeepSeek Configuration

Add to `~/.claude/settings.json`:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "sk-your-key",
    "ANTHROPIC_MODEL": "deepseek-v4-pro[1m]",
    "DEEPSEEK_API_KEY": "sk-your-key",
    "CLAUDE_CODE_EFFORT_LEVEL": "high"
  },
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/skills/deepseek-status/deepseek-status.sh"
  }
}
```

### DeepSeek Display

```
mod:v4-pro  bal:¥17.38  syn@14:32  ef:MAX
  ↑    ↑       ↑    ↑       ↑    ↑      ↑   ↑
label value  label value  label value  label value
(gray)(cyan) (gray)(green) (gray)(white) (gray)(magenta)
```

- `mod` = model · `bal` = balance · `syn@` = last sync · `ef` = effort factor
- Balance < ¥5 → value turns yellow as a warning
- API unavailable → value shows `?`

---

## MiMo Token Plan Configuration

Add to `~/.claude/settings.json`:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://token-plan-cn.xiaomimimo.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "tp-your-mimo-key",
    "ANTHROPIC_MODEL": "mimo-v2.5-pro",
    "MIMO_TOKEN_PLAN_TOTAL_CREDITS": "700000000",
    "CLAUDE_CODE_EFFORT_LEVEL": "high"
  },
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/skills/deepseek-status/deepseek-status.sh"
  }
}
```

Set `MIMO_TOKEN_PLAN_TOTAL_CREDITS` to your plan's credit quota:

| Plan | Credits | Config Value |
|------|---------|-------------|
| Lite | 60M | `60000000` |
| Standard | 200M | `200000000` |
| Pro | 700M | `700000000` |
| Max | 1.6B | `1600000000` |

MiMo has no public balance API. The script auto-tracks token consumption from Claude Code's local audit logs (`~/.claude/projects/*/*.jsonl`) and converts tokens to credits using the model-specific multiplier. A file-mtime cache avoids re-scanning on every refresh. Tracking is per-machine; usage from other computers is not reflected.

### Credit Multiplier

| Model | Multiplier |
|-------|-----------|
| MiMo-V2-Omni | 1x (1 Token = 1 Credit) |
| MiMo-V2.5-Pro | 2x (1 Token = 2 Credits) |
| MiMo-V2-Pro | 2x (1 Token = 2 Credits) |
| Others | 2x (default) |

Override with `MIMO_CREDIT_MULTIPLIER` env var if needed.

### MiMo Display

```
mod:v2.5-pro  [██████░░░░]  syn@14:32  ef:HIGH
   ↑             ↑             ↑         ↑
(cyan model) (rainbow bar)  (white time) (magenta effort)
```

- The progress bar replaces `bal:` — shows credits consumed vs. total plan quota
- 12-character Unicode block bar with full rainbow gradient
- Empty ░ chars in gray, filled █ chars cycle through 12 rainbow colors (Red → HotPink)
- `[?]` shown when `MIMO_TOKEN_PLAN_TOTAL_CREDITS` is not configured
- Auto-detects provider by model name prefix (`mimo-` vs `deepseek-`)

---

## Environment Variables

| Variable | Provider | Purpose | Default |
|----------|----------|---------|---------|
| `DEEPSEEK_API_KEY` | DeepSeek | API key for balance queries | — |
| `MIMO_TOKEN_PLAN_TOTAL_CREDITS` | MiMo | Token Plan total credit quota | — |
| `MIMO_CREDIT_MULTIPLIER` | MiMo | Token→Credit multiplier override | auto-detect |
| `DEEPSEEK_MODEL` | Both | Model name override | `$ANTHROPIC_MODEL` |
| `CLAUDE_CODE_EFFORT_LEVEL` | Both | Effort level (Claude Code official) | — |
| `CLAUDE_EFFORT` | Both | Legacy fallback | — |
| `NO_COLOR` | Both | Set to 1 to disable colors | — |

## CLI Arguments

```bash
./deepseek-status.sh [--api-key KEY] [--model NAME] [--effort LVL] [--total-credits N] [--no-color]
```

Arguments override environment variables.

## How It Works

1. Claude Code invokes the script periodically via the `statusLine` command
2. Script detects provider from model name prefix
3. **DeepSeek**: Calls `GET https://api.deepseek.com/user/balance` (2s/3s timeout) and parses `total_balance`
4. **MiMo**: Parses `~/.claude/projects/*/*.jsonl` audit logs (no public API exists), sums `input_tokens + output_tokens` for MiMo model calls, multiplies by credit rate, renders progress bar vs. total quota. Uses file-mtime cache for performance.
5. Outputs a single colorized line to stdout
