---
name: draft-x
description: 替 X (Twitter) 起草單篇推文（不發文）。280 字硬上限、沒有空間客套、鉤子即一切。
---

> 共通規則見 `CLAUDE.md`。本檔只描述 X drafting 的取向。

## Input
- `product_id`：對應 `config/brand.yaml.products[].id`
- `theme`：選自 `config/brand.yaml.content_themes`
- `language`：`zh-TW` / `en` / `ja` / `de`（X 國際流量為主，預設 `en`）
- `local_image_path`：選填，本地圖檔絕對路徑
- `extra`：caller 任意補充

## Output（JSON）
```json
{
  "platform": "x",
  "caption": "完整推文（含 hashtags，整段 ≤ 280 字元）",
  "hashtags": [],
  "local_image_path": "/abs/... or null",
  "rationale": "..."
}
```

> 注意：X 的 caption **就是完整推文**（含 hashtags 已嵌進去）。`hashtags` 欄位回空陣列以維持 schema 一致；`publish-x` 只會用 `caption`。

## X drafting 規則
1. **硬限制**：280 字元（中日韓字算 1）。**自己數字數**，不要丟給下游檢查。
2. **結構**：鉤子在開頭（前 5-7 字決定有沒有人停下來）→ 一個明確訊息 → 0-2 個 hashtag。
3. **Hashtag**：嵌進句子裡，不要堆結尾。0-2 個就夠；多了像垃圾訊息。
4. **不必每次都品牌 tag**：與 IG / FB 不同，X 上品牌 tag 過度會降觸及。每 3 篇有 1 篇帶就好；**caller 傳 `extra.brand_tag: true` 才強制加**。
5. **禁止 thread**：這個 skill 只起草單篇；要 thread 由 caller 拆多次呼叫。
6. **連結**：直接貼網址（X 自動縮短，但仍計入字元數 — 算進去）。

## 不要做
- 不要呼叫其他 skill
- 不要碰 Playwright
- 不要超過 280 字 — 超過就回 `{ "error": "over 280 chars: <count>" }`
- 不要把 `hashtags` 重複寫進 caption 又塞進陣列
