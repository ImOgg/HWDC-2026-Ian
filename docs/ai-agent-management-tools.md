# Herdr、Orca、magpie 與 model-relay 比較

核實日期：2026-10-28（Asia/Taipei）  
用途：延續「比較兩個 Repo」討論，協助選擇 Windows 本機的 AI Coding Agent 管理與模型路由工具。

## 1. 先看結論

這四個工具處理兩個不同層級的問題：

- **Herdr、Orca：管理在哪裡執行 Agent，以及如何查看、切換與恢復工作。** Herdr 以真實終端機、分割窗格及背景 Session 為中心；Orca 以 Worktree、Agent、編輯器與 Diff 整合為中心。
- **magpie、model-relay：管理 Agent 的模型請求送往哪裡。** magpie 面向多種 Agent、供應商與帳號；model-relay 專注 Claude Code 的每個對話／視窗、Subagent 路由與額度失敗備援。

如果只是想同時管理原本已登入的 Claude Code、Codex、OpenCode，先選 **Herdr 或 Orca 其中一套**即可。有跨供應商模型切換需求，再考慮 magpie；只有 Claude Code 需要細緻分流，再研究 model-relay。這是依功能定位提出的搭配建議，**不是已完成整合測試的保證**。[H1][O1][M1][R1]

**最重要的權限發現：本次檢查的 Orca 原始碼，新設定預設為 `full-access`，其 Claude Code 啟動參數對應 `--dangerously-skip-permissions`。** 這點已沿設定值與參數映射核實，詳見第 7 節。[O6][O7][O8]

## 2. 核實範圍與專案識別

