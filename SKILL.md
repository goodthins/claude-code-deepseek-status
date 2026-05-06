---
name: deepseek-status
description: Real-time DeepSeek API balance, model, and status display for Claude Code status line
---

# DeepSeek Status Line Plugin

Displays real-time DeepSeek account info in Claude Code's status bar: current model, balance, update time, and effort level — all color-coded.

## Quick Install

```bash
# 1. Clone or download the script
mkdir -p ~/.claude/skills/deepseek-status
cp deepseek-status.sh ~/.claude/skills/deepseek-status/
chmod +x ~/.claude/skills/deepseek-status/deepseek-status.sh
```

## Configuration

Add to `~/.claude/settings.json`:

```json
{
  "env": {
    "DEEPSEEK_API_KEY": "sk-your-key-here",
    "CLAUDE_EFFORT": "max"
  },
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/skills/deepseek-status/deepseek-status.sh"
  }
}
```

Replace the `CLAUDE_EFFORT` value with your actual effort level (max, high, medium, low).

## Usage

Once installed, the status line will display automatically. You can also run it manually:

```bash
DEEPSEEK_API_KEY=sk-xxx ANTHROPIC_MODEL=deepseek-v4-pro bash ~/.claude/skills/deepseek-status/deepseek-status.sh
```

## Display

```
mod:v4-pro  bal:¥17.38  syn@14:32  ef:MAX
  ↑    ↑       ↑    ↑       ↑    ↑      ↑   ↑
label value  label value  label value  label value
(gray)(cyan) (gray)(green) (gray)(white) (gray)(magenta)
```

- `mod` = model · `bal` = balance · `syn@` = last sync · `ef` = effort factor
- Balance < ¥5 → value turns yellow as a warning
- API unavailable → value shows `?`

## Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `DEEPSEEK_API_KEY` | DeepSeek API key (required) | — |
| `DEEPSEEK_MODEL` | Model name override | `$ANTHROPIC_MODEL` |
| `CLAUDE_EFFORT` | Effort level display | — |
| `NO_COLOR` | Set to 1 to disable colors | — |
