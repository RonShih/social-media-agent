---
description: Phase 2（搭配 /draft-post）或一步直發 — 把貼文真正發到指定平台。每平台一個 subagent 並行。
argument-hint: "draft:<id>  或  [platforms] [caption / image_path 等]"
---

兩種模式：

- **A. Draft 模式（推薦）**：`draft:<id>` 從 `reports/drafts/<id>.json` 載入 phase 1 已確認的內容直發。
- **B. 直發模式**：使用者明說「直接發 / 不要 draft」時用，從 args + TG context 拼內容。

## 模式 A：draft:<id>

1. **載入** `reports/drafts/<draft_id>.json`。找不到 → 回 `{ "error": "draft <id> not found" }`。
2. **檢查素材** — 對每個 draft 內的 `local_image_path` / `local_video_path` 跑 `local-reader.resolve_asset_path`。任一不存在直接終止整批，回 TG 哪個檔案不見了。
3. **為每個平台產生 `RUN_ID`**：`openssl rand -hex 4`（每平台獨立、用於 click-log 串接同一次 publish 的所有事件）。
4. **平行 spawn 一個 subagent / 平台**（同一個 message 內多個 Agent tool calls，subagent type = `general-purpose`）。每個 subagent 的 prompt：
   - 「請讀 `.claude/skills/publish-<platform>/SKILL.md` 後依步驟用 Playwright 發文」
   - 完整 input（caption / hashtags / 媒體路徑等，從 draft JSON 取）
   - **`DRAFT_ID="<draft_id>"` 與 `RUN_ID="<該平台的 run id>"`**（subagent 跑 `scripts/log-click.sh` 必傳）
   - 「每個 SKILL.md 編號步驟結束後（不論成敗）必須呼叫 `scripts/log-click.sh`，格式見 CLAUDE.md『Click recording』」
   - 「成功回 `{ "post_url": "..." }`、失敗回 `{ "error": "..." }`」
   - 「跑完務必呼叫 `mcp__playwright__browser_close`」
5. **每平台寫一份 post 報告** — 主 session 收齊 subagent 回傳後，逐平台 Write 到 `reports/posts/<draft_id>-<platform>.md`：

   ```markdown
   # <platform> post — <draft_id>

   - **status**: ✅ success | ❌ error
   - **post_url** | **error**: ...
   - **published_at**: <ISO>
   - **run_id**: <該平台的 run id>
   - **caption**:
     <caption>
   - **hashtags**: #a #b
   - **media**: <local path>
   ```

6. **TG 回報** — 一則訊息列出每平台 ✅ + post_url 或 ❌ + 原因 + 報告檔路徑。

## 模式 B：直發（退路）

1. 從 args + TG 訊息文字 + 上傳素材拼出 platforms / caption / hashtags / 媒體路徑。
2. **產生臨時 draft id**：`YYYYMMDD-HHMMSS-direct`，立刻寫 `reports/drafts/<id>.json`（讓事後可追溯）。
3. 後續同模式 A 步驟 3-6。

## 平台 → skill 對照

| platform | publish skill | 必填 input |
|---|---|---|
| `facebook` | `publish-facebook` | caption + hashtags + local_image_path |
| `instagram` | `publish-instagram` | caption + hashtags + local_image_path |
| `x` | `publish-x` | caption（≤ 280 含 tags）+ local_image_path（選填） |
| `youtube` | `publish-youtube` | title + description + tags + local_video_path |
| `tiktok` | `publish-tiktok` | caption + hashtags + local_video_path |

## 共通
- 全部 subagent 跑完後，**主 session 自己**呼叫 `mcp__playwright__browser_close` 一次（兜底；subagent 各自也該關，多關沒事）
- 不要主 session 內直接呼叫 `publish-*` — 一律 spawn subagent

## 驗收
- [ ] 指定平台都有貼文（或結構化 error）
- [ ] `reports/posts/<draft_id>-<platform>.md` 各平台一份
- [ ] `data/click-logs/<platform>-<YYYY-MM>.jsonl` 有當次 `run_id` 的事件（含成功與失敗步驟）
- [ ] TG 回了每平台結果 + 報告檔路徑
- [ ] 瀏覽器全部關掉

## 不要做
- 不要在主 session 直接跑 Playwright — 一律 subagent
- 不要為了「成功」偽造 post_url — 失敗就老實回 error
- 不要省掉 `reports/posts/` 報告 — 這是事後追蹤的唯一憑據
- 不要重新起草內容 — draft 已經是使用者確認過的，照發
