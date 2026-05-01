---
name: publish-instagram
description: 用 Playwright 在 Instagram 發一篇 Feed 含圖貼文（非 Story）。
---

> 共通規則見 `CLAUDE.md`「共通行為規則」章節，本檔只描述 IG 特有的步驟。
> **每步結束都要呼叫 `scripts/log-click.sh`**（格式見 CLAUDE.md「Click recording」）。

## Input
- `caption`：貼文文字
- `hashtags`：list of string（IG 上限 30 個）
- `local_image_path`：本地圖檔絕對路徑
- `draft_id` / `run_id`：caller（/publish-now）傳入

## Output
```json
{ "post_url": "https://..." }
```

## 流程（步驟名 = log 的 `--step` 值）

1. **`1_navigate_home`** — `browser_navigate` → `https://www.instagram.com/`
2. **`2_click_create_sidebar`** — 點左側 sidebar「Create / 建立」
3. **`3_click_post_option`** — 點「Post / 貼文」
4. **`4_file_upload`** — `browser_file_upload` 傳 `local_image_path`
5. **`5_click_next_crop`** — 「Next / 下一步」（跳過裁切）
6. **`6_click_next_filter`** — 「Next / 下一步」（跳過篩選器）
7. **`7_type_caption`** — caption 框輸入 `caption + "\n.\n.\n.\n" + hashtags.join(" ")`（IG 慣例：tags 與正文用 3 行點隔開）
8. **`8_click_share`** — 點「Share / 分享」
9. **`9_wait_home_return`** — 等回到首頁
10. **`10_extract_post_url`** — 讀 `config/brand.yaml.socials.instagram.url`、`browser_navigate` 過去抓最新貼文 URL

## IG 特有的坑
- IG 對自動化敏感、容易被風控 → 卡登入頁 / 卡 2FA 就 log 對應 step `--ok false --error "login or 2FA gate"` 後回 `error`，不要重試
- 這個 skill 只處理 Feed 圖片；要傳影片用其他 skill
