# Social Media Agent

通用社群小編 agent — Claude Code + Playwright MCP + Telegram。任何品牌都能快速套用。

對 TG bot 下指令、或在 Claude Code 對話打 slash command，由 Claude 開真瀏覽器發文到 5 平台（FB / IG / X / YouTube / TikTok）。品牌設定 / 產品 / 語氣 / 熱點關鍵字集中在 `config/brand.yaml`，**跑 `/setup` 對話式建立**，不用手寫 yaml。

## 設計

- 不接平台官方 API：發文 / 上片 / 抓數據都靠 Playwright MCP 操作真瀏覽器
- 儲存全部本地：素材 `media/assets/`、週報 `reports/`、stats `data/stats-history.json`
- 執行入口 = 7 個 slash command + 21 個 skill，全部用 markdown 編排（沒有 build step）

## 快速開始

1. **TG bot** — 照 https://code.claude.com/docs/en/channels 設定
2. **Claude** — `cp .claude/settings.example.json .claude/settings.json`，把 `<ABSOLUTE_PATH_TO_REPO>` 換成此 repo 絕對路徑
3. **品牌 + 登入** — repo 內跑 `claude`，依序 `/setup` → `/first-time-login`
4. **上線** — `claude --channels plugin:telegram@claude-plugins-official`，對 TG bot 講話

完整步驟見 [`docs/HOW_TO_USE.md`](./docs/HOW_TO_USE.md)。

## 目錄結構

```
social-media-agent/
├── CLAUDE.md                   # 身分、共通行為規則（client-agnostic）
├── README.md
├── .gitignore
│
├── .claude/
│   ├── settings.example.json   # ✅ commit；MCP + permissions 範本
│   ├── settings.json           # 🔒 gitignored；每台機器自己一份
│   ├── commands/               # 7 個 slash command
│   └── skills/                 # 21 個 skill（SKILL.md）
│
├── config/
│   ├── brand.example.yaml      # ✅ commit；換客戶範本
│   ├── brand.yaml              # 🔒 gitignored；/setup 自動產生
│   └── secrets.yaml            # 🔒 gitignored；保留 placeholder
│
├── media/assets/               # 🟡 gitignored；圖 / 影素材
├── reports/                    # 週報 markdown 寫入處
├── browser_profiles/           # 🔒 gitignored；Chromium 登入狀態
│
└── docs/
    ├── HOW_TO_USE.md           # 使用手冊
    ├── SYSTEM_CHANGES.md       # 系統層級設定 / 換機器 checklist
    └── WARNINGS.md             # 已知問題 / 限制
```

## 換客戶 / 重用

- 換品牌 → 跑 `/setup` 重新對話式生成 `brand.yaml`
- 換素材 → 把新檔丟進 `media/assets/`
- 平台 UI 改版 → 改對應 `.claude/skills/publish-*/SKILL.md`
- Agent 行為規則 → `CLAUDE.md`（一般不用動）

## License

MIT
