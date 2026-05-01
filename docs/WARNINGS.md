# 已知問題（Warnings）

記錄目前專案的問題、限制、踩過的坑。新發現一條就 append 一條。

---

## 1. TG bot 會一直沿用對話 context

**症狀**：用 `claude --channels plugin:telegram@claude-plugins-official` 啟動後，所有 TG 訊息都進**同一個 Claude session**，對話 context 持續累積。

**影響**：

- 對話越長 → 每次回應 token 越貴
- 舊對話會影響新指令的判斷（例：上次 FB 失敗 → 這次可能被「預測」會失敗）
- Auto-compact 觸發後可能丟失你以為還在的 state

**解法**：

- `/clear` — 在 Claude session 內清對話歷史（保留 session）
- Ctrl+C → 重啟 `claude --channels ...` — 完全重置

**狀態**：by design（Channels 就是同 session 累積，要靠人手動清）。

---

## 2. Chromium profile lock 衝突

**症狀**：跑 `/publish-now`（或任何 publish-*）時，Playwright 啟動 Chromium 失敗，錯誤訊息含 `SingletonLock` 或 `profile in use`。

**影響**：

- publish-* 全部失敗、無法發文
- 通常發生在前一輪 Chromium 沒乾淨關閉的情況

**常見原因**：

- 跑 `/first-time-login` 後 Chromium 視窗沒關
- 上一個 Claude session crash 留下孤兒進程
- 你手動開了一個 Chromium 指到同個 `browser_profiles/`（少見）

**解法**：

1. 跑 `/unlock-browser` 命令 — 會：
   - 先試 `mcp__playwright__browser_close`（軟性關 Playwright 自己管的）
   - 還沒解開就找實際進程、問你要不要殺
   - 若是孤兒 lock 檔（沒進程但 lock 還在），問你要不要刪
2. 或手動：
   - macOS Activity Monitor 找 Chromium 進程關掉
   - 或 `pkill -f "Chromium.*browser_profiles"`（**確認沒在做別的事再殺**）

**狀態**：架構限制（Chromium 一個 profile 只能被一個進程用）。`/first-time-login` 結尾已強制 `browser_close`，正常使用不會卡。

---

## 3. 一台電腦跑多個 agent（多帳號 / 多品牌）

**症狀**：想在同一台電腦同時管兩個社群帳號（例：個人 + 公司、不同品牌），各自有獨立 cookies、TG bot、發文流程。

**會撞的點**：
- Chromium SingletonLock — 兩個 agent 共用同一個 `browser_profiles/` 會卡
- `claude mcp add playwright -s user` 同名會互相覆蓋 — 一台電腦只能有一個叫 `playwright` 的 user-level MCP
- 同一個 TG bot token 被兩個 Claude session polling 會搶訊息

**設置方式**（要做才能避免撞）：

1. **兩個 repo clone**，各自獨立 `browser_profiles/`：
   ```
   agent-A/browser_profiles/    ← 帳號 A cookies
   agent-B/browser_profiles/    ← 帳號 B cookies
   ```

2. **兩個 Playwright MCP 用不同名稱**（user-level 都註冊）：
   ```bash
   claude mcp add playwright-A -s user -- \
     npx @playwright/mcp@latest --user-data-dir /Users/ron/.../agent-A/browser_profiles
   claude mcp add playwright-B -s user -- \
     npx @playwright/mcp@latest --user-data-dir /Users/ron/.../agent-B/browser_profiles
   ```

3. **兩個 TG bot token**（@BotFather 各申請一個）

4. **兩個 channel session 各別在不同終端機**：
   ```bash
   # 終端機 A
   cd agent-A && claude --channels plugin:telegram-A@claude-plugins-official
   # 終端機 B
   cd agent-B && claude --channels plugin:telegram-B@claude-plugins-official
   ```

5. **每個 agent 的 SKILL.md 要寫明用哪個 MCP 前綴**：
   - agent-A 的 publish-* 用 `mcp__playwright-A__browser_navigate`
   - agent-B 用 `mcp__playwright-B__*`

**替代設置（簡單但不能同時跑）**：
- 一份 user-level settings + 啟動腳本切換 `~/.claude/settings.json`
- 一次只能服務一個 agent

**狀態**：架構限制（Playwright + Chromium + Channels 都是 process-level 隔離）。如果你只有一個帳號，可忽略本條。

---

## 4. TG bot 在群組裡要靠 @ tag 才會收到訊息

**症狀**：bot 加進 TG 群組後，群裡聊天 bot 不一定會收到、Claude 也沒反應。

**原因**：Telegram bot 預設 **Privacy Mode = ON**，群組裡 bot 只能看到：

- 直接 `@your_bot` 提到 bot 的訊息
- `/command` 開頭的 slash command
- 回覆 bot 自己訊息的 reply
- service messages（成員加入等）

**這正是想要的行為**（多人群組中，大家自由聊天、bot 安靜，只有真的 @ 才反應）。

**確認設定**：BotFather 打 `/setprivacy` → 選你的 bot → 應顯示 `Status: ENABLED`（新建 bot 預設就是這樣）。

**多 bot 同群組時**：用 `/publish-now@your_main_bot`（換成實際 bot username）指定特定 bot；只打 `/publish-now` 會所有 bot 都收到。

**DM 不受影響**：私聊 bot 不管 Privacy Mode、bot 全看。

**狀態**：by design（Telegram 設計）。

---

## 5. 缺乏程式化、速度可能慢

**症狀**：用 TG 對 bot 下指令發文，從訊息到平台貼文發出常要 30 秒至 2 分鐘以上（依平台 / 任務複雜度）。

**原因**：每個動作都走 Claude（LLM）→ Playwright MCP → Chromium，LLM 在迴圈裡反覆讀頁面、找 element、決定下一步。每個 action 都要 round-trip。

對比純程式化（pre-built handler）：

- 沒有 LLM 在迴圈中（直接 hardcoded selector + click）
- 沒有「每次 browser_snapshot 讀整頁結構」的成本
- Sessions 持久化、可批次操作

**對你的影響**：

- 一篇 IG 貼文走完 ~30-60 秒；長片 YT 上傳 5-15 分（含 YT 處理時間）
- 大量發文場景（例：一次發 50 篇）會非常慢
- 每次都吃 LLM token，成本高於程式化

**解法 / 未來方向**：

如果未來大量發文成為瓶頸，可參考程式化做法，例如 [adolfousier/socialcrabs](https://github.com/adolfousier/socialcrabs) — Playwright + Stealth Mode，用 TypeScript 寫死各平台 handler、沒 LLM in the loop、有 rate-limit 控制 + session 持久化。

混合架構：
- 一般使用：Claude + Playwright MCP（彈性高、易調整）
- 大量 / 重複任務：呼叫 socialcrabs 之類的程式化 service（速度快）

**狀態**：架構選擇。目前單篇互動式發文堪用，未來若上量需重新評估。

---