| 名稱 | 本文件採用的專案／官方來源 | 核實方式 |
| --- | --- | --- |
| Herdr | [herdrdev/herdr](https://github.com/herdrdev/herdr)、[herdr.dev](https://herdr.dev/) | 現行 README、安裝、Windows、Agent 與 Session 文件 |
| Orca | [stablyai/orca](https://github.com/stablyai/orca)、[onorca.dev](https://www.onorca.dev/) | README、產品文件、權限預設與參數映射原始碼 |
| magpie | [yetone/magpie](https://github.com/yetone/magpie)、[usemagpie.ai](https://usemagpie.ai/) | README、技術參考文件 |
| model-relay | [cablate/model-relay](https://github.com/cablate/model-relay) | README 的功能、版本需求、Windows 測試說明與限制 |

判讀原則：

- 「已確認」表示官方文件或原始碼存在明確證據，不表示已在使用者電腦實際運行。
- 「專案宣稱」用於功能／相容性說明；本次沒有安裝四套工具、登入帳號、發送付費模型請求或做端到端測試。
- 「未確認」表示本次證據不足，不等於該功能一定不存在。
- 文件與預設分支會持續更新。Orca 權限證據固定在提交 `ca2154945b1b968ebac3a652cf281113aa31a427`；其他文件反映查閱當日內容，不保證每個已發布版本都相同。

Herdr 搜尋結果可能仍出現 `SuperCodeAgents/herdr-terminal` 的舊內容。本次由現行官方網站追到 `herdrdev/herdr`，並確認現行文件已列出原生 Windows 正式支援；不能再以舊 README 的 Linux／macOS 限制判斷現況。[H1][H2][H3]

## 3. 功能總表

| 比較項目 | Herdr | Orca | magpie | model-relay |
| --- | --- | --- | --- | --- |
| 主要定位 | 終端機與 Agent 執行工作區 | Worktree 導向的 Agent 開發環境 | 多 Agent 模型設定與本機 Gateway | Claude Code 外掛與本機 Router |
| Claude Code／Codex／OpenCode | 三者皆有支援 | 三者皆列為支援 Agent | 三者皆可設定模型與路由 | 專注 Claude Code；不是 Codex／OpenCode 管理器 |
| 使用真正 CLI | 在真實終端機執行原 CLI | 終端機模式執行原 CLI；另有實驗性原生聊天介面 | 通常修改 Agent 設定並接收 API 請求；Claude 訂閱橋接另會啟動本機 `claude` | 依附已安裝的 Claude Code，透過外掛與 Router 分流 |
| 直接輸入 `claude` | 可，在 Shell Pane 中 | 可，在一般 Terminal／Blank Terminal 中 | 不是通用終端機工作區；應到外部終端機執行 | 先在終端機開 `claude`；進入後使用 `/provider` |
| Agent／Session 管理 | 多工作區、分頁、窗格、狀態偵測、detach／reattach | Worktree 與 Agent 狀態、歷史、恢復；整合編輯與審查 | 有對話用量／成本列表及重新在終端機開啟功能；不是多窗格執行管理器 | 保存路由的 Session 綁定；不是完整程序管理器 |
| Worktree | 可在既有 Worktree 中執行、偵測 Git／Worktree；不要把 Workspace 直接視為 Worktree | 核心功能：建立、切換、審查與清理 | 本次未確認提供 Worktree 生命週期管理 | 非其核心範圍 |
| 跨模型路由／備援 | 主要沿用 CLI／外部路由設定 | 有 Agent 自身的模型選擇；非通用協定轉換 Gateway | 多供應商、帳號、路由群組、協定轉換與備援 | 每對話分流、模型別名／Subagent 分流、429 備援 |
| 用量／費用 | 不是本次確認的主要功能 | Claude／Codex 等用量、限制與帳號管理 | Token、估算成本、額度、帳號與 Session 統計 | 路由狀態與日誌；不宜稱為完整帳務平台 |
| Windows | 現行官方文件列為正式支援，仍有限制 | 提供 Windows 安裝版 | 官方列 Windows，含視窗／TUI／Web／CLI 等介面 | README 列 Windows 11＋Node.js 22＋Git Bash／PowerShell 為已測試 |

來源：Herdr [H1]–[H6]；Orca [O1]–[O5]；magpie [M1][M2]；model-relay [R1]。

## 4. 「可以在裡面下 claude 嗎？」

### Herdr：可以，操作的是 Shell

啟動 Herdr 後，選一個 Shell Pane，輸入 `claude`、`codex` 或 `opencode`，就會啟動該環境中的 CLI。Herdr 保留 Agent 原本的終端機介面，並偵測其工作／等待狀態。也可使用 `herdr agent start` 在既有 Shell Pane 啟動指定 Agent；這與在聊天輸入框輸入文字不同。[H4][H5]

### Orca：可以手動啟動，也可以選 Agent

在一般 Terminal 中輸入 `claude` 可啟動 CLI；從 Agent 選單選 Claude Code 時，Orca 會替你啟動，工作目錄對應當前 Worktree。官方說明要求先安裝 Claude Code 並登入，Orca 會使用既有本機設定。[O2]

Orca 另外提供實驗性 **Chat UI／native chat**，支援部分 Agent 的結構化聊天與對話恢復。因此「Orca 只有 Terminal」並不完整。但聊天輸入框仍不是任意 Shell：要執行 `claude` 指令，應使用 Terminal；已有聊天則直接輸入任務。[O3]

### magpie：設定模型，不應把其 TUI 當成 Shell

magpie 的桌面、Web、TUI 與 CLI 主要操作供應商、模型、帳號與路由。文件中的 `magpie claude <provider/model>` 是替 Claude Code 選模型的操作，不能單憑命令名稱就認為它是終端機管理器。模型設定完成後，依文件開啟新的 Agent Session。[M1]

例外要分清楚：**magpie 使用 Claude 訂閱作為上游時，會驅動真正的本機 `claude`，並透過 MCP 橋接呼叫端工具。** 這是 Gateway 的訂閱橋接實作，不等於 magpie 提供 Herdr 式的 Shell Pane。[M1][M2]

### model-relay：在 Claude Code 裡輸入 `/provider`

model-relay 不是另一套終端機。使用者先啟動 Claude Code，安裝與設定外掛後，在 Claude Code 輸入 `/provider` 開啟切換面板，或 `/provider <名稱>` 切換當前對話的供應商。[R1]

**共同前提：** 所在執行環境必須找得到 CLI，且能讀取適用的登入／設定。Windows 原生與 WSL 有不同的可執行檔路徑、家目錄與設定位置；不能因為 Windows 已登入，就假設 WSL 中也已登入。

## 5. Session 與 Worktree 的差異

### 執行中的程序、聊天紀錄、路由綁定是三回事

- **Herdr：** detach 後背景 Server 繼續執行，原本的 CLI 程序可持續運作；Server 或電腦重啟後，原程序不會存活。恢復版面與透過 Agent 的 resume 機制恢復對話，是另外的能力。[H1][H6]
- **Orca：** 管理工作區、Agent 與歷史對話；結構化 Chat UI 可保存並恢復對話。不能把畫面或對話恢復，推論成任意背景程序在重開機後仍原地運行。[O3]
- **magpie：** Sessions 頁面可列出對話、成本與標題，並重新在終端機開啟；重點仍是用量及模型設定。[M1]
- **model-relay：** Session pinning 是「此對話的請求繼續送給哪個供應商」。README 說明其綁定可維持 7 天；429 冷卻預設 10 分鐘後，新 Session 可再次探測 Claude，已綁定的 Session 仍使用備援。這些不是程序續跑功能。[R1]

### Worktree 能分開程式碼，但不能當成資安隔離

Orca 以獨立 Worktree／分支承載平行任務，整合 Diff 與清理。Herdr 的 Workspace 是版面與工作容器，可指向既有 Worktree；本次不把兩者視為等價，也不宣稱 Herdr 已有與 Orca 相同的建立／合併／清理流程。[H3][H7][O4]

Worktree 仍可能共享使用者權限、家目錄、憑證、網路及某些目錄。Orca 官方文件還提供共享目錄與 `.worktreeinclude` 複製機制；若納入 `.env` 等機敏檔，可能增加資料副本及 Agent 可讀範圍。**不同 Worktree 不等於不同沙箱、容器或作業系統帳號。**[O4]

## 6. 模型路由、登入與訂閱

### 路由能力

**magpie** 的預設本機 Gateway 為 `127.0.0.1:3425`，文件列出 OpenAI Chat、Responses、Anthropic Messages、Gemini 協定轉換。可設定路由群組與多帳號備援；若只有一個帳號、沒有可用備援成員，錯誤仍會傳給 Agent。用量成本是依模型價格等資料計算的統計，不宜直接當成供應商最終帳單。[M1]

**model-relay** 的預設 Router 為 `127.0.0.1:8950`，重點包括當前對話切換、模型別名與 Subagent 分流、429 備援。上游必須提供 Anthropic 相容的 `/v1/messages`；只有 OpenAI Chat Completions 的服務，需要另外的轉換層。不能把它描述為已內建所有協定轉換的通用 Gateway。[R1]

Herdr／Orca 能啟動 Agent、選取 Agent 支援的模型，不代表它們因此具有 magpie 等級的跨協定路由能力。[H1][O3]

### 原生 CLI 登入與第三方橋接要分開判斷

| 情境 | 判讀 |
| --- | --- |
| Herdr／Orca 啟動原本的 Claude Code | 若 CLI 使用原訂閱登入，且環境與設定未改成其他驗證來源，仍走該 CLI 的登入與額度規則 |
| Codex CLI 登入 | 官方支援 ChatGPT 訂閱登入或 API Key；API Key 走用量計費，不是扣同一份訂閱額度 |
| OpenCode | 依 provider 設定與 `/connect` 管理憑證；其支援的帳號／訂閱方式須看個別 provider，不能套用 Claude Code 的登入邏輯 |
| magpie 匯入已登入帳號 | 專案可讀取 CLI 登入檔或系統憑證來源，並把部分訂閱供其他 Agent 使用；這比單純啟動 CLI 多了一層憑證與請求處理 |
| model-relay 切到備援 | Claude 路徑與備援 provider 是不同帳務來源；備援通常需要自己的有效憑證／服務額度 |

來源：Claude Code [C1]；Codex [C2]；OpenCode [C3]；magpie [M1][M2]；model-relay [R1]。

Claude Code 官方列出 Pro／Max、組織方案、Console 與雲端 provider 等驗證路徑。環境中的 API Key／Token 及管理政策可能改變實際採用來源，所以「曾登入訂閱」不足以證明每次請求都扣訂閱；應檢查 CLI 當前狀態。[C1]

**訂閱不是通用 API 點數。** magpie 或其他工具宣稱可以橋接訂閱，僅能證明該專案提供此技術路徑，不能據此認定所有供應商已授權任意第三方使用，或公司政策允許。本文未逐條審閱供應商合約，也未驗證各帳號的可用權益；企業採用前應確認授權、資料處理與組織限制。

「多帳號輪替」也不會消除供應商本身的額度或政策；它只是在已配置且可用的帳號／模型之間選擇。

## 7. 資安與權限：Orca 預設值的核實

### 原始碼證據鏈

檢查提交：[`ca2154945b1b968ebac3a652cf281113aa31a427`](https://github.com/stablyai/orca/commit/ca2154945b1b968ebac3a652cf281113aa31a427)。

| 證據 | 觀察到的設定／映射 | 意義 |
| --- | --- | --- |
| `default-global-settings.ts` | `agentPermissionDefault: 'full-access'` | 新設定的 Agent 預設權限為 full-access |
| `tui-agent-permission-choice.ts` | `'full-access': YOLO_TUI_AGENT_ARGS` | full-access 使用 Yolo 啟動參數集合 |
| `tui-agent-permissions.ts` | `claude: '--dangerously-skip-permissions'` | Claude Code 的 Yolo 參數跳過權限確認 |
| 同一參數集合 | `codex: '--dangerously-bypass-approvals-and-sandbox'` | 此模式對 Codex 也涉及略過批准與沙箱 |

以上三份檔案已在固定提交重新讀取並比對。[O6][O7][O8]

**核實結論：** 原討論指出「Orca 預設以 `--dangerously-skip-permissions` 啟動 Claude Code」有原始碼依據；更精確的說法是：本次檢查的版本，新設定預設 full-access，經參數映射後會得到該旗標。既有使用者設定、自訂命令／參數、版本差異及手動啟動方式可能改變結果，不能推論所有 Orca Session 都一定使用它。

### 建議怎麼調整

1. 安裝後先檢查 **Settings → Agents → Agent permissions**。官方文件列 Manual／Auto／Yolo；一般工作優先採需使用者確認的模式。
2. 若版本介面採用較新的 **Ask／Full access／Use agent settings** 等命名，重點是確認實際權限與啟動參數。原始碼中的 Claude `ask` 對應 `--permission-mode default`；`own` 不加權限旗標，沿用 Agent 自己設定，並不自動保證其設定安全。[O7]
3. 檢查自訂 Command、Arguments 與個別 Agent 覆寫；只改全域選項不一定能覆蓋自訂權限參數。更改後開新 Session，既有聊天可能維持原模式。[O5]
4. **Auto 不等於 Manual。** 官方將 Auto 描述為讓支援的 Agent 自行核准例行動作；若需要每項敏感操作由人確認，不能只因名稱有 Auto 就視為同等保護。[O5]
5. 官方設定說明另列「Trust the folder when Orca starts an agent」預設開啟。需要保留 CLI 的資料夾信任提示時，應一併檢查此項。[O5]

Manual／Ask 也不代表每個動作都必定跳出提示，仍須配合 CLI 的允許規則與組織政策。不要以 Worktree 分開、視窗分開或聊天介面較友善，取代真正的權限控制。

### 其他三套工具的注意事項

| 工具 | 已有依據的注意事項 | 採用建議 |
| --- | --- | --- |
| Herdr | CLI／Socket 可對 Pane 送輸入、讀輸出；Windows 的高權限 Server 可選擇允許一般權限 Client 控制 | 避免以管理員執行日常 Agent；不要任意開放高權限 Session 控制。預設 `allow_unelevated_clients` 關閉，保持此界線 [H3][H5] |
| Orca | 有帳號管理、遠端／手機控制；發行版有產品使用遙測 | 不需要遠端控制時不必啟用。官方表示產品遙測不傳送程式碼或提示內容，並提供 `DO_NOT_TRACK=1`／`ORCA_TELEMETRY_DISABLED=1`；這項說明不等於模型供應商不會收到提示 [O1][O9] |
| magpie | 可探索既有登入、更新 Agent 設定；隱私遮罩預設關閉；插件中介層可看見／修改請求 | 不需要訂閱探索時，可用 `magpie accounts discovery off` 或單次 `MAGPIE_NO_ACCOUNTS=1`；慎選插件並備份設定。遮罩不是完整 DLP 保證，仍可能漏判或誤判 [M1][M2] |
| model-relay | 會修改 Claude 路由設定，保存綁定與日誌；Remote Control 相容模式涉及本機 HTTPS Proxy 與憑證信任 | 先理解設定變更與復原方式；不要把「localhost」當成資料不外送。請求仍會到設定的上游 [R1] |

model-relay 的 HTTPS Proxy 模式會使用 `HTTPS_PROXY`、`NODE_EXTRA_CA_CERTS` 等設定。專案文件表示 CA 限定 `api.anthropic.com` 且不寫入系統憑證庫；但 Router 停止時，此模式無法像一般 Base URL 模式自動直連。文件也列出目前不支援上游公司 Proxy 的限制，以及既有額外 CA 設定的衝突。企業代理環境應先確認相容性。[R1]

所有工具都應保護登入檔、備份、Shell 歷史與日誌；不要把 API Key／Token 寫入可提交的文件。本次沒有讀取使用者的登入憑證、`appsettings*.json` 或任何模型金鑰。

## 8. Windows 相容性怎麼看

| 工具／執行層 | 官方證據 | 實務限制 |
| --- | --- | --- |
| Herdr | 原生 Windows 正式支援；穩定版提供 x86_64 ZIP 與 ConPTY 執行元件 | 解壓目錄要一起保留，不能只複製 EXE。IME 定位、圖片貼上、游標等仍有局部限制；直接 terminal attach、live server handoff 等不支援，詳見官方清單 [H2][H3] |
| Orca | README 提供 Windows EXE；終端機設定可選 PowerShell、CMD、WSL | 原生與 WSL 執行路徑不同；Chat UI 文件指出 WSL／SSH 仍採終端機支撐的聊天路徑 [O1][O3][O5] |
| magpie | README 與 reference 明列 Windows | 「menu bar」是跨平台產品用語，不應推論 Windows 體驗與 macOS 完全相同。本次未驗證 Windows 封裝、所有帳號探索及 WSL 跨環境連線 [M1][M2] |
| model-relay | 專案列 Windows 11＋Node.js 22＋Git Bash／PowerShell 已測試；最低需求 Node.js 20+、Claude Code 2.1.287+ | 版本要求取自查閱當日 README。這是作者測試聲明，不是本次本機驗證；Claude Code 升級後外掛相容性仍須確認 [R1] |
| Claude Code | 官方支援原生 Windows 與 WSL | 現行文件將 Git for Windows 列為選用：未安裝時使用 PowerShell 工具；Claude Code 的命令沙箱在原生 Windows 不支援，WSL 2 支援。不可與 Codex 的 Windows 沙箱混為一談 [C4] |
| Codex | 官方有原生 Windows 權限／沙箱文件 | 仍受啟動模式與管理政策影響；若外層加入 bypass 旗標，不能只依「Codex 支援沙箱」推論該 Session 有啟用 [C5][O8] |

對 Windows 使用者，應先決定主要工作放在原生 Windows 還是 WSL，再讓 CLI、設定與 Gateway 的執行位置一致。跨環境時需確認路徑、憑證與網路可達性；不能保證每種 WSL 網路模式下的 `127.0.0.1` 都指向另一邊的服務。

## 9. 推薦搭配方式

### A. 只想管理多個 CLI：先用 Herdr

適合喜歡原始終端機介面、分割 Pane、背景持續執行、SSH 與快速查看 Agent 狀態的人。維持 CLI 原生登入與模型設定，先不用 Gateway。若需要平行修改同一 Repo，再另外規劃獨立 Worktree。[H1][H4][H6]

### B. 想整合 Worktree、編輯器與審查：先用 Orca

適合多任務平行開發、頻繁查看 Diff，以及希望在一個桌面介面完成工作的人。第一步先檢查第 7 節的權限預設、資料夾信任與自訂參數，再導入實際專案。[O1][O4][O5]

### C. 多個 Agent 都需要切供應商：Herdr 或 Orca ＋ magpie

由 Herdr／Orca 管工作位置與 Session，magpie 管模型請求。先選一個 Agent、一個 provider 做小規模驗證，再增加路由群組。

要特別驗證：Agent 實際讀取哪份設定、帳號管理是否互相覆寫、Gateway 中斷時的行為、對話恢復後的模型、工具呼叫與用量歸屬。此組合是依架構可互補推導，本次未做整合測試。[H1][O1][M1][M2]

### D. 主要用 Claude Code，只需要單視窗／Subagent 分流：CLI ＋ model-relay

可以直接使用原本終端機，也可以把 CLI 放在 Herdr／Orca Terminal 中。若打算在 Orca 原生 Chat UI 使用 model-relay 的 AbovePrompt 面板，**相容性本次未確認**，不要把 Terminal 路徑的相容性直接套過去。[R1][O3]

### 不建議一開始就同時接 magpie 與 model-relay

兩者都可能影響 Claude Code 的 Base URL、模型與相關設定。重疊設定可能產生雙重備援、請求繞路、統計難以歸屬，甚至錯誤回路。

若確實需要串接，概念上可設計成「Claude Code → model-relay → magpie 的 Anthropic 相容端點 → 上游」，但必須明確指定唯一流向、分工與設定擁有者；這僅是協定能力推導，**不是官方已認證或本次已驗證的組合**。一般先選一套 Router 即可。[M1][R1]

### 配合本次工作規則

Orca 的建立 Worktree、Commit、Push 等是產品能力，不代表使用本文件就授權 Agent 執行。依目前的 AGENTS.md，Codex 僅可執行唯讀 Git；建立／刪除 Worktree、提交及推送等仍應由使用者按既有規則處理。此次整理未執行任何改變 Git 狀態的動作。

## 10. 對原討論的修正與保留

| 原說法／容易誤解的地方 | 本次核實後的表述 |
| --- | --- |
| Herdr 只支援 Linux／macOS，Windows 得用 WSL | 現行官方已提供原生 Windows 正式支援；搜尋可見的舊 Repo 內容不能代表現況 |
| Herdr Workspace 就等於獨立 Worktree | Workspace 是終端機工作容器；程式碼隔離需另確認實際目錄／Worktree |
| Orca 可以在介面下 `claude` | 一般 Terminal 可以；聊天輸入框不是任意 Shell |
| Orca 只是一層 CLI 終端機外殼 | 終端機是主要路徑之一，另有實驗性結構化 Chat UI |
| Orca 預設跳過 Claude 權限 | 本次固定提交的新設定與參數映射確實支持此結論；既有設定與版本可能不同 |
| magpie 完全不管 Session／不會啟動 CLI | 有 Session 統計與重新開啟；Claude 訂閱橋接會驅動本機 `claude`，但不是多窗格執行管理器 |
| 透過管理工具就能沿用訂閱，不會有額外 API 費用 | 只有實際選用訂閱驗證與相應上游時才成立；API Key／備援模型可能另計費 |
| model-relay 支援所有模型 API 格式 | 上游需要 Anthropic Messages 相容端點；其他格式需另加轉換 |
| Session 恢復代表重開機後程序繼續 | 版面、聊天歷史與程序存活是不同概念 |

## 來源索引

以下均為專案自有 Repo／官方文件；來源位置可能隨產品更新而改版。

[H1]: https://github.com/herdrdev/herdr/blob/master/README.md "Herdr 現行 README"
[H2]: https://herdr.dev/docs/install/ "Herdr 安裝與 Windows 發行"
[H3]: https://herdr.dev/docs/windows-beta/ "Herdr Windows 支援與限制；網址保留 beta，頁面已標示正式支援"
[H4]: https://herdr.dev/docs/agents/ "Herdr 支援的 Agent"
[H5]: https://herdr.dev/docs/agent-automation/ "Herdr Agent 與 Pane 操作"
[H6]: https://herdr.dev/docs/session-state/ "Herdr Session 持續執行與恢復"
[H7]: https://herdr.dev/docs/concepts/ "Herdr Workspace、Pane 與 Session 概念"
[O1]: https://github.com/stablyai/orca/blob/main/README.md "Orca 功能與 Windows 發行"
[O2]: https://www.onorca.dev/docs/agents/claude-code "Orca 中的 Claude Code"
[O3]: https://www.onorca.dev/docs/agents/native-chat "Orca 實驗性 Chat UI"
[O4]: https://www.onorca.dev/docs/model/worktrees "Orca Worktree 與共享路徑"
[O5]: https://www.onorca.dev/docs/settings "Orca 設定、權限與信任提示"
[O6]: https://github.com/stablyai/orca/blob/ca2154945b1b968ebac3a652cf281113aa31a427/src/shared/default-global-settings.ts "Orca 固定提交：agentPermissionDefault"
[O7]: https://github.com/stablyai/orca/blob/ca2154945b1b968ebac3a652cf281113aa31a427/src/shared/tui-agent-permission-choice.ts "Orca 固定提交：full-access 與 ask 的參數映射"
[O8]: https://github.com/stablyai/orca/blob/ca2154945b1b968ebac3a652cf281113aa31a427/src/shared/tui-agent-permissions.ts "Orca 固定提交：Claude 與 Codex 的 Yolo 參數"
[O9]: https://www.onorca.dev/docs/telemetry "Orca 隱私與產品遙測"
[M1]: https://github.com/yetone/magpie/blob/main/README.md "magpie 定位、訂閱、路由、遮罩與 Session"
[M2]: https://github.com/yetone/magpie/blob/main/docs/reference.md "magpie 設定與登入橋接參考"
[R1]: https://github.com/cablate/model-relay/blob/main/README.md "model-relay 功能、版本需求、權限、Windows 與 Proxy 限制"
[C1]: https://code.claude.com/docs/en/authentication "Claude Code 官方驗證方式"
[C2]: https://learn.chatgpt.com/docs/auth "OpenAI 官方：訂閱、API Key 與憑證儲存"
[C3]: https://opencode.ai/docs/providers/ "OpenCode 官方：Provider 與憑證"
[C4]: https://code.claude.com/docs/en/setup "Claude Code 官方：Windows、WSL 與沙箱差異"
[C5]: https://learn.chatgpt.com/docs/windows/windows-sandbox "OpenAI 官方：Windows 沙箱"

---

**未檢查與限制：** 本次為官方文件與指定原始碼核實，未進行安裝、效能評測、付費請求、完整資安稽核或四工具交叉整合測試；未變更使用者現有 CLI 設定。  
**主要風險：** Orca 的高權限預設、第三方工具讀取登入憑證、跨上游傳送資料，以及雙重路由設定衝突。實際行為請以所安裝版本、目前設定與帳號政策為準。
