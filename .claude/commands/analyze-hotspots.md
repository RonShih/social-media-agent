---
description: 併發爬 5 平台熱點，依品牌相關性過濾、輸出建議清單
argument-hint: "[top_n 預設讀 brand.yaml hotspot.default_top_n]"
---

## 流程

1. **讀 `config/brand.yaml`** 的 `hotspot` 區塊取得：
   - `hard_keywords`（硬相關，命中 +10）
   - `soft_keywords`（軟相關，命中 +5）
   - `cross_platform_bonus`（跨平台加分）
   - `default_top_n`（預設輸出筆數）

2. **併發**呼叫 5 個 skill：
   - `fetch-trends-x`
   - `fetch-trends-youtube`
   - `fetch-trends-tiktok`
   - `fetch-trends-instagram`
   - `fetch-trends-facebook`

3. 合併所有 trends，為每項算分數：
   - 命中任一 `hard_keywords` → `+10`
   - 命中任一 `soft_keywords` → `+5`
   - 同主題 ≥ 2 平台都看到 → `+cross_platform_bonus`

4. 依分數降序取 top_n（如果使用者沒給就用 `default_top_n`），輸出 Markdown 表：

   ```
   | 分數 | 主題 | 來源平台 | 建議切入角度 |
   | 18 | iPhone 17 電池 | X + YT | 用 PD 測試儀實測 iPhone 17 快充速率 |
   ```

   「建議切入角度」要結合 `brand.yaml.products` 和 `content_themes` 給具體 idea。

5. 純終端輸出給使用者，不寫檔。

## 不要做
- 不要把相關性過濾塞進 `fetch-trends-*` skill — 過濾邏輯集中在這裡
- 不要把 hard / soft keywords 寫死在本檔 — 全部從 `brand.yaml` 讀
- 不要產 caption — caption 是 `content-writer` 的事
- 不要快取；每次跑都抓即時資料
