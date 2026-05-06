# Claude Code DeepSeek Status Line

Real-time DeepSeek API status line plugin for [Claude Code](https://claude.ai/code). Displays your current model, account balance, sync time, and effort level — right in the status bar.

<!-- COLOR PREVIEW (renders on GitHub — bgcolor is preserved) -->
<table>
<tr>
  <td bgcolor="#555555"><font color="white"><b>&nbsp;mod:&nbsp;</b></font></td>
  <td bgcolor="#00aaaa"><b>&nbsp;v4-pro&nbsp;</b></td>
  <td>&nbsp;&nbsp;</td>
  <td bgcolor="#555555"><font color="white"><b>&nbsp;bal:&nbsp;</b></font></td>
  <td bgcolor="#00aa00"><b>&nbsp;&yen;17.38&nbsp;</b></td>
  <td>&nbsp;&nbsp;</td>
  <td bgcolor="#555555"><font color="white"><b>&nbsp;syn@&nbsp;</b></font></td>
  <td bgcolor="#cccccc"><b>&nbsp;14:32&nbsp;</b></td>
  <td>&nbsp;&nbsp;</td>
  <td bgcolor="#555555"><font color="white"><b>&nbsp;ef:&nbsp;</b></font></td>
  <td bgcolor="#aa00aa"><b>&nbsp;HIGH&nbsp;</b></td>
</tr>
</table>

> Gray labels + **cyan** model + **green** balance + white time + **magenta** effort.
> Balance turns **yellow** when < &yen;5.

## Features

- **mod** — Current model, auto-detected from environment (`deepseek-v4-pro[1m]` → `v4-pro`)
- **bal** — Real-time account balance (CNY) via DeepSeek `/user/balance` API
- **syn@** — Last refresh timestamp (HH:MM)
- **ef** — Claude Code effort level (XHIGH / HIGH / MED / LOW), read from `CLAUDE_CODE_EFFORT_LEVEL`
- **Color-coded** — Balance turns yellow when < &yen;5 as low-balance warning
- **Graceful fallback** — Shows `?` on network failure, never crashes
- **Zero dependencies** — Only `curl`, `sed`, `awk`, `printf` (all POSIX standard)

## Quick Start

> **Prerequisite:** Claude Code must already be configured to use DeepSeek's Anthropic-compatible endpoint. If you haven't done this yet, see [DeepSeek's Claude Code guide](https://platform.deepseek.com/docs).

### 1. Install the script

```bash
mkdir -p ~/.claude/skills/deepseek-status
curl -o ~/.claude/skills/deepseek-status/deepseek-status.sh \
  https://raw.githubusercontent.com/goodthins/claude-code-deepseek-status/main/deepseek-status.sh
chmod +x ~/.claude/skills/deepseek-status/deepseek-status.sh
```

### 2. Configure Claude Code

Add to `~/.claude/settings.json` (merge into existing config):

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "sk-your-deepseek-key",
    "ANTHROPIC_MODEL": "deepseek-v4-pro[1m]",
    "DEEPSEEK_API_KEY": "sk-your-deepseek-key",
    "CLAUDE_CODE_EFFORT_LEVEL": "high"
  },
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/skills/deepseek-status/deepseek-status.sh"
  }
}
```

| Key | Purpose |
|-----|---------|
| `ANTHROPIC_BASE_URL` | Route Claude Code to DeepSeek's Anthropic-compatible endpoint |
| `ANTHROPIC_AUTH_TOKEN` | DeepSeek API key (used by Claude Code for chat requests) |
| `ANTHROPIC_MODEL` | Model to use — `deepseek-v4-pro[1m]` recommended |
| `DEEPSEEK_API_KEY` | DeepSeek API key (used by this plugin for balance queries) |
| `CLAUDE_CODE_EFFORT_LEVEL` | Effort level: `high` / `medium` / `low` (see note below) |

> **Note:** `ANTHROPIC_AUTH_TOKEN` and `DEEPSEEK_API_KEY` can be the same key. They are listed separately because one feeds Claude Code's chat requests and the other feeds this plugin's balance queries.
>
> **Effort levels on DeepSeek:** `max` and `xhigh` are Opus-exclusive and are silently downgraded to `high` on non-Anthropic models. `high` is the recommended setting for DeepSeek and gives the best reasoning quality it supports.

### 3. Restart Claude Code

The status line appears at the bottom of the window automatically.

## Manual Test

```bash
export DEEPSEEK_API_KEY=sk-xxx
export ANTHROPIC_MODEL=deepseek-v4-pro
export CLAUDE_CODE_EFFORT_LEVEL=high
bash ~/.claude/skills/deepseek-status/deepseek-status.sh
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DEEPSEEK_API_KEY` | Yes | Your DeepSeek API key from [platform.deepseek.com](https://platform.deepseek.com/api_keys) |
| `DEEPSEEK_MODEL` | No | Override model name. Falls back to `ANTHROPIC_MODEL` |
| `ANTHROPIC_MODEL` | No | Model name auto-set by Claude Code when using DeepSeek Anthropic endpoint |
| `CLAUDE_CODE_EFFORT_LEVEL` | No | Effort level: `high`, `medium`, `low` (official Claude Code var) |
| `CLAUDE_EFFORT` | No | Legacy fallback — use `CLAUDE_CODE_EFFORT_LEVEL` instead |
| `NO_COLOR` | No | Set to `1` to disable ANSI colors |

## CLI Arguments

```bash
./deepseek-status.sh [--api-key KEY] [--model NAME] [--effort LVL] [--no-color]
```

Arguments override environment variables.

## Color Scheme

<table>
<tr>
  <td bgcolor="#555555"><font color="white"><b>Gray</b></font></td>
  <td>Labels: <code>mod:</code> <code>bal:</code> <code>syn@</code> <code>ef:</code></td>
  <td><code>\033[0;90m</code></td>
</tr>
<tr>
  <td bgcolor="#00aaaa"><font color="white"><b>Cyan</b></font></td>
  <td>Model value</td>
  <td><code>\033[1;36m</code></td>
</tr>
<tr>
  <td bgcolor="#00aa00"><font color="white"><b>Green</b></font></td>
  <td>Balance value (normal)</td>
  <td><code>\033[1;32m</code></td>
</tr>
<tr>
  <td bgcolor="#aaaa00"><font color="white"><b>Yellow</b></font></td>
  <td>Balance value (&lt; &yen;5)</td>
  <td><code>\033[1;33m</code></td>
</tr>
<tr>
  <td bgcolor="#cccccc"><b>White</b></td>
  <td>Time value</td>
  <td><code>\033[0;37m</code></td>
</tr>
<tr>
  <td bgcolor="#aa00aa"><font color="white"><b>Magenta</b></font></td>
  <td>Effort value</td>
  <td><code>\033[1;35m</code></td>
</tr>
</table>

## How It Works

1. Claude Code invokes the script periodically via the `statusLine` command
2. Script calls `GET https://api.deepseek.com/user/balance` (2s connect / 3s total timeout)
3. Parses `total_balance` from the JSON response
4. Outputs a single colorized line to stdout

