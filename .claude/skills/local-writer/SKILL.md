---
name: local-writer
description: 把產生的圖 / 影片素材存進 media/assets/。
---

## save_asset

**用途**：把 image-generator 產生的圖（或其他素材）放進 `media/assets/`，供之後 publish-* 用。

**Input**：
- `name`：檔名（例如 `md905-epr.jpg`、`pd-tester/generated/20260501-1430.jpg`）
- 來源：`base64` 或 `source_url`（任一）

**實作**：
- base64 → `echo <base64> | base64 -D > media/assets/<name>`
- URL → `curl -sL -o media/assets/<name> <url>`
- 必要時自動 `mkdir -p` 父目錄

**回傳**：`{ "path": "media/assets/<name>" }`

## 失敗處理

- 磁碟不足 → 回 `{ "error": "disk full" }`
- 來源 URL 抓不到 → 回 `{ "error": "source_url fetch failed: <code>" }`
- 不丟例外，結構化回傳
