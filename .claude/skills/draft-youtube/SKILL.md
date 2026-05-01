---
name: draft-youtube
description: 替 YouTube 影片起草 title + description + tags（不上傳）。SEO 取向，title 是流量決定者。
---

> 共通規則見 `CLAUDE.md`。本檔只描述 YT drafting 的取向。

## Input
- `product_id`：對應 `config/brand.yaml.products[].id`
- `theme`：選自 `config/brand.yaml.content_themes`
- `language`：`zh-TW` / `en` / `ja` / `de`（預設 `en` — YT 國際流量）
- `local_video_path`：本地影片絕對路徑
- `format`：`shorts`（≤ 60 秒）或 `long`（一般長片）。預設 `shorts`。
- `extra`：caller 任意補充

## Output（JSON）
```json
{
  "platform": "youtube",
  "title": "...",
  "description": "...",
  "tags": ["...", "..."],
  "local_video_path": "/abs/...",
  "visibility": "public",
  "rationale": "..."
}
```

## YT drafting 規則

### Title（最重要）
1. ≤ 60 字元（行動裝置截斷邊界）。
2. 前 30 字元放關鍵字（產品名 / 痛點 / 數字）— SEO 與點擊率都看這。
3. **不要**ALL CAPS、不要 clickbait（`config/brand.yaml.voice.forbidden_behavior` 通常會列）。

### Description
1. 前 150 字元最關鍵（搜尋結果預覽 + RSS）— 用一句總結影片價值。
2. 結構：一句總結 → 章節時間戳（long 形才需要）→ 連結（`company.website`、社群）→ hashtag（前 3 個會變成 title 上方的 chip）。
3. Shorts 可以短到一行 + 3 個 hashtag。
4. 連結用完整 URL（YT 會自動轉藍）。

### Tags
1. 5-15 個，混合具體（產品名 / 型號）+ 大類（產業 / 主題）。
2. **不要重複**也不要近義詞堆疊（YT 會懲罰 keyword stuffing）。

### Visibility
- 預設 `public`；`extra.visibility` 可覆寫成 `unlisted` / `private`。

## 不要做
- 不要呼叫其他 skill
- 不要碰 Playwright
- 不要 clickbait（誇大數字、釣魚 title）— 會違反 `voice.forbidden_behavior`
- title 不要 emoji 開頭（YT 演算法降權）
