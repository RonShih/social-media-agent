---
description: Phase 1 — 替指定平台起草貼文供使用者確認，**不發文**。每平台一個 subagent 並行。
argument-hint: "[platforms（逗號分隔，例 fb,ig,x）] [其他指示如 theme / image_path / extra]"
---

兩階段發文流程的 **phase 1**。為每個指定平台 spawn 一個 draft subagent 起草，回 TG 給使用者看。
使用者確認後再用 `/publish-now draft:<id>` 觸發 phase 2 真正發文。

## 步驟

1. **解析意圖** — 從以下湊出 platforms / product_id / theme / language / 素材路徑 / 參考網址 / extra：
   - 指令參數（`fb,ig,x` 等）
   - TG 訊息文字 + 上傳素材（路徑通常 `~/.claude/channels/telegram/inbox/<id>.{jpg,mp4}`）
   - **TG 訊息中的 URL** — 任何 `https?://...` 都視為「參考連結」，需要先抓內容
   - `config/brand.yaml.products` / `content_themes` — 從中挑最符合使用者意圖的 `product_id` 與 `theme`
   - 之前對話的上下文

2. **生成 draft id**：`YYYYMMDD-HHMMSS`（用 `date +%Y%m%d-%H%M%S`）。整批 draft 共用一個 id。

3. **若有參考網址 → 先 spawn 一個 reference subagent**（在 platform draft subagents **之前**）：
   - subagent type = `general-purpose`
   - prompt：「請讀 `.claude/skills/fetch-reference/SKILL.md` 後對 `<url>` 跑三層 fallback 抓主文，purpose 設為 `<從 TG 訊息推得的用途，例：要做 X/IG 發文，請保留產品賣點與圖片描述>`，依 SKILL.md 的 output schema 回 JSON。」
   - subagent 回 JSON 後**主 session 接住**，把 `summary` + `key_points` + `images` 收進變數 `reference`
   - 多個 URL → 平行 spawn 多個 reference subagent（同訊息多個 Agent calls）
   - reference subagent 失敗 → TG 回「無法取得 <url>，請使用者改貼文字 / 換連結 / 確認是否要繼續無參考發文」，**先停**，等使用者決定（不要默默繼續用空參考發）

4. **平行 spawn 一個 subagent / 平台**（同一個 message 內多個 Agent tool calls）：

   | platform | subagent 用 skill | 必填 input |
   |---|---|---|
   | `facebook` | `draft-facebook` | product_id + theme + language + local_image_path |
   | `instagram` | `draft-instagram` | product_id + theme + language + local_image_path |
   | `x` | `draft-x` | product_id + theme + language + local_image_path（選填） |
   | `youtube` | `draft-youtube` | product_id + theme + language + local_video_path + format |
   | `tiktok` | `draft-tiktok` | product_id + theme + language + local_video_path |

   每個 subagent 的 prompt **必含**：
   - 「請讀 `.claude/skills/draft-<platform>/SKILL.md` 後依其 input/output 規格產出 JSON」
   - 該平台的 input 值
   - 若有 reference：把 step 3 收到的 `reference` 物件以 `extra.reference = {...}` 整段帶進去（draft subagent 自己決定要怎麼吸收 summary / key_points 進 caption）
   - 「**不要**呼叫 publish-* / fetch-reference / 開瀏覽器 / 寫檔案；只回 JSON 結構」

5. **彙整 + 寫檔**（主 session 自己做，不要再 spawn subagent）：
   - 把每個 subagent 回來的 JSON 合併成
     ```json
     {
       "draft_id": "<id>",
       "created_at": "<ISO timestamp>",
       "references": [ <reference_subagent_output>, ... ],
       "drafts": [ <draft1>, <draft2>, ... ],
       "errors": [ { "platform": "...", "error": "..." } ]
     }
     ```
   - Write 到 `reports/drafts/<draft_id>.json`

6. **回 TG 確認介面** — 用 telegram reply 一次回完所有 platform：
   ```
   📝 Draft <draft_id>
   參考來源：<url1>（via <fetched_via>）  ← 有 reference 才出現
                <url2>（via <fetched_via>）

   [facebook]
   <caption + hashtags 預覽>

   [instagram]
   <...>

   ---
   ✅ 全部 OK：回「/publish-now draft:<draft_id>」
   ✏️ 想改某平台：回「改 fb: <新內容>」我會重抓
   ❌ 不要了：回「取消 <draft_id>」我會刪檔
   ```

7. **保留素材路徑** — `local_image_path` / `local_video_path` 已經寫進 draft JSON；phase 2 直接讀，使用者中間不必重傳。

## 失敗處理
- 任一平台 subagent 回 `error` → 寫進 `errors` 欄位、其他平台正常彙整、TG 回報哪個失敗
- 全部失敗也要把 `reports/drafts/<id>.json` 寫出來（裡面只有 errors）— 方便 debug

## 驗收
- [ ] `reports/drafts/<draft_id>.json` 已寫
- [ ] TG 收到一則訊息含所有平台 draft 預覽 + 確認指令
- [ ] **完全沒有開瀏覽器**（draft 階段純 LLM）

## 不要做
- 不要呼叫 publish-* skill
- 不要在主 session 直接 `WebFetch` / `curl` / 開 Playwright 抓參考網址 — 一律 spawn `fetch-reference` subagent
- 不要把多平台 draft 寫成多個檔案 — 一個 draft id 一個 JSON
- 不要在主 session 跑 drafting — 一定 spawn subagent，就算只有一個平台
- 沒抓到參考網址內容時不要用「網址 + 標題」自己腦補 — 直接停下來問使用者
