# 使用手冊

TG bot 下指令 → Claude 開瀏覽器發到 5 平台（FB / IG / X / YT / TikTok）。

---

## 1. TG bot

照官方文件設定：**https://code.claude.com/docs/en/channels**

設完後，啟動指令：

```bash
claude --channels plugin:telegram@claude-plugins-official
```

終端機保持開著 = bot 上線。

---

## 2. Claude 設定（一次）

```bash
git clone <repo-url> && cd social-media-agent
cp .claude/settings.example.json .claude/settings.json
# 把 settings.json 內 <ABSOLUTE_PATH_TO_REPO> 換成此 repo 絕對路徑

# 註冊 user-level Playwright MCP（channel session 不讀專案層 settings）
claude mcp add playwright -s user -- npx -y @playwright/mcp@latest \
  --user-data-dir <ABSOLUTE_PATH_TO_REPO>/browser_profiles
```

`~/.claude/settings.json` 加 `"defaultMode": "bypassPermissions"`，**Cmd+Q 重啟**。

進 repo 跑 `claude`，依序：

- `/setup` — 對話式建 `config/brand.yaml`
- `/first-time-login` — 登 5 平台，登完關 Chromium
- 素材丟 `media/assets/`

---

## 3. 日常使用

對 TG bot 直接講話：

| 你說 | Claude 做 |
|---|---|
| 上傳圖 + `發 IG，caption: ...` | 起 draft → 你確認 → 發文 |
| `發 FB+IG，caption: ...` | 多平台並行 |
| `/publish-now draft:<id>` | 確認某個 draft 發出 |
| `/weekly-report` | 產 `reports/<YYYY-WWW>.md` |
| `/analyze-hotspots` | 5 平台熱點分析 |
| `/unlock-browser` | 解 Chromium profile lock |

預設兩階段：先 draft 預覽、回 `/publish-now draft:<id>` 才真的發。要直發就講「直接發、不要 draft」。

---

## 故障

| 症狀 | 解法 |
|---|---|
| 跳權限提示 | `bypassPermissions` 沒設 → §2 |
| 找不到 `mcp__playwright__*` | 重跑 §2 的 `claude mcp add playwright` |
| Chromium profile lock | `/unlock-browser` |
| 發文後貼文不見（FB / IG）| 平台靜默 block，間歇性，重試 |

換客戶 → `/setup` + 換 `media/assets/` + `/first-time-login`。
