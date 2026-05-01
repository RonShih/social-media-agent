---
name: draft-facebook
description: 替 Facebook 貼文起草 caption + hashtags（不發文）。FB 文長中等、可帶連結、tag 不必密集。
---

> 共通規則見 `CLAUDE.md`。本檔只描述 FB drafting 的取向。

## Input
- `product_id`：對應 `config/brand.yaml.products[].id`
- `theme`：選自 `config/brand.yaml.content_themes`
- `language`：`zh-TW` / `en` / `ja` / `de`（預設 `zh-TW + en` 並排）
- `local_image_path`：caller 傳入的本地圖檔絕對路徑（draft 不檢查存在性，由 publish-* 階段檢查）
- `extra`：caller 任意補充（活動、節日、要強調的賣點）

## Output（JSON）
```json
{
  "platform": "facebook",
  "caption": "...",
  "hashtags": ["#NoirsBoxes", "#..."],
  "local_image_path": "/abs/...",
  "rationale": "為什麼這樣寫（一兩句，方便使用者判斷要不要改）"
}
```

## FB drafting 規則
1. **長度**：caption ≤ 500 字（含換行）。FB 用戶吃得下完整故事，不要硬縮短到 IG 那樣。
2. **結構**：開場鉤子（1 行）→ 故事 / 賣點（2-4 行）→ CTA + 連結（`config/brand.yaml.company.website`）。
3. **Hashtag**：3-6 個就好；FB 上密集 hashtag 觀感差。品牌 tag `#${company.name_en}` 必含。
4. **語氣**：依 `voice.tone`，`voice.forbidden_words` / `voice.forbidden_behavior` 全部避開。
5. **連結放法**：直接貼網址，FB 會自動展 OG 卡片。
6. **不要**承諾交期 / 折扣（除非 `extra.promotion` 明確傳入）。

## 不要做
- 不要呼叫其他 skill（含 `publish-facebook`）
- 不要碰 Playwright、不要開瀏覽器
- 不要把 `local_image_path` 換成你自己挑的路徑 — 原樣回傳 caller 給的值
- 不要硬寫品牌名 — 一切從 `brand.yaml` 取
