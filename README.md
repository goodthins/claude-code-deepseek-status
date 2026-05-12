# Claude Code DeepSeek Status Line

Real-time DeepSeek account status line for [Claude Code](https://claude.ai/code). Displays the current model, DeepSeek balance, refresh time, and effort level in Claude Code's status bar.

### Preview

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

## Features

- **mod** — Current model, shortened for display (`deepseek-v4-pro[1m]` -> `v4-pro`)
- **bal** — Real-time DeepSeek account balance via `/user/balance`
- **syn@** — Last refresh time (`HH:MM`)
- **ef** — Claude Code effort level (`XHIGH` / `HIGH` / `MED` / `LOW`)
- **Color-coded** — Balance turns yellow when below ¥5
- **Graceful fallback** — Shows `?` if the API key is missing or the balance query fails
- **Zero runtime dependencies** — Uses standard shell tools plus `curl`

## Fresh Machine Setup

Use this path after Claude Code is already installed and configured to use DeepSeek's Anthropic-compatible endpoint.

### 1. Install the plugin metadata

This lets Claude Code recognize the package as a plugin/marketplace entry. The status line itself is configured in step 3.

```bash
claude plugin marketplace add goodthins/claude-code-deepseek-status
claude plugin install deepseek-status@goodthins-claude-plugins
```

If you cloned this repository locally, install from the local path:

```bash
claude plugin marketplace add /path/to/claude-code-deepseek-status
claude plugin install deepseek-status@goodthins-claude-plugins
```

### 2. Install the status line script

```bash
mkdir -p ~/.claude/skills/deepseek-status
curl -L -o ~/.claude/skills/deepseek-status/deepseek-status.sh \
  https://raw.githubusercontent.com/goodthins/claude-code-deepseek-status/main/deepseek-status.sh
chmod +x ~/.claude/skills/deepseek-status/deepseek-status.sh
```

### 3. Configure Claude Code

Add this to `~/.claude/settings.json` and merge it with any existing settings:

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
| `ANTHROPIC_BASE_URL` | Routes Claude Code to DeepSeek's Anthropic-compatible endpoint |
| `ANTHROPIC_AUTH_TOKEN` | DeepSeek API key used by Claude Code chat requests |
| `ANTHROPIC_MODEL` | DeepSeek model name |
| `DEEPSEEK_API_KEY` | DeepSeek API key used by this status line to query balance |
| `CLAUDE_CODE_EFFORT_LEVEL` | Effort level: `high`, `medium`, or `low` |

`ANTHROPIC_AUTH_TOKEN` and `DEEPSEEK_API_KEY` can be the same key.

### 4. Restart Claude Code

The status line appears at the bottom of the Claude Code window.

### Windows

Windows users should install Git for Windows. If `bash` resolves to Windows' WSL launcher, use the full Git Bash path:

```json
{
  "statusLine": {
    "type": "command",
    "command": "\"C:\\Program Files\\Git\\bin\\bash.exe\" ~/.claude/skills/deepseek-status/deepseek-status.sh"
  }
}
```

## Manual Test

```bash
export DEEPSEEK_API_KEY=sk-xxx
export ANTHROPIC_MODEL=deepseek-v4-pro
export CLAUDE_CODE_EFFORT_LEVEL=high
bash ~/.claude/skills/deepseek-status/deepseek-status.sh
```

Expected shape:

```text
mod:v4-pro  bal:¥17.38  syn@14:32  ef:HIGH
```

## CLI Arguments

```bash
./deepseek-status.sh [--api-key KEY] [--model NAME] [--effort LVL] [--no-color]
```

Arguments override environment variables.

## How It Works

1. Claude Code invokes `deepseek-status.sh` through `statusLine.command`
2. The script reads Claude Code status-line JSON from stdin, with environment variables as fallback
3. The script calls `GET https://api.deepseek.com/user/balance`
4. It parses `total_balance` and prints one colorized status line

The balance API call is free and does not consume model tokens.

## FAQ

**Q: What if it shows `bal:?`?**
A: The API key is missing, the network request timed out, or the balance API returned an unexpected response. The next refresh retries automatically.

**Q: Can I use DeepSeek natively instead of the Anthropic-compatible endpoint?**
A: Set `DEEPSEEK_MODEL=deepseek-chat` or another model name in the `env` block.

**Q: Can I use this with other providers?**
A: No. This plugin is intentionally DeepSeek-only because it relies on DeepSeek's official balance API.

## License

MIT — see [LICENSE](LICENSE).

---

# Claude Code DeepSeek 状态栏

用于 [Claude Code](https://claude.ai/code) 的 DeepSeek 实时状态栏。显示当前模型、DeepSeek 余额、刷新时间和努力级别。

### 预览

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

## 功能

- **mod** — 当前模型，简化显示（`deepseek-v4-pro[1m]` -> `v4-pro`）
- **bal** — 通过 DeepSeek `/user/balance` 查询实时账户余额
- **syn@** — 最后刷新时间（`HH:MM`）
- **ef** — Claude Code 努力级别（`XHIGH` / `HIGH` / `MED` / `LOW`）
- **颜色提示** — 余额低于 ¥5 时变为黄色
- **优雅降级** — API key 缺失或查询失败时显示 `?`
- **零运行依赖** — 只使用标准 shell 工具和 `curl`

## 新电脑完整配置

适用于已经安装 Claude Code，并准备把 Claude Code 配置到 DeepSeek Anthropic 兼容接口的新电脑。

### 1. 安装插件元信息

这一步让 Claude Code 识别本包的插件/marketplace 信息。状态栏本身在第 3 步配置。

```bash
claude plugin marketplace add goodthins/claude-code-deepseek-status
claude plugin install deepseek-status@goodthins-claude-plugins
```

如果你已经把本仓库 clone 到本地，也可以从本地路径安装：

```bash
claude plugin marketplace add /path/to/claude-code-deepseek-status
claude plugin install deepseek-status@goodthins-claude-plugins
```

### 2. 安装状态栏脚本

```bash
mkdir -p ~/.claude/skills/deepseek-status
curl -L -o ~/.claude/skills/deepseek-status/deepseek-status.sh \
  https://raw.githubusercontent.com/goodthins/claude-code-deepseek-status/main/deepseek-status.sh
chmod +x ~/.claude/skills/deepseek-status/deepseek-status.sh
```

### 3. 配置 Claude Code

在 `~/.claude/settings.json` 中添加以下配置，并与已有配置合并：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "sk-你的-deepseek-key",
    "ANTHROPIC_MODEL": "deepseek-v4-pro[1m]",
    "DEEPSEEK_API_KEY": "sk-你的-deepseek-key",
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
| `ANTHROPIC_BASE_URL` | 将 Claude Code 请求转到 DeepSeek Anthropic 兼容接口 |
| `ANTHROPIC_AUTH_TOKEN` | Claude Code 对话请求使用的 DeepSeek API key |
| `ANTHROPIC_MODEL` | DeepSeek 模型名 |
| `DEEPSEEK_API_KEY` | 本状态栏查询余额使用的 DeepSeek API key |
| `CLAUDE_CODE_EFFORT_LEVEL` | 努力级别：`high`、`medium` 或 `low` |

`ANTHROPIC_AUTH_TOKEN` 和 `DEEPSEEK_API_KEY` 可以使用同一个 key。

### 4. 重启 Claude Code

状态栏会出现在 Claude Code 窗口底部。

### Windows

Windows 用户请安装 Git for Windows。如果 `bash` 被解析成 Windows 自带的 WSL launcher，请使用完整 Git Bash 路径：

```json
{
  "statusLine": {
    "type": "command",
    "command": "\"C:\\Program Files\\Git\\bin\\bash.exe\" ~/.claude/skills/deepseek-status/deepseek-status.sh"
  }
}
```

## 手动测试

```bash
export DEEPSEEK_API_KEY=sk-xxx
export ANTHROPIC_MODEL=deepseek-v4-pro
export CLAUDE_CODE_EFFORT_LEVEL=high
bash ~/.claude/skills/deepseek-status/deepseek-status.sh
```

预期格式：

```text
mod:v4-pro  bal:¥17.38  syn@14:32  ef:HIGH
```

## 命令行参数

```bash
./deepseek-status.sh [--api-key KEY] [--model NAME] [--effort LVL] [--no-color]
```

命令行参数优先于环境变量。

## 工作原理

1. Claude Code 通过 `statusLine.command` 调用 `deepseek-status.sh`
2. 脚本读取 Claude Code 传入的 status-line JSON，环境变量作为 fallback
3. 脚本调用 `GET https://api.deepseek.com/user/balance`
4. 解析 `total_balance` 并输出一行彩色状态信息

余额查询 API 免费，不消耗模型 token。

## FAQ

**Q: 为什么显示 `bal:?`？**
A: API key 缺失、网络请求超时，或余额 API 返回格式异常。下一次刷新会自动重试。

**Q: 如果我使用 DeepSeek 原生接口而不是 Anthropic 兼容接口？**
A: 在 `env` 中设置 `DEEPSEEK_MODEL=deepseek-chat` 或其他模型名。

**Q: 能用于其他服务商吗？**
A: 不能。本插件现在刻意只支持 DeepSeek，因为它依赖 DeepSeek 官方余额查询 API。

## 许可证

MIT — 见 [LICENSE](LICENSE)。
