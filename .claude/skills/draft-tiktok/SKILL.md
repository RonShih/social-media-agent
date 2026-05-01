---
name: draft-tiktok
description: 替 TikTok 短片起草 caption + hashtags（不上傳）。前 3 秒鉤子、強行動呼籲、tag 趨勢化。
---

> 共通規則見 `CLAUDE.md`。本檔只描述 TikTok drafting 的取向。

## Input
- `product_id`：對應 `config/brand.yaml.products[].id`
- `theme`：選自 `config/brand.yaml.content_themes`
- `language`：`zh-TW` / `en` / `ja` / `de`（預設 `en`）
- `local_video_path`：本地影片絕對路徑
- `extra`：caller 任意補充

## Output（JSON）
```json
{
  "platform": "tiktok",
  "caption": "...",
  "hashtags": ["#fyp", "#NoirsBoxes", "..."],
  "local_video_path": "/abs/...",
  "rationale": "..."
}
```

## TikTok drafting 規則
1. **長度**：caption ≤ 150 字 + 強 CTA（「留言告訴我...」「點 link」）。冗長即跳出。
2. **鉤子句**：caption 第一句要對應影片前 3 秒的視覺鉤子 — 兩者要呼應。
3. **Hashtag**：
   - 必含品牌 `#${company.name_en}`
   - 必含 `#fyp` 或 `#foryou`（演算法 hint，業界共識）
   - 2-3 個產品 / 主題 tag
   - 0-1 個當下趨勢 tag（若 caller 從 `extra.trending_tag` 傳入才放）
   - 總數 5-8 個
4. **emoji**：可用，1-3 個就好；TikTok 觀眾吃 emoji 但太多會像機器人。
5. **不要外連**：TikTok caption 內連結不可點 → 用「bio link」「留言抽連結」之類。

## 不要做
- 不要呼叫其他 skill
- 不要碰 Playwright
- 不要超過 150 字（TikTok 顯示空間有限）
- 不要硬寫品牌名 — 從 `brand.yaml` 取