The balance API call is free and does not consume tokens.

## FAQ

**Q: Does this work on Windows?**
A: Yes — requires Git Bash (included with Git for Windows). The `bash` command must be in your PATH. Use the full path in the `statusLine.command` if needed, e.g. `"C:\\Program Files\\Git\\bin\\bash.exe"`.

**Q: What if I use DeepSeek natively (not via the Anthropic-compatible endpoint)?**
A: Set `DEEPSEEK_MODEL=deepseek-chat` (or your model name) in the `env` block.

**Q: Why does it show `?` sometimes?**
A: Network timeout or API auth issue. The next refresh retries automatically.

**Q: Can I use this with other API providers?**
A: Currently DeepSeek-only. PRs welcome for OpenAI, Anthropic, etc.

**Q: The effort shows HIGH but I set it to max — why?**
A: `max` and `xhigh` are Opus-exclusive effort levels. On DeepSeek and other non-Anthropic models they are silently downgraded to `high`. Use `CLAUDE_CODE_EFFORT_LEVEL=high` — it's the best reasoning DeepSeek supports.

## License

MIT — see [LICENSE](LICENSE).

---

# 中文说明

## Claude Code DeepSeek 状态栏插件

实时显示 DeepSeek API 账户信息：当前模型、余额、同步时间、努力级别。

