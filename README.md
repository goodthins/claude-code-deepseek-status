# Claude Code AI Status Line (DeepSeek + MiMo)

Real-time API status line plugin for [Claude Code](https://claude.ai/code). Auto-detects provider from model name. Displays model, balance/credits, sync time, and effort level — right in the status bar.

### DeepSeek (pay-per-use)

<!-- COLOR PREVIEW -->
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

### MiMo (Token Plan)

<!-- RAINBOW BAR PREVIEW -->
<table>
<tr>
  <td bgcolor="#555555"><font color="white"><b>&nbsp;mod:&nbsp;</b></font></td>
  <td bgcolor="#00aaaa"><b>&nbsp;v2.5-pro&nbsp;</b></td>
  <td>&nbsp;&nbsp;</td>
  <td bgcolor="#333333"><font color="#ff0000"><b>█</b></font><font color="#ff8700"><b>█</b></font><font color="#ffd700"><b>█</b></font><font color="#00ff00"><b>█</b></font><font color="#00ffff"><b>█</b></font><font color="#5f00ff"><b>█</b></font><font color="#ff005f"><b>█</b></font><font color="#888888">░</font><font color="#888888">░</font><font color="#888888">░</font><font color="#888888">░</font><font color="#888888">░</font></td>
  <td>&nbsp;&nbsp;</td>
  <td bgcolor="#555555"><font color="white"><b>&nbsp;syn@&nbsp;</b></font></td>
  <td bgcolor="#cccccc"><b>&nbsp;14:32&nbsp;</b></td>
  <td>&nbsp;&nbsp;</td>
  <td bgcolor="#555555"><font color="white"><b>&nbsp;ef:&nbsp;</b></font></td>
  <td bgcolor="#aa00aa"><b>&nbsp;HIGH&nbsp;</b></td>
</tr>
</table>

## Features

- **Auto-detection** — Switches between DeepSeek / MiMo based on model name prefix
- **mod** — Current model, auto-detected from environment (`deepseek-v4-pro[1m]` → `v4-pro`, `mimo-v2.5-pro` → `v2.5-pro`)
- **bal** (DeepSeek) — Real-time account balance (CNY) via `/user/balance` API
- **credits bar** (MiMo) — Rainbow Unicode progress bar showing credits consumed vs. Token Plan quota, auto-tracked from local audit logs
- **syn@** — Last refresh timestamp (HH:MM)
- **ef** — Claude Code effort level (XHIGH / HIGH / MED / LOW)
- **Color-coded** — Balance turns yellow when < &yen;5; progress bar uses 12-color rainbow gradient
- **Graceful fallback** — Shows `?` / `[?]` on missing config, never crashes
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

---

## MiMo Token Plan Setup

### 1. Configure Claude Code

Add to `~/.claude/settings.json` (merge into existing config):

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

| Key | Purpose |
|-----|---------|
| `ANTHROPIC_BASE_URL` | MiMo Token Plan Anthropic-compatible endpoint (China) |
| `ANTHROPIC_AUTH_TOKEN` | Your MiMo Token Plan API key (starts with `tp-`) |
| `ANTHROPIC_MODEL` | Model to use — `mimo-v2.5-pro` recommended |
| `MIMO_TOKEN_PLAN_TOTAL_CREDITS` | Your plan's total credit quota (see table below) |

**Token Plan quotas:**

| Plan | Monthly Price | Credits | Config |
|------|-------------|---------|--------|
| Lite | ¥39 | 60,000,000 | `60000000` |
| Standard | ¥99 | 200,000,000 | `200000000` |
| Pro | ¥329 | 700,000,000 | `700000000` |
| Max | ¥659 | 1,600,000,000 | `1600000000` |

### 2. How Credits Tracking Works

Since MiMo has no public balance API, the script parses Claude Code's local audit logs (`~/.claude/projects/*/*.jsonl`) to auto-track token consumption. Each refresh it sums all `input_tokens + output_tokens` from MiMo model calls, converts to credits using the model-specific multiplier, and renders the progress bar.

**Credit multipliers by model:**
- MiMo-V2-Omni: 1 Token = 1 Credit
- MiMo-V2.5-Pro / V2-Pro: 1 Token = 2 Credits
- Others: 2x (default, override with `MIMO_CREDIT_MULTIPLIER`)

### 3. Restart Claude Code

The status line appears with the rainbow credits progress bar.

---

## Manual Test

**DeepSeek:**
```bash
export DEEPSEEK_API_KEY=sk-xxx
export ANTHROPIC_MODEL=deepseek-v4-pro
export CLAUDE_CODE_EFFORT_LEVEL=high
bash ~/.claude/skills/deepseek-status/deepseek-status.sh
```

**MiMo Token Plan:**
```bash
export ANTHROPIC_MODEL=mimo-v2.5-pro
export MIMO_TOKEN_PLAN_TOTAL_CREDITS=700000000
export CLAUDE_CODE_EFFORT_LEVEL=high
bash ~/.claude/skills/deepseek-status/deepseek-status.sh
```

## Environment Variables

| Variable | Required | Provider | Description |
|----------|----------|----------|-------------|
| `DEEPSEEK_API_KEY` | DeepSeek only | DeepSeek | Your DeepSeek API key from [platform.deepseek.com](https://platform.deepseek.com/api_keys) |
| `MIMO_TOKEN_PLAN_TOTAL_CREDITS` | MiMo Token Plan | MiMo | Your Token Plan total credit quota (e.g. `700000000` for Pro) |
| `MIMO_CREDIT_MULTIPLIER` | No | MiMo | Override Token→Credit multiplier (auto-detected from model) |
| `DEEPSEEK_MODEL` | No | Both | Override model name. Falls back to `ANTHROPIC_MODEL` |
| `ANTHROPIC_MODEL` | No | Both | Model name auto-set by Claude Code |
| `CLAUDE_CODE_EFFORT_LEVEL` | No | Both | Effort level: `high`, `medium`, `low` (official Claude Code var) |
| `CLAUDE_EFFORT` | No | Both | Legacy fallback — use `CLAUDE_CODE_EFFORT_LEVEL` instead |
| `NO_COLOR` | No | Both | Set to `1` to disable ANSI colors |

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

**Q: How does MiMo credits tracking work without a balance API?**
A: MiMo has no public balance/credits endpoint. The script parses Claude Code's local audit logs (`~/.claude/projects/*/*.jsonl`) and sums all `input_tokens + output_tokens` from MiMo model calls, then converts to credits using the model's multiplier. This is automatic — no manual input needed.

**Q: How do I switch between DeepSeek and MiMo?**
A: Just change `ANTHROPIC_MODEL` in your settings.json. The script auto-detects the provider from the model name prefix (`deepseek-` vs `mimo-`).

**Q: Can I use this with other API providers?**
A: Currently supports DeepSeek and MiMo. PRs welcome for OpenAI, Anthropic, etc.

**Q: The effort shows HIGH but I set it to max — why?**
A: `max` and `xhigh` are Opus-exclusive effort levels. On non-Anthropic models they are silently downgraded to `high`. Use `CLAUDE_CODE_EFFORT_LEVEL=high`.

## License

MIT — see [LICENSE](LICENSE).

---

# Claude Code AI 状态栏插件 (DeepSeek + MiMo)

实时显示 API 账户信息：当前模型、余额/额度、同步时间、努力级别。根据模型名自动识别厂商。

### DeepSeek (按量付费)

<!-- 颜色预览 -->
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

### MiMo (Token Plan)

<!-- 彩虹进度条预览 -->
<table>
<tr>
  <td bgcolor="#555555"><font color="white"><b>&nbsp;mod:&nbsp;</b></font></td>
  <td bgcolor="#00aaaa"><b>&nbsp;v2.5-pro&nbsp;</b></td>
  <td>&nbsp;&nbsp;</td>
  <td bgcolor="#333333"><font color="#ff0000"><b>█</b></font><font color="#ff8700"><b>█</b></font><font color="#ffd700"><b>█</b></font><font color="#00ff00"><b>█</b></font><font color="#00ffff"><b>█</b></font><font color="#5f00ff"><b>█</b></font><font color="#ff005f"><b>█</b></font><font color="#888888">░</font><font color="#888888">░</font><font color="#888888">░</font><font color="#888888">░</font><font color="#888888">░</font></td>
  <td>&nbsp;&nbsp;</td>
  <td bgcolor="#555555"><font color="white"><b>&nbsp;syn@&nbsp;</b></font></td>
  <td bgcolor="#cccccc"><b>&nbsp;14:32&nbsp;</b></td>
  <td>&nbsp;&nbsp;</td>
  <td bgcolor="#555555"><font color="white"><b>&nbsp;ef:&nbsp;</b></font></td>
  <td bgcolor="#aa00aa"><b>&nbsp;HIGH&nbsp;</b></td>
</tr>
</table>

## 功能

- **自动识别** — 根据模型名前缀（`deepseek-` vs `mimo-`）自动切换厂商
- **mod** — 当前使用的模型，自动从环境变量获取并简化显示（`deepseek-v4-pro[1m]` → `v4-pro`，`mimo-v2.5-pro` → `v2.5-pro`）
- **bal** (DeepSeek) — 实时余额（人民币），通过 DeepSeek `/user/balance` API 查询
- **额度进度条** (MiMo) — 彩虹 Unicode 进度条展示已用 Credits 占比，通过解析本地 audit_log 自动累计
- **syn@** — 最后刷新时间（HH:MM 格式）
- **ef** — Claude Code 努力级别（XHIGH / HIGH / MED / LOW）
- **颜色编码** — 余额低于 ¥5 时变为黄色警告；进度条使用 12 色彩虹渐变
- **优雅降级** — 配置缺失时显示 `?` / `[?]`，不会崩溃
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

---

## MiMo Token Plan 部署

### 1. 配置 Claude Code

在 `~/.claude/settings.json` 中添加：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://token-plan-cn.xiaomimimo.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "tp-你的密钥",
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

| 变量 | 用途 |
|------|------|
| `ANTHROPIC_BASE_URL` | MiMo Token Plan Anthropic 兼容接口（国内节点） |
| `ANTHROPIC_AUTH_TOKEN` | MiMo Token Plan API 密钥（以 `tp-` 开头） |
| `ANTHROPIC_MODEL` | 使用的模型，推荐 `mimo-v2.5-pro` |
| `MIMO_TOKEN_PLAN_TOTAL_CREDITS` | 你的套餐总 Credits 额度（见下表） |

**Token Plan 套餐额度：**

| 套餐 | 月费 | Credits | 配置值 |
|------|------|---------|--------|
| Lite | ¥39 | 6,000万 | `60000000` |
| Standard | ¥99 | 2亿 | `200000000` |
| Pro | ¥329 | 7亿 | `700000000` |
| Max | ¥659 | 16亿 | `1600000000` |

### 2. Credits 追踪原理

MiMo 没有公开的余额/额度查询 API。脚本通过解析 Claude Code 本地的审计日志（`~/.claude/projects/*/*.jsonl`）自动累计所有 MiMo 模型调用的 `input_tokens + output_tokens`，再乘以模型对应的 Credit 倍率，得到已消耗 Credits，与总配额对比渲染进度条。

**各模型 Credit 倍率：**
- MiMo-V2-Omni: 1 Token = 1 Credit
- MiMo-V2.5-Pro / V2-Pro: 1 Token = 2 Credits
- 其他: 默认 2x（可通过 `MIMO_CREDIT_MULTIPLIER` 覆盖）

### 3. 重启 Claude Code

状态栏将显示彩虹额度进度条。

---

## 手动测试

**DeepSeek：**
```bash
export DEEPSEEK_API_KEY=sk-xxx
export ANTHROPIC_MODEL=deepseek-v4-pro
export CLAUDE_CODE_EFFORT_LEVEL=high
bash ~/.claude/skills/deepseek-status/deepseek-status.sh
```

**MiMo Token Plan：**
```bash
export ANTHROPIC_MODEL=mimo-v2.5-pro
export MIMO_TOKEN_PLAN_TOTAL_CREDITS=700000000
export CLAUDE_CODE_EFFORT_LEVEL=high
bash ~/.claude/skills/deepseek-status/deepseek-status.sh
```

## 环境变量

| 变量 | 必填 | 适用厂商 | 说明 |
|------|------|----------|------|
| `DEEPSEEK_API_KEY` | DeepSeek 必填 | DeepSeek | DeepSeek API 密钥，从 [platform.deepseek.com](https://platform.deepseek.com/api_keys) 获取 |
| `MIMO_TOKEN_PLAN_TOTAL_CREDITS` | MiMo Token Plan 必填 | MiMo | 你的 Token Plan 总 Credits 额度（如 Pro 套餐填 `700000000`） |
| `MIMO_CREDIT_MULTIPLIER` | 否 | MiMo | Token→Credit 倍率覆盖（默认根据模型自动判断） |
| `DEEPSEEK_MODEL` | 否 | 通用 | 覆盖模型名称，默认使用 `ANTHROPIC_MODEL` |
| `ANTHROPIC_MODEL` | 否 | 通用 | Claude Code 自动设置的模型名 |
| `CLAUDE_CODE_EFFORT_LEVEL` | 否 | 通用 | 努力级别：`high`、`medium`、`low`（Claude Code 官方变量） |
| `CLAUDE_EFFORT` | 否 | 通用 | 旧版兼容 —— 请改用 `CLAUDE_CODE_EFFORT_LEVEL` |
| `NO_COLOR` | 否 | 通用 | 设为 `1` 禁用 ANSI 颜色 |

## 命令行参数

```bash
./deepseek-status.sh [--api-key KEY] [--model NAME] [--effort LVL] [--total-credits N] [--no-color]
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
<tr>
  <td bgcolor="#ff0000"><font color="white"><b>红</b></font>→<font color="white"><b>粉</b></font></td>
  <td>MiMo 额度进度条（12 色彩虹渐变）</td>
  <td><code>\033[38;5;196m</code>~<code>201m</code></td>
</tr>
</table>

## 工作原理

1. Claude Code 通过 `statusLine` 命令周期性调用本脚本
2. 脚本根据模型名前缀自动识别厂商（`deepseek-` / `mimo-`）
3. **DeepSeek**：调用 `GET https://api.deepseek.com/user/balance`（连接超时 2s，总超时 3s），提取 `total_balance` 字段
4. **MiMo Token Plan**：解析 `~/.claude/projects/*/*.jsonl` 审计日志，累计所有 MiMo 模型调用的 input/output tokens，乘以 Credit 倍率得到已消耗 Credits，与总配额对比渲染彩虹进度条
5. 输出一行带颜色的状态信息到 stdout

余额/额度查询不消耗 token。

## 常见问题

**Q: Windows 上能用吗？**
A: 可以，需要安装 Git Bash（Git for Windows 自带）。确保 `bash` 在 PATH 中可见，或在配置中使用完整路径。

**Q: 如果我用的是 DeepSeek 原生接口（而非 Anthropic 兼容接口）？**
A: 在 `env` 块中设置 `DEEPSEEK_MODEL=deepseek-chat`（或你使用的模型名）。

**Q: 为什么有时显示 `?`？**
A: 网络超时或 API 密钥问题。下次刷新会自动重试。

**Q: MiMo 的 Credits 是怎么追踪的？没有 API 查余额吗？**
A: MiMo 没有公开的余额/额度查询 API。脚本通过解析 Claude Code 本地的审计日志（`~/.claude/projects/*/*.jsonl`），自动累计所有 MiMo 模型调用的 `input_tokens + output_tokens`，再乘以模型对应的 Credit 倍率转为已消耗 Credits。全程自动，无需手动输入。

**Q: 如何在 DeepSeek 和 MiMo 之间切换？**
A: 只需在 settings.json 中修改 `ANTHROPIC_MODEL`。脚本会根据模型名前缀（`deepseek-` vs `mimo-`）自动识别厂商。

**Q: 能否用于其他 API 提供商？**
A: 目前已支持 DeepSeek 和 MiMo。欢迎提交 PR 支持 OpenAI、Anthropic 等。

**Q: 努力级别显示 HIGH，但我设的是 max —— 为什么？**
A: `max` 和 `xhigh` 是 Opus 专属级别。在非 Anthropic 模型上会被静默降级为 `high`。请使用 `CLAUDE_CODE_EFFORT_LEVEL=high`。

## 许可协议

MIT — 详见 [LICENSE](LICENSE) 文件。
