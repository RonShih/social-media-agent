---
name: content-writer
description: 給定產品 ID + 主題 + 平台 + 語言，產出符合品牌調性的貼文 caption 與 hashtags。
---

## Input
- `product_id`：對應 `config/brand.yaml` 的 `products[].id`
- `theme`：選自 `config/brand.yaml.content_themes`
- `platform`：facebook / instagram / tiktok / youtube / x
- `language`：zh-TW / en / ja / de（預設 zh-TW + en 並排）

## Output（JSON）
```json
{
  "caption": "...",
  "hashtags": ["#...", "#..."]
}
```

## 規則
1. 必讀 `config/brand.yaml`：
   - `company` → 品牌身分
   - `voice.tone` / `voice.audience` → 用詞風格
   - `voice.forbidden_words` → 完全避開
   - `voice.forbidden_behavior` → 完全不做
   - `products[product_id]` → 產品細節
2. 平台字數限制：
   - X：≤ 280 字元（含 hashtags）
   - Instagram：caption ≤ 2200，hashtag 5–10 個
   - Facebook：≤ 500 字
   - TikTok / YouTube Shorts：≤ 150 字 + 強行動呼籲
3. Hashtag 必含品牌標：`#${company.name_en}`（從 brand.yaml 自動帶）
4. 結尾若可加 CTA，導去 `company.website`

## 不要做
- 不要編造未驗證的測試數字或認證
- 不要承諾交期 / 折扣（除非 caller 明確傳入 promotion 欄位）
- 不要呼叫其他 skill — 純 LLM 任務
- **不要硬寫品牌名稱** — 一切從 `brand.yaml` 取得，這個 skill 對任何客戶都應該能直接重用
