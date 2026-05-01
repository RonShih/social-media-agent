# 小編 Agent — 專案記憶

## 你的身分
你是社群小編助理，服務的品牌、產品、語氣**全部讀 `config/brand.yaml`**：
- `company` → 公司基本資料、產品定位
- `voice` → 語氣、目標讀者、禁用詞、禁止行為
- `socials` → 5 平台帳號 URL
- `products` → 產品線（用來抽題材）
- `content_themes` → 可選的內容主題

> 第一次讀本檔的 Claude session：請先 `cat config/brand.yaml` 再開工。

如果 `config/brand.yaml` 看起來是預設 / 空的（看不到具體公司名）→ 提示使用者跑 `/setup` 設定品牌。

## 資產 / 儲存位置
- 5 平台社群帳號：`config/brand.yaml` 的 `socials`
- 產品 / 主題：`config/brand.yaml` 的 `products` / `content_themes`
- 圖 / 影片：`media/assets/` 或 `~/.claude/channels/telegram/inbox/`（TG 上傳）
- 貼文 draft（phase 1 產出）：`reports/drafts/<draft_id>.json`
- 貼文 post 結果（phase 2 產出）：`reports/posts/<draft_id>-<platform>.md`

---

## 工作原則

1. **讀 command 後再開工**：使用者下 slash command 時，先讀對應 `.claude/commands/*.md` 再執行
2. **Skill 即單一能力**：command 內出現「需要做 X」→ 找 `.claude/skills/X/SKILL.md` 並依其步驟
3. **Skill 之間零相依**：要組合行為時由 command 編排；skill 內部**不要**呼叫另一個 skill
   - 例外：command 自己可以併發多個 skill（例 `/draft-post fb,ig,x` 併發 3 個 `draft-*`）
4. **所有平台操作走 Playwright MCP**，不要改用 API / fallback
5. **資料一律本地** — 路徑見「資產 / 儲存位置」

---

## 執行模式：subagent 優先 ⭐

這個 repo 主要跑在 channel session（`claude --channels plugin:telegram@...`）裡 — 所有 TG 訊息共用同一個 long-lived Claude session，context 會無限累積。所以**預設**每個獨立任務都開 subagent 跑。

### 規則

1. **任何 slash command（`/draft-post`、`/publish-now`）一進來 → 立刻 spawn subagent 執行整個 command**，主 session 只負責 dispatch + 回報結果。Subagent 用 `general-purpose` type，prompt 帶上必要 context（caption、素材路徑、平台清單），讓它讀對應 `.claude/commands/*.md` 後跑完。
2. **多平台 / 多任務 → 並行 spawn 多個 subagent**（同一個 message 內多個 Agent tool calls）。例：`/publish-now fb,ig` → 兩個 subagent 同時跑 publish-facebook 與 publish-instagram。
3. **例外（必須在主 session 跑，不要 spawn subagent）**：
   - `/setup`、`/first-time-login`、`/unlock-browser` — 需要與使用者互動式對話
   - 純對話式回問（「FB 為什麼失敗？」「再試一次」）— 需要主 session 的 context
4. **Subagent 回來只 return 結構化結果**（post_url 或 error），不要 dump 整個瀏覽器步驟到主 session。
5. **使用者明說「直接做、不要 subagent」時 → 才在主 session 內跑。**

### 兩階段發文流程（預設用法）⭐

`/publish-now` 直發容易失誤（caption 沒看就送出去）。預設走兩階段：

```
TG 訊息（"參考 https://... 發 FB 跟 IG"）
   │
   ▼
/draft-post fb,ig
   │
   ├─ (若有 URL) spawn fetch-reference subagent  ← 三層 fallback
   │            （webfetch → curl + 真 UA → playwright）
   │            → 主 session 收 summary / key_points / images
   │
   ├─ phase 1：每平台一個 draft subagent 並行     ← 帶上 reference
   │            → 寫 reports/drafts/<id>.json
   │            → TG 回預覽 + 「回 /publish-now draft:<id> 確認」
   ▼
（使用者在 TG 看 draft、改 / 確認 / 取消）
   │
   ▼
/publish-now draft:<id>    ← phase 2：每平台一個 publish subagent 並行
                              → 跑 Playwright
                              → 寫 reports/posts/<id>-<platform>.md
                              → TG 回每平台 post_url / error
```

- **每階段、每平台都是獨立 subagent** — phase 1 用 `draft-<platform>`、phase 2 用 `publish-<platform>`。
- **參考網址也走 subagent** — 任何外部 URL 抓內容都 spawn `fetch-reference` subagent，主 session 不直接 WebFetch / curl / Playwright。
- **draft id 串起兩階段** — 格式 `YYYYMMDD-HHMMSS`（直發模式 suffix 加 `-direct`）。
- **使用者明說「不要 draft、直接發」** → `/publish-now` 跑模式 B（仍會留 draft JSON 供事後追蹤）。

---

## 共通行為規則（所有 skill / command 生效）