<!-- 颜色预览（GitHub 上可见真实颜色） -->
<table>
<tr>
  <td bgcolor="#555555"><font color="white"><b>&nbsp;mod:&nbsp;</b></font></td>
  <td bgcolor="#00aaaa"><b>&nbsp;v4-pro&nbsp;</b></td>
  <td>&nbsp;&nbsp;</td>
  <td bgcolor="#555555"><font color="white"><b>&nbsp;bal:&nbsp;</b></font></td>
  <td bgcolor="#00aa00"><b>&nbsp;&yen;17.38&nbsp;</b></td>
  <td>&nbsp;&nbsp;</td>
  <td bgcolor="#555555"><font color="white"><b>&nbsp;syn@&nbsp;</b></font></td>
  <td bgcolor="#cccccc"><b>&nbsp;14:32&nbsp;</b></td>
  <td>&nbsp;&nbsp;</td>
  <td bgcolor="#555555"><font color="white"><b>&nbsp;ef:&nbsp;</b></font></td>
  <td bgcolor="#aa00aa"><b>&nbsp;HIGH&nbsp;</b></td>
</tr>
</table>

> 灰色标签 + **青色**模型 + **绿色**余额 + 白色时间 + **紫色**努力级别。
> 余额低于 &yen;5 时变为**黄色**警告。

## 功能

- **mod** — 当前使用的模型，自动从环境变量获取（`deepseek-v4-pro[1m]` 简化为 `v4-pro`）
- **bal** — 实时余额（人民币），通过 DeepSeek `/user/balance` API 查询
- **syn@** — 最后刷新时间（HH:MM 格式）
- **ef** — Claude Code 努力级别（XHIGH / HIGH / MED / LOW），从 `CLAUDE_CODE_EFFORT_LEVEL` 读取
- **颜色编码** — 余额低于 &yen;5 时变为黄色警告
- **优雅降级** — 网络异常时显示 `?`，不会崩溃
- **零依赖** — 仅使用 `curl`、`sed`、`awk`、`printf`（均为系统自带）

## 快速开始

