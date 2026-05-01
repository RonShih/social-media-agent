---
name: draft-instagram
description: 替 Instagram Feed 貼文起草 caption + hashtags（不發文）。視覺優先、tag 密集、第一行決勝負。
---

> 共通規則見 `CLAUDE.md`。本檔只描述 IG drafting 的取向。

## Input
- `product_id`：對應 `config/brand.yaml.products[].id`
- `theme`：選自 `config/brand.yaml.content_themes`
- `language`：`zh-TW` / `en` / `ja` / `de`（預設 `zh-TW + en` 並排）
- `local_image_path`：caller 傳入的本地圖檔絕對路徑
- `extra`：caller 任意補充

## Output（JSON）
```json
{
  "platform": "instagram",
  "caption": "...",
  "hashtags": ["#NoirsBoxes", "#..."],
  "local_image_path": "/abs/...",
  "rationale": "..."
}
```

## IG drafting 規則
1. **長度**：caption ≤ 2200 字，但**前 125 字**最關鍵（手機預覽就到這）— 把鉤子塞最前面。
2. **結構**：第一行鉤子（emoji 可，但別整段都是 emoji）→ 內文 → 換行 → hashtag 區。
3. **Hashtag**：5-10 個（IG 上限 30，但 5-10 對品牌帳號最佳）。混合：
   - 品牌：`#${company.name_en}`（必）
   - 產品 / 主題（2-3 個）
   - 社群通用（剩餘）
4. **不放外連**：IG caption 內連結不可點 → 改寫「Link in bio」之類引導。
5. **語氣**：依 `voice.tone`、避開 `voice.forbidden_*`。
6. IG 不允許粗體 / 列表符號 — 用 emoji + 換行做視覺切分。

## 不要做
- 不要呼叫其他 skill
- 不要碰 Playwright
- 不要更動 `local_image_path`
- 不要超過 30 個 hashtag — IG 會擋
