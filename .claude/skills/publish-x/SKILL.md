---
name: publish-x
description: 用 Playwright 在 X (Twitter) 發一則推文，可選帶本地圖片。
---

> 共通規則見 `CLAUDE.md`「共通行為規則」章節，本檔只描述 X 特有的步驟。
> **每步結束都要呼叫 `scripts/log-click.sh`**（格式見 CLAUDE.md「Click recording」）。

## Input
- `caption`：≤ 280 字元（含 hashtags）
- `local_image_path`：選填，本地圖檔絕對路徑
- `draft_id` / `run_id`：caller（/publish-now）傳入

## Output
```json
{ "post_url": "https://x.com/<handle>/status/..." }
```

## 流程（步驟名 = log 的 `--step` 值）

1. **`1_navigate_home`** — `browser_navigate` → `https://x.com/home`
2. **`2_click_post_button`** — 點「Post」按鈕（或用快捷鍵 `n`，這時 `--method key`）
3. **`3_type_caption`** — 輸入 caption
4. **`4_click_add_photo`** — *（僅 `local_image_path` 有值才跑）* 點「新增圖片」
5. **`5_file_upload`** — *（僅 `local_image_path` 有值才跑）* `browser_file_upload` 傳檔
6. **`6_submit_post`** — 用 `Meta+Enter`（macOS）或點「Post」送出
   - 用快捷鍵：`--method key --args '{"key":"Meta+Enter"}'`
   - 用按鈕：`--method role_name --args '{"role":"button","name":"Post"}'`
7. **`7_extract_post_url`** — 等頁面刷新、從 URL 或 toast 抓 post URL
