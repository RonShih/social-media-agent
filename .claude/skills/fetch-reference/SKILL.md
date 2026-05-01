---
name: fetch-reference
description: 取一個外部網址的主文內容（標題 / 正文 / 重點）給 draft-* skill 參考。內建多層 fallback 對抗反爬。
---

> 共通規則見 `CLAUDE.md`。本 skill 專責「把網址變成可用文字」，**不負責**起草貼文。

## Input
- `url`：要參考的網址（單一）
- `purpose`：caller 用途說明（讓 LLM 摘要時知道要保留什麼，例：「要做 IG 發文，請保留產品賣點與圖片描述」）

## Output（JSON）
```json
{
  "url": "...",
  "title": "...",
  "main_text": "正文純文字（已去廣告 / nav / footer）",
  "summary": "依 purpose 摘要的 3-8 句重點",
  "key_points": ["...", "..."],
  "images": ["https://...absolute-url..."],
  "fetched_via": "webfetch | curl | playwright",
  "fetched_at": "<ISO timestamp>"
}
```

失敗：`{ "error": "<原因>", "tried": ["webfetch", "curl", "playwright"] }`

## 取得策略（**依序嘗試，前一層失敗才換下一層**）

### Layer 1 — `WebFetch`
- 直接呼叫 `WebFetch(url, prompt="抽出 title / main text / image URLs，回 JSON")`
- 視為失敗的訊號：
  - tool 回 error / timeout
  - 回傳內容明顯是登入牆 / paywall / Cloudflare 挑戰頁（出現「Just a moment」「Verify you are human」「請登入」）
  - `main_text` < 100 字（多半是被擋）

### Layer 2 — `curl` 帶真實瀏覽器 header
失敗才跑這層。用 Bash：

```bash
curl -sL --max-time 30 \
  -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" \
  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
  -H "Accept-Language: zh-TW,zh;q=0.9,en;q=0.8" \
  -H "Accept-Encoding: gzip, deflate, br" \
  -H "Sec-Fetch-Dest: document" \
  -H "Sec-Fetch-Mode: navigate" \
  -H "Sec-Fetch-Site: none" \
  -H "Upgrade-Insecure-Requests: 1" \
  --compressed \
  "$URL" -o /tmp/fetch-ref-$$.html
```

- 然後 `Read /tmp/fetch-ref-$$.html` 把 HTML 拿進來（截最前 200KB 即可）
- LLM 自行解析 `<title>`、`<meta property="og:*">`、`<article>` / `<main>` / 最大 `<div>` 文字
- 解析完 `rm /tmp/fetch-ref-$$.html`
- 失敗訊號同 Layer 1（登入牆 / 挑戰頁 / 字數過少）

### Layer 3 — Playwright（最後手段）
仍失敗才用。**這層會開瀏覽器、慢、必須收尾**：

1. `mcp__playwright__browser_navigate` → `url`
2. `mcp__playwright__browser_wait_for({ time: 2 })` 讓 JS 渲染
3. `mcp__playwright__browser_snapshot` 拿頁面結構
4. （可選）若 snapshot 看起來主文還沒出現，`browser_evaluate` 跑：
   ```js
   () => {
     const a = document.querySelector('article, main, [role=main]') || document.body;
     return {
       title: document.title,
       text: a.innerText.slice(0, 20000),
       images: [...document.querySelectorAll('img')].map(i => i.src).filter(Boolean).slice(0, 20)
     };
   }
   ```
5. **無論成敗**：呼叫 `mcp__playwright__browser_close`（與本檔 caller 約定 — 收尾義務在這個 skill）

## LLM 摘要階段
拿到 `main_text` 後，依 `purpose` 摘要：
- 抽 3-8 條 `key_points`
- 寫一段 ≤ 200 字的 `summary`
- `images` 過濾掉明顯的 logo / icon（`<100x100`、檔名含 `logo`/`icon`/`avatar`），只保留與內容相關的

## 失敗處理
- 三層全失敗 → 回 `{ "error": "...", "tried": [...] }`，**不要編造內容**
- 明顯是 paywall / 需登入 → 即使內容極少也直接回 `{ "error": "paywall or login required", "tried": [...] }`，不要硬塞 metadata 當主文
- 涉及版權 / 付費內容（NYT / 學術期刊）→ 即使能繞，也只取 abstract / 開頭，回 caller 「請使用者確認版權」

## 不要做
- 不要呼叫其他 skill（draft-* / publish-* 都不行）
- 不要把抓回的內容寫到 repo 任何檔案 — 只回 JSON 給 caller
- 不要對同一個 URL 試超過上述三層 — 三層都不行就老實說
- 不要為了「不被擋」用任何違反 robots.txt 或刻意偽造 referer 的方式去撞付費 / 登入牆
- 不要忘了 Layer 3 結束時 `browser_close`
- 不要在 Layer 2 用 `curl` 卻沒帶 UA + Accept-Language（會被一律擋掉）
