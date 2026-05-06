# Claude Code DeepSeek Status Line

Real-time DeepSeek API status line plugin for [Claude Code](https://claude.ai/code). Displays your current model, account balance, sync time, and effort level — right in the status bar.

```
mod:v4-pro  bal:¥17.38  syn@14:32  ef:MAX
```

## Features

- **mod** — Current model, auto-detected from environment (`deepseek-v4-pro[1m]` → `v4-pro`)
- **bal** — Real-time account balance (CNY) via DeepSeek `/user/balance` API
- **syn@** — Last refresh timestamp (HH:MM)
- **ef** — Claude Code effort level (MAX / HIGH / MED / LOW)
- **Color-coded** — Balance turns yellow when < ¥5 as low-balance warning
- **Graceful fallback** — Shows `?` on network failure, never crashes
- **Zero dependencies** — Only `curl`, `sed`, `awk`, `printf` (all POSIX standard)

## Quick Start

### 1. Install the script

```bash
mkdir -p ~/.claude/skills/deepseek-status
curl -o ~/.claude/skills/deepseek-status/deepseek-status.sh \
  https://raw.githubusercontent.com/goodthins/claude-code-deepseek-status/main/deepseek-status.sh
chmod +x ~/.claude/skills/deepseek-status/deepseek-status.sh
```

### 2. Configure Claude Code

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

### 3. Restart Claude Code

The status line appears at the bottom of the window automatically.

## Manual Test

```bash
export DEEPSEEK_API_KEY=sk-xxx
export ANTHROPIC_MODEL=deepseek-v4-pro
export CLAUDE_EFFORT=max
bash ~/.claude/skills/deepseek-status/deepseek-status.sh
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DEEPSEEK_API_KEY` | Yes | Your DeepSeek API key from [platform.deepseek.com](https://platform.deepseek.com/api_keys) |
| `DEEPSEEK_MODEL` | No | Override model name. Falls back to `ANTHROPIC_MODEL` |
| `ANTHROPIC_MODEL` | No | Model name auto-set by Claude Code when using DeepSeek Anthropic endpoint |
| `CLAUDE_EFFORT` | No | Effort level: `max`, `high`, `medium`, `low` |
| `NO_COLOR` | No | Set to `1` to disable ANSI colors |

## CLI Arguments

```bash
./deepseek-status.sh [--api-key KEY] [--model NAME] [--effort LVL] [--no-color]
```

Arguments override environment variables.

## Color Scheme

| Element | Color | ANSI |
|---------|-------|------|
| Labels (`mod:` `bal:` `syn@` `ef:`) | Gray | `\033[0;90m` |
| Model value | Bold Cyan | `\033[1;36m` |
| Balance value (normal) | Bold Green | `\033[1;32m` |
| Balance value (< ¥5) | Bold Yellow | `\033[1;33m` |
| Time value | White | `\033[0;37m` |
| Effort value | Bold Magenta | `\033[1;35m` |

## How It Works

1. Claude Code invokes the script periodically via the `statusLine` command
2. Script calls `GET https://api.deepseek.com/user/balance` (2s connect / 3s total timeout)
3. Parses `total_balance` from the JSON response
4. Outputs a single colorized line to stdout

The balance API call is free and does not consume tokens.

## FAQ

**Q: Does this work on Windows?**
A: Yes — requires Git Bash (included with Git for Windows). The `bash` command must be in your PATH.

**Q: What if I use DeepSeek natively (not via the Anthropic-compatible endpoint)?**
A: Set `DEEPSEEK_MODEL=deepseek-chat` (or your model name) in the `env` block.

**Q: Why does it show `?` sometimes?**
A: Network timeout or API auth issue. The next refresh retries automatically.

**Q: Can I use this with other API providers?**
A: Currently DeepSeek-only. PRs welcome for OpenAI, Anthropic, etc.

## License

MIT — see [LICENSE](LICENSE).

---

# 中文说明

## Claude Code DeepSeek 状态栏插件

实时显示 DeepSeek API 账户信息：当前模型、余额、同步时间、努力级别。

```
mod:v4-pro  bal:¥17.38  syn@14:32  ef:MAX
```

## 功能

- **mod** — 当前使用的模型，自动从环境变量获取（`deepseek-v4-pro[1m]` 简化为 `v4-pro`）
- **bal** — 实时余额（人民币），通过 DeepSeek `/user/balance` API 查询
- **syn@** — 最后刷新时间（HH:MM 格式）
- **ef** — Claude Code 努力级别（MAX / HIGH / MED / LOW）
- **颜色编码** — 余额低于 ¥5 时变为黄色警告
- **优雅降级** — 网络异常时显示 `?`，不会崩溃
- **零依赖** — 仅使用 `curl`、`sed`、`awk`、`printf`（均为系统自带）

## 快速开始

### 1. 安装脚本

```bash
mkdir -p ~/.claude/skills/deepseek-status
curl -o ~/.claude/skills/deepseek-status/deepseek-status.sh \
  https://raw.githubusercontent.com/goodthins/claude-code-deepseek-status/main/deepseek-status.sh
chmod +x ~/.claude/skills/deepseek-status/deepseek-status.sh
```

### 2. 配置 Claude Code

在 `~/.claude/settings.json` 中添加：

```json
{
  "env": {
    "DEEPSEEK_API_KEY": "sk-你的密钥",
    "CLAUDE_EFFORT": "max"
  },
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/skills/deepseek-status/deepseek-status.sh"
  }
}
```

> **Windows 用户**: 如果状态栏不显示，请确保已安装 [Git for Windows](https://git-scm.com/)，并将 `bash` 路径替换为实际路径。

### 3. 重启 Claude Code

状态栏会自动出现在窗口底部。

## 环境变量

| 变量 | 必填 | 说明 |
|------|------|------|
| `DEEPSEEK_API_KEY` | 是 | DeepSeek API 密钥，从 [platform.deepseek.com](https://platform.deepseek.com/api_keys) 获取 |
| `DEEPSEEK_MODEL` | 否 | 覆盖模型名称，默认使用 `ANTHROPIC_MODEL` |
| `ANTHROPIC_MODEL` | 否 | Claude Code 通过 Anthropic 兼容接口使用时自动设置的模型名 |
| `CLAUDE_EFFORT` | 否 | 努力级别：`max`、`high`、`medium`、`low` |
| `NO_COLOR` | 否 | 设为 `1` 禁用 ANSI 颜色 |

## 命令行参数

```bash
./deepseek-status.sh [--api-key KEY] [--model NAME] [--effort LVL] [--no-color]
```

参数优先级高于环境变量。

## 颜色方案

| 元素 | 颜色 | ANSI 码 |
|------|------|---------|
| 标签 (`mod:` `bal:` `syn@` `ef:`) | 灰色 | `\033[0;90m` |
| 模型值 | 粗体青色 | `\033[1;36m` |
| 余额值（正常） | 粗体绿色 | `\033[1;32m` |
| 余额值（< ¥5） | 粗体黄色 | `\033[1;33m` |
| 时间值 | 白色 | `\033[0;37m` |
| 努力级别 | 粗体品红 | `\033[1;35m` |

## 常见问题

**Q: Windows 上能用吗？**
A: 可以，需要安装 Git Bash（Git for Windows 自带）。确保 `bash` 在 PATH 中可见。

**Q: 如果我用的是 DeepSeek 原生接口（而非 Anthropic 兼容接口）？**
A: 在 `env` 块中设置 `DEEPSEEK_MODEL=deepseek-chat`（或你使用的模型名）。

**Q: 为什么有时显示 `?`？**
A: 网络超时或 API 密钥问题。下次刷新会自动重试。

**Q: 能否用于其他 API 提供商？**
A: 目前仅支持 DeepSeek。欢迎提交 PR 支持 OpenAI、Anthropic 等。

## 许可协议

MIT — 详见 [LICENSE](LICENSE) 文件。