> **前提：** Claude Code 必须已配置为使用 DeepSeek 的 Anthropic 兼容接口。如果还没有，请参考 [DeepSeek 官方指南](https://platform.deepseek.com/docs)。

### 1. 安装脚本

```bash
mkdir -p ~/.claude/skills/deepseek-status
curl -o ~/.claude/skills/deepseek-status/deepseek-status.sh \
  https://raw.githubusercontent.com/goodthins/claude-code-deepseek-status/main/deepseek-status.sh
chmod +x ~/.claude/skills/deepseek-status/deepseek-status.sh
```

### 2. 配置 Claude Code

在 `~/.claude/settings.json` 中添加（与已有配置合并）：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "sk-你的密钥",
    "ANTHROPIC_MODEL": "deepseek-v4-pro[1m]",
    "DEEPSEEK_API_KEY": "sk-你的密钥",
    "CLAUDE_CODE_EFFORT_LEVEL": "high"
  },
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/skills/deepseek-status/deepseek-status.sh"
  }
}
```

| 变量 | 用途 |
|------|------|
| `ANTHROPIC_BASE_URL` | 将 Claude Code 的请求转发至 DeepSeek Anthropic 兼容接口 |
| `ANTHROPIC_AUTH_TOKEN` | DeepSeek API 密钥（供 Claude Code 对话请求使用） |
| `ANTHROPIC_MODEL` | 使用的模型，推荐 `deepseek-v4-pro[1m]` |
| `DEEPSEEK_API_KEY` | DeepSeek API 密钥（供本插件查询余额使用） |
| `CLAUDE_CODE_EFFORT_LEVEL` | 努力级别：`high` / `medium` / `low`（见下方说明） |

> **注意：** `ANTHROPIC_AUTH_TOKEN` 和 `DEEPSEEK_API_KEY` 可以用同一个密钥。分两个字段是因为一个喂给 Claude Code 的对话请求，另一个喂给本插件的余额查询。
>
> **DeepSeek 上的努力级别：** `max` 和 `xhigh` 是 Opus 专属级别，在非 Anthropic 模型上会被静默降级为 `high`。推荐使用 `high`——这是 DeepSeek 实际支持的最高推理质量。

> **Windows 用户：** 如果状态栏不显示，请确认已安装 [Git for Windows](https://git-scm.com/)。如果 `bash` 不在 PATH 中，需要在 `statusLine.command` 中使用完整路径，如 `"C:\\Program Files\\Git\\bin\\bash.exe"`。

### 3. 重启 Claude Code

状态栏会自动出现在窗口底部。

## 手动测试

```bash
export DEEPSEEK_API_KEY=sk-xxx
export ANTHROPIC_MODEL=deepseek-v4-pro
export CLAUDE_CODE_EFFORT_LEVEL=high
bash ~/.claude/skills/deepseek-status/deepseek-status.sh
```

## 环境变量

| 变量 | 必填 | 说明 |
|------|------|------|
| `DEEPSEEK_API_KEY` | 是 | DeepSeek API 密钥，从 [platform.deepseek.com](https://platform.deepseek.com/api_keys) 获取 |
| `DEEPSEEK_MODEL` | 否 | 覆盖模型名称，默认使用 `ANTHROPIC_MODEL` |
| `ANTHROPIC_MODEL` | 否 | Claude Code 通过 Anthropic 兼容接口使用时自动设置的模型名 |
| `CLAUDE_CODE_EFFORT_LEVEL` | 否 | 努力级别：`high`、`medium`、`low`（Claude Code 官方变量） |
| `CLAUDE_EFFORT` | 否 | 旧版兼容 —— 请改用 `CLAUDE_CODE_EFFORT_LEVEL` |
| `NO_COLOR` | 否 | 设为 `1` 禁用 ANSI 颜色 |

## 命令行参数

```bash
./deepseek-status.sh [--api-key KEY] [--model NAME] [--effort LVL] [--no-color]
```

参数优先级高于环境变量。

## 颜色方案

<table>
<tr>
  <td bgcolor="#555555"><font color="white"><b>灰色</b></font></td>
  <td>标签：<code>mod:</code> <code>bal:</code> <code>syn@</code> <code>ef:</code></td>
  <td><code>\033[0;90m</code></td>
</tr>
<tr>
  <td bgcolor="#00aaaa"><font color="white"><b>青色</b></font></td>
  <td>模型值</td>
  <td><code>\033[1;36m</code></td>
</tr>
<tr>
  <td bgcolor="#00aa00"><font color="white"><b>绿色</b></font></td>
  <td>余额值（正常）</td>
  <td><code>\033[1;32m</code></td>
</tr>
<tr>
  <td bgcolor="#aaaa00"><font color="white"><b>黄色</b></font></td>
  <td>余额值（&lt; &yen;5）</td>
  <td><code>\033[1;33m</code></td>
</tr>
<tr>
  <td bgcolor="#cccccc"><b>白色</b></td>
  <td>时间值</td>
  <td><code>\033[0;37m</code></td>
</tr>
<tr>
  <td bgcolor="#aa00aa"><font color="white"><b>紫色</b></font></td>
  <td>努力级别值</td>
  <td><code>\033[1;35m</code></td>
</tr>
</table>

## 工作原理

1. Claude Code 通过 `statusLine` 命令周期性调用本脚本
2. 脚本调用 `GET https://api.deepseek.com/user/balance`（连接超时 2s，总超时 3s）
3. 从 JSON 响应中提取 `total_balance` 字段
4. 输出一行带颜色的状态信息到 stdout

余额查询 API 免费，不消耗 token。

## 常见问题

**Q: Windows 上能用吗？**
A: 可以，需要安装 Git Bash（Git for Windows 自带）。确保 `bash` 在 PATH 中可见，或在配置中使用完整路径。

**Q: 如果我用的是 DeepSeek 原生接口（而非 Anthropic 兼容接口）？**
A: 在 `env` 块中设置 `DEEPSEEK_MODEL=deepseek-chat`（或你使用的模型名）。

**Q: 为什么有时显示 `?`？**
A: 网络超时或 API 密钥问题。下次刷新会自动重试。

**Q: 能否用于其他 API 提供商？**
A: 目前仅支持 DeepSeek。欢迎提交 PR 支持 OpenAI、Anthropic 等。

**Q: 努力级别显示 HIGH，但我设的是 max —— 为什么？**
A: `max` 和 `xhigh` 是 Opus 专属级别。在 DeepSeek 及其他非 Anthropic 模型上会被静默降级为 `high`。请使用 `CLAUDE_CODE_EFFORT_LEVEL=high`——这是 DeepSeek 实际支持的最高推理质量。

## 许可协议

MIT — 详见 [LICENSE](LICENSE) 文件。
