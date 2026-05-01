---
name: publish-tiktok
description: 用 Playwright 在 TikTok Studio 上傳短影音。
---

> 共通規則見 `CLAUDE.md`「共通行為規則」章節，本檔只描述 TikTok 特有的步驟。
> **每步結束都要呼叫 `scripts/log-click.sh`**（格式見 CLAUDE.md「Click recording」）。

## Input
- `local_video_path`：本地影片絕對路徑
- `caption`：說明文字
- `hashtags`：list of string
- `draft_id` / `run_id`：caller（/publish-now）傳入

## Output
```json
{ "video_url": "https://..." }
```

## 流程（步驟名 = log 的 `--step` 值）

1. **`1_navigate_upload`** — `browser_navigate` → `https://www.tiktok.com/tiktokstudio/upload`
2. **`2_file_upload`** — `browser_file_upload` 傳 `local_video_path`
3. **`3_wait_preview`** — 等預覽載入
4. **`4_type_caption`** — caption 框輸入 `caption + " " + hashtags.join(" ")`
5. **`5_click_post`** — 點「Post」
6. **`6_extract_video_url`** — 等跳到 `/tiktokstudio/content`、抓影片 URL

## TikTok 特有的坑
*（這些臨時對話框處理**不算正式 step**，不要 log，避免污染分析資料）*

- 「開啟自動內容檢查？」dialog → **點「開啟」**（取消會被降級為「僅自己」）
- 「已新增編輯功能」alert → 點「知道了」
- 發佈前驗證可見度欄位是「所有人」（被降級就手動切回）
- 對自動化敏感，要求額外驗證時 log `5_click_post --ok false --error "TikTok blocked / verification required"` 後回 `{ "error": "..." }`
