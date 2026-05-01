---
description: 對話式建立 / 修改 config/brand.yaml — 換客戶 / 首次部署用
---

引導使用者填好 `config/brand.yaml`。最終結果是一個完整、可直接使用的 brand.yaml。

## 開始前先讀

- `config/brand.example.yaml`：欄位 schema 與註解
- 現有的 `config/brand.yaml`（若有）：判斷是「全新」還是「修改」

## 流程

### Step 0：偵測現況

讀 `config/brand.yaml`：

1. **若不存在** → 跑 `cp config/brand.example.yaml config/brand.yaml` 起手 → 進 Step 1
2. **若已存在 + 含範本 placeholder（`<...>` 字串還沒填）** → 問使用者：
   ```
   目前 brand.yaml 已有設定（公司：<company.name_zh>），你要：
     A. 從頭重設（清空後重新引導）
     B. 部分修改（指定要改的欄位）
     C. 取消
   ```
3. **若已存在 + 像是真實品牌（不是預設）** → 直接問 B 或 C

### Step 1：對話式收資訊（全新或重設時）

**逐項詢問**，每個都要解釋為什麼問、給範例：

#### 1. 公司
- 「公司中文名 / 英文名（或品牌名）？」
- 「網站 URL？」
- 「主要聯絡 email？」
- 「用一段話描述你的業務（產品 / 服務 / 客群），這會給 AI 寫貼文時當背景」

#### 2. 品牌調性
- 「語氣偏好？例：專業而親切 / 活潑年輕 / 嚴謹學術」
- 「目標客群？（可以多個，例：B2B 採購 / 終端消費者）」
- 「想強調的價值？（例：技術精準度 / 性價比 / 創新）」
- 「有沒有禁用詞？（例：絕對 / 唯一 / 最便宜）」
- 「有沒有禁止行為？（例：競品攻擊、未驗證數據）」

#### 3. 社群帳號（5 平台）
逐個問 FB / IG / X / YT / TikTok 的 URL：
- 「Facebook 粉專或個人 URL？（沒有就 skip）」
- ...
- handle 從 URL 自動 derive、不用問

#### 4. 產品線
「列出主要產品 / 服務（一個一個來，講完打『沒了』結束）：」

對每個產品問：
- name（顯示名稱）
- category（類別）
- selling_points（3-5 個賣點）
- target_audience（這產品的目標客群）

id 由 Claude 從 name slug 自動生成（例：「PD 快充測試儀」→ `pd-tester`）

#### 5. 內容主題
「你的社群會發哪些主題？（建議 4-6 個）」

可預設選項：產品介紹 / 技術知識 / 客戶案例 / 行業新聞 / 教學內容 / 業界觀察 / 真假鑑別 / 用戶見證...

#### 6. 熱點分析關鍵字
基於前面的產品 + 主題，**Claude 自己想 hard / soft keywords**，給使用者確認：

```
我幫你想了熱點分析的關鍵字：

核心領域（命中 +10 分）：
  快充, PD, USB-C, Type-C, 充電, GaN, ...

延伸領域（命中 +5 分）：
  科技, 3C, 電子, 手機, iPhone, Android, ...

要調整嗎？
```

#### 7. IG seed hashtags
基於核心關鍵字產生 5-8 個 IG hashtag，給使用者確認。

### Step 2：寫進 brand.yaml

把收集到的資料寫進 `config/brand.yaml`，**保留原有的 storage 區塊**。

寫完後 `cat` 整個檔給使用者看，問「確認嗎？」

### Step 3：提示下一步

```
✅ brand.yaml 設定完成！

下一步：
  1. 把素材（產品照、影片）放進 media/assets/
  2. 跑 /first-time-login 登入 5 平台社群帳號（用你新設的帳號）
  3. 啟動 bot：claude --channels plugin:telegram@claude-plugins-official
```

## 不要做

- 不要修改 `media/`、`browser_profiles/`、`.claude/` 任何東西
- 不要主動跑 `/first-time-login`（讓使用者自己跑）
- 不要為了「填滿欄位」編造資訊 — 缺值就 skip 該欄
- 不要假設使用者會 yaml — 全程對話、不要叫他們手動編輯
