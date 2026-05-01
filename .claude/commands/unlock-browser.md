---
description: 解開 Chromium profile lock（卡住無法跑 publish-* 時用）
---

當 publish-* 報 `profile lock conflict` 時，跑這條命令排除。

## 流程

1. 呼叫 `mcp__playwright__browser_close`（會關掉 Playwright 自己管的 Chromium，安全）
2. 等 1 秒讓 Chromium 完全退出 + 釋放 lock
3. 檢查還有沒有手動開的 Chromium 視窗：
   ```bash
   pgrep -af "Chromium.*browser_profiles"
   ```
4. **若還有進程**：列出 PID + 命令給使用者看，**問使用者要不要殺**：
   - 「找到一個進程 PID=12345 在用 browser_profiles，是你手動開的嗎？」
   - 等使用者回 `yes / kill it` → 才 `kill <pid>`
   - 回 `no` 或不確定 → 停下、不殺
5. **若沒進程**但 lock 還在：lock 檔可能孤兒了
   - 顯示 `ls -la browser_profiles/shared/SingletonLock` 給使用者看
   - 問：「沒看到佔用進程，但 lock 檔還在。要不要刪？」
   - 等使用者回 `yes` → 才 `rm browser_profiles/shared/SingletonLock`
   - 回 `no` → 停下

## 不要做

- 不要不問使用者就殺 process / 刪 lock — 可能毀使用者正在做的事
- 不要把 user-data-dir 換到別的地方繞過（會讓 cookies 都不見）
- 不要 retry 超過一次 — 一次跑不過就請使用者人工排除

## 為什麼分兩種情境

- **有進程**：可能是使用者自己開的 Chromium（debug、看 FB），不要亂殺
- **無進程但有 lock**：上次 Chromium crash 沒清乾淨、孤兒 lock 檔，刪掉是安全的
