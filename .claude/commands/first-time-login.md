---
description: 首次部署：引導使用者人工登入 5 個社群平台一次，登入態持久化在 ./browser_profiles
---

依下列順序執行，每個平台都「打開頁面 → 等使用者回 `ok` → 下一個」：

1. Facebook — `https://www.facebook.com/`
2. Instagram — `https://www.instagram.com/`
3. TikTok — `https://www.tiktok.com/login`
4. YouTube Studio — `https://studio.youtube.com/`
5. X — `https://x.com/login`

## 流程

1. 用 `mcp__playwright__browser_navigate` 開第一個平台
2. 顯示訊息：「請在瀏覽器手動登入 [平台名]，登入完成後在此回覆 `ok` 我會繼續下一個」
3. 等使用者回覆 `ok` → 進下一個平台
4. 5 個都完成後 → **`mcp__playwright__browser_close` 關掉視窗**
5. 告訴使用者：登入態已存到 `./browser_profiles`，**Chromium 已關**，之後 publish-* 可正常運作

## 為什麼結尾一定要 `browser_close`

Chromium 一個 profile 同時只能被一個進程使用。若 first-time-login 結束後視窗還開著，下次跑 publish-* 會卡 profile lock。**結尾關視窗是強制條件、不可省略**。
