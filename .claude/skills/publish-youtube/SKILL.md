---
name: publish-youtube
description: 用 Playwright 在 YouTube Studio 上傳影片並填 metadata。
---

> 共通規則見 `CLAUDE.md`「共通行為規則」章節，本檔只描述 YT 特有的步驟。
> **每步結束都要呼叫 `scripts/log-click.sh`**（格式見 CLAUDE.md「Click recording」）。

## Input
- `local_video_path`：本地影片絕對路徑
- `title`：YT 標題
- `description`：YT 描述
- `tags`：list of string
- `visibility`：public | unlisted | private（預設 public）
- `playlist`：選填
- `draft_id` / `run_id`：caller（/publish-now）傳入

## Output
```json
{ "video_url": "https://www.youtube.com/watch?v=..." }
```

## 流程（步驟名 = log 的 `--step` 值）

1. **`1_navigate_studio`** — `browser_navigate` → `https://studio.youtube.com/`
2. **`2_click_create`** — 點「Create」
3. **`3_click_upload_videos`** — 點「Upload videos」
4. **`4_file_upload`** — `browser_file_upload` 傳 `local_video_path`
5. **`5_wait_details_page`** — 等 Details 頁載入
6. **`6_type_title`** — 清空 title 欄 → 輸入 `title`
7. **`7_type_description`** — 清空 description 欄 → 貼 `description`
8. **`8_click_show_more`** — 「Show more」
9. **`9_type_tags`** — Tags 欄輸入 `tags.join(", ")`
10. **`10_click_audience_no_kids`** — 「Audience」→ 選「No, it's not made for kids」
11. **`11_click_next_elements`** — 「Next」（跳過 elements）
12. **`12_click_next_checks`** — 「Next」（跳過 checks）
13. **`13_select_visibility`** — Visibility 頁選對應 radio button（依 `visibility` 值）
14. **`14_wait_save_enabled`** — 等 Save 按鈕可點
15. **`15_click_save_publish`** — 點「Save / Publish」
16. **`16_wait_published_dialog`** — 等「Video published」對話框
17. **`17_extract_video_url`** — 從對話框抓影片 URL

## YT 特有的坑
- 大檔上傳要 5-15 分 → step 5（wait_details_page）的 `timeout_s` 設大；若 timeout 就 log `--ok false --error "upload timeout"` 回 error
- 偶爾要求「Verify channel」→ log `--ok false --error "channel verification required"` 回 `{ "error": "need channel verification" }` 中止
