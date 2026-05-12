---
name: deepseek-status
description: Real-time DeepSeek balance, model, and status display for Claude Code status line
---

# DeepSeek Status Line Plugin

Displays DeepSeek account info in Claude Code's status bar: current model, balance, update time, and effort level.

## Supported Provider

| Provider | Billing Model | Display |
|----------|---------------|---------|
| **DeepSeek** | Pay-per-use (¥) | `mod:v4-pro  bal:¥17.38  syn@14:32  ef:HIGH` |

## Fresh Machine Setup

```bash
claude plugin marketplace add goodthins/claude-code-deepseek-status
claude plugin install deepseek-status@goodthins-claude-plugins

mkdir -p ~/.claude/skills/deepseek-status
curl -L -o ~/.claude/skills/deepseek-status/deepseek-status.sh \
  https://raw.githubusercontent.com/goodthins/claude-code-deepseek-status/main/deepseek-status.sh
chmod +x ~/.claude/skills/deepseek-status/deepseek-status.sh
```

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

Restart Claude Code after editing settings.

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `DEEPSEEK_API_KEY` | API key for DeepSeek balance queries |
| `DEEPSEEK_MODEL` | Optional model name override |
| `ANTHROPIC_MODEL` | Model name from Claude Code settings |
| `CLAUDE_CODE_EFFORT_LEVEL` | Effort level |
| `CLAUDE_EFFORT` | Legacy effort fallback |
| `NO_COLOR` | Set to `1` to disable colors |

## CLI Arguments

```bash
./deepseek-status.sh [--api-key KEY] [--model NAME] [--effort LVL] [--no-color]
```

## How It Works

1. Claude Code invokes the script via `statusLine.command`
2. The script reads status-line JSON from stdin, with environment variables as fallback
3. It calls `GET https://api.deepseek.com/user/balance`
4. It prints one colorized status line
