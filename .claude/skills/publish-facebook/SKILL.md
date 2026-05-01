---
name: publish-facebook
description: 用 Playwright 在 Facebook 個人 timeline / 粉專發一篇含圖貼文。
---

> 共通規則見 `CLAUDE.md`「共通行為規則」章節，本檔只描述 FB 特有的步驟。
> **每步結束都要呼叫 `scripts/log-click.sh`**（格式見 CLAUDE.md「Click recording」）。

## Input
- `caption`：貼文文字
- `hashtags`：list of string（接在 caption 結尾）
- `local_image_path`：本地圖檔絕對路徑
- `draft_id` / `run_id`：caller（/publish-now）傳入，用於 click-log

## Output
```json
{ "post_url": "https://..." }
```

## 流程（步驟名 = log 的 `--step` 值）

1. **`1_navigate_socials_url`** — 讀 `config/brand.yaml.socials.facebook.url`，`browser_navigate` 過去
2. **`2_click_create_post`** — 點「建立貼文 / Create post」
3. **`3_type_caption`** — 文字框輸入 `caption + "\n\n" + hashtags.join(" ")`
4. **`4_click_add_photo`** — 點圖片上傳鈕
5. **`5_file_upload`** — `browser_file_upload` 傳 `local_image_path`
6. **`6_wait_preview`** — `browser_wait_for` 等預覽載入完
7. **`7_click_publish`** — 點「發佈 / Post」
8. **`8_extract_post_url`** — 等回到動態消息頁、抓新貼文永久連結（失敗則回傳粉專 URL）

## FB 特有的坑
- 偶爾跳「您的密碼是否已洩漏」對話框 → 點 `Not now` / `稍後再說` 關閉後繼續
  - 這個「處理彈窗」**不算正式 step**，**不要 log**（log 只記 SKILL.md 編號步驟，避免污染分析資料）
- 有時 dialog 正常關閉但貼文不出現（FB 反自動化偵測） → step 8 抓不到 URL → log `8_extract_post_url --ok false --error "post not visible in timeline"`、回 caller `error`