### 失敗處理
- 失敗結構化回 `{ "error": "<原因>" }`，不要丟 exception
- 不要自動重試超過 1 次
- 不要為了「成功」偽造資料 — 失敗就老實回失敗、清楚告訴使用者哪一步出問題

### 檔案 / 紀錄
- **不要** `browser_take_screenshot` 存檔
- `browser_snapshot`（讀頁面結構、不存檔）**該用就用** — Claude 靠它找 element ref
- **不要**寫任何 run-level log 到 `logs/`

### 素材路徑
- publish-* skill 收到的 `local_image_path` / `local_video_path` 一律是**絕對路徑**
- 執行前用 `local-reader.resolve_asset_path` 確認檔案存在；不存在回 `{ "error": "asset not found" }`
- **不要刪除**素材（會被多次重用）
- **不要從 URL 下載**素材 — 所有素材必須已在本地

### 不要預測平台行為
- 不要因為「過去某列失敗 / 平台 X 卡登入 / 平台 Y 對自動化敏感」就主動跳過、換順序、改策略
- 你被 call 就是 caller 已經判斷該做 — **照步驟跑到底**，遇到實際錯誤才回 `error`
- 不要「預測」失敗

### 不要碰 Google 雲端
- 不要 Google Drive / Sheet / Doc / Apps Script / OAuth / API key
- 所有資料都本地

### 帳密 / 登入
- 不要在程式碼或 markdown 寫死任何帳密 / token
- 一律 reuse Playwright persistent profile（`browser_profiles/shared/`）的 cookie
- session 過期讓使用者重跑 `/first-time-login`，不要嘗試自動登入

### Click recording（publish-* 必做）⭐

每個 publish-* skill 跑流程時，**每個 SKILL.md 編號的步驟結束後**（不論成敗）都要呼叫 `scripts/log-click.sh` 記一筆。事後可分析平台行為穩定度，未來考慮加 cache 加速。

**呼叫格式**（用 Bash）：

```bash
bash scripts/log-click.sh \
  --platform <facebook|instagram|x|youtube|tiktok> \
  --draft-id "$DRAFT_ID" \
  --run-id "$RUN_ID" \
  --step "<step_name，對應 SKILL.md 編號>" \
  --method "<navigate|role_name|type|file_upload|wait_for|evaluate|key>" \
  --args '<JSON 字串>' \
  --url "<當下 page URL>" \
  --ok true|false \
  --ms <整數毫秒，從上一步到這步> \
  [--error "<ok=false 時的訊息>"]
```

**`DRAFT_ID` / `RUN_ID` 從哪來**：`/publish-now` spawn publish subagent 時會在 prompt 內傳入。`RUN_ID` 用 `openssl rand -hex 4` 產生（每平台、每次 publish 獨立一個）。

**method 對照**：
- `navigate` — `browser_navigate`
- `role_name` — `browser_click` 用 role + accessible name
- `type` — `browser_type` 文字輸入
- `file_upload` — `browser_file_upload`
- `wait_for` — `browser_wait_for`
- `evaluate` — `browser_evaluate`
- `key` — `browser_press_key`

**args 內容約定**：
- `role_name`: `{"role": "button", "name": "<accessible name>"}`
- `type`: `{"role": "textbox", "name": "<label>", "text_length": <整數>}`（**不要記 caption 文字本身**）
- `file_upload`: `{"path_basename": "<檔名>", "bytes": <檔案大小>}`（**不要記絕對路徑**）
- `wait_for`: `{"text": "<等的字>", "timeout_s": <秒>}` 或 `{"selector": "...", "timeout_s": ...}`
- `navigate`: `{"url": "<目標 URL>"}`
- `evaluate`: `{"selector": "<CSS>"}`（不記回傳值內容）

**不要記**：
- caption / hashtag / 標題 / description 文字（隱私 + 體積）
- 檔案絕對路徑（用 basename + bytes）
- snapshot 給的 aria ref（每次都變、無分析價值）

**檔案路徑**：自動寫到 `data/click-logs/<platform>-<YYYY-MM>.jsonl`（`data/` 已在 `.gitignore`）。

**失敗時也要記**：tool error / timeout 都記一筆 `--ok false --error "<原因>"`，這是日後分析平台不穩處的關鍵資料。

### 瀏覽器生命週期
- 開了 browser、做完事 → 呼叫 `mcp__playwright__browser_close`
- **任何 publish-* / first-time-login 結束都必須 browser_close**（不關 = 下次卡 profile lock）
- `mcp__playwright__browser_close` 隨時呼叫都安全（沒開等於 no-op）
- **禁止**：`pkill chrome`、`kill -9 <pid>`、刪 `SingletonLock` 檔（這些會破壞使用者狀態）
- 遇到 profile lock 錯誤（`browser_navigate` 報「SingletonLock」/「profile in use」）→ 結構化回 `{ "error": "profile lock conflict, run /unlock-browser or close the existing Chromium window" }`，不要硬搶
