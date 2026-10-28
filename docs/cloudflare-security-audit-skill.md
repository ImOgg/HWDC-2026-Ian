# Cloudflare security-audit-skill 分析筆記

整理日期：2026-10-28（Asia/Taipei）  
來源：原對話〈分析 Cloudflare Skill〉，並核對 Cloudflare 官方儲存庫與 Claude Code Skills 文件。  
文件性質：工具介紹與導入評估；本次未安裝 Skill、執行驗證腳本或對任何專案進行資安審計。官方 `main` 分支會持續更新，使用前應再確認版本。

## 1. 用途與定位

**security-audit-skill 是一套由 AI 程式開發代理執行的多階段資安審計工作流程。**它透過分工搜尋、獨立驗證、覆蓋紀錄與結構化報告，協助找出真正跨越信任邊界的漏洞，並提出最小有效修正建議。

它可用於原始碼可見的應用程式、API、服務、CLI、函式庫及常駐程式；不是僅限 Cloudflare 平台，也不是針對 Laravel、ASP.NET Core 或 Vue 的固定規則掃描器。官方說明指出，這是 Cloudflare 漏洞探索系統演進前的單一儲存庫起點，不能等同其後來完整的內部系統。專案採 MIT 授權。[官方專案](https://github.com/cloudflare/security-audit-skill)、[授權](https://github.com/cloudflare/security-audit-skill/blob/main/LICENSE)

核心價值是把「可疑程式碼」與「有證據的漏洞」區分開來。審計需說明低信任來源、輸入、原本的防護、跨越的邊界、受影響對象及實際結果；缺少最佳實務或第二道防線，本身不一定構成漏洞。流程會建議修正，但不修改受審專案原始碼。[核心規則](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/SKILL.md)

## 2. 六階段流程

| 階段 | 工作內容 | 主要目的／產出 |
| --- | --- | --- |
| 1. Reconnaissance：前期盤點 | 理解架構、輸入面、資料流、信任邊界、建置方式與歷次證據，規劃可追蹤的檢查單位。 | `architecture.md`、`coverage-ledger.json`。 |
| 2. Coverage-led Hunting：依覆蓋計畫搜尋 | 將檢查單位交給隔離的 hunter；由 coverage critic 檢視遺漏與分工缺口。 | 候選問題、實際檢查紀錄及尚未涵蓋範圍。 |
| 3. Candidate Validation：獨立驗證候選 | 依根因與 fingerprint 去重，交給沒有發現該問題的新 verifier，主動嘗試推翻假設。 | 確認、待驗證或排除的判定。 |
| 4. Structured Output：結構化輸出 | 將通過候選驗證的紀錄寫入 `findings.json`，檢查格式及覆蓋紀錄一致性。 | JSON 紀錄與驗證結果。 |
| 5. Independent Record Verification：獨立覆核最終紀錄 | 新的 verifier 重新核對原始碼位置、條件、重現方式、實際影響與修正建議；重大改判須再次獨立覆核。 | 可作為最終報告依據的紀錄。 |
| 6. Target-neutral Reporting：依目標介面產生報告 | 從最終紀錄與覆蓋清單產生報告，清楚揭露未完成與排除範圍。 | `REPORT.md`、`FINDINGS-DETAIL.md`、`NEEDS-VALIDATION.md`。 |

「依目標介面」代表不強迫所有問題都使用 HTTP 重現：函式庫可用函式呼叫，CLI 可用命令，解析器可用測試檔案，基礎設施可用本機產生的政策設定。`quick` 模式會合併第 3、5 階段的覆核工作，詳見後文。[流程與驗證規則](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/VALIDATION-AND-REPORTING.md)

### 三種判定必須分開

| 判定 | 意義 | 嚴重度 |
| --- | --- | --- |
| `confirmed` | 完整原始碼追蹤及受限的本機觀察結果，足以證明具體邊界失效。 | 可以評級；整體嚴重度不得高於已證實的影響。 |
| `needs_validation` | 有原始碼依據，但仍缺少一項決定性的執行、部署、身分或平台事實；須寫明阻礙及安全驗證計畫。 | 不得標示嚴重度。 |
| `rejected` | 原始碼、防護措施、本機結果或不成立的前提已推翻候選。 | 不作為漏洞呈現。 |

`needs_validation` 不能用來收納純猜測。若只是預算不足、根本還沒完成候選驗證，應保留在 coverage ledger，標示此次執行未完成，不能直接塞進 `findings.json`。

兩個 Node.js 工具 `validate-findings.cjs` 與 `validate-coverage-ledger.cjs` 負責格式與紀錄一致性驗證；**工具通過不等於漏洞成立，也不代表專案安全。**[判定與報告規則](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/VALIDATION-AND-REPORTING.md)

## 3. 涵蓋的資安範圍

以下是可選用的檢查方向；是否適用，需先由架構與輸入面決定，不代表每次執行都會涵蓋全部項目。

| 類別 | 代表性檢查方向 |
| --- | --- |
| 注入與資源處理 | SQL／命令／樣板注入、路徑穿越、SSRF、不安全反序列化、解壓縮與檔案操作競態。 |
| 存取控制與業務邏輯 | 認證與授權落差、跨使用者資料存取、批次操作權限、流程跳步、重播、重複扣款或審批。 |
| 密碼學與機敏資訊 | 隨機值、金鑰衍生、完整性驗證、nonce／IV 使用，以及日誌或錯誤訊息洩漏。 |
| Web／HTTP／身分協定 | HTTP framing、快取、session、CSRF、JWT、OAuth／OIDC、SAML、MFA、帳號復原。 |
| 前端與瀏覽器 | DOM XSS、跨視窗訊息來源信任、UI redress、prototype pollution、瀏覽器儲存與 webview。 |
| AI／LLM／Agent | Prompt injection、記憶或檢索內容污染、工具呼叫授權、MCP 身分與模型輸出處理。 |
| 供應鏈與發版 | 相依套件來源、CI、簽章、發版與更新、外掛及擴充套件。 |
| 雲端與部署 | IAM、基礎設施即程式碼、容器／Kubernetes、serverless、入口與執行設定。 |
| 協定、RPC 與訊息 | 序列化、gRPC、訊息佇列、broker、webhook、串流傳輸。 |
| 資料隔離與生命週期 | 多租戶隔離、快取與搜尋、匯出／備份、遷移、刪除與還原。 |
| 記憶體、原生與系統程式 | 記憶體安全、整數／ABI、並行、binary loader、核心與高權限介面。 |
| 桌面、行動與本機 IPC | Deep link、webview bridge、匯出元件、輔助程式、daemon 與本機通訊邊界。 |
| 可用性與成本 | CPU、記憶體、磁碟、連線、worker、佇列、配額與營運費用濫用。 |

來源：[攻擊類別與領域文件索引](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/ATTACK-CLASSES.md)。

## 4. Claude Code 安裝與使用

### 前置條件

- 已可正常使用 Claude Code，且使用的模型與執行環境支援工具呼叫及平行子代理。
- 已安裝 Node.js；安裝方式使用 `npx`，審計產物驗證器也使用 Node.js。
- 若要執行受審專案程式碼，另須具備符合第 6 節全部限制的作業系統層級沙箱。

### 安裝指令

在 PowerShell 中，於要使用 Skill 的專案目錄執行以下單行指令，並依安裝器提示選擇 Claude Code：

```powershell
npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit
```

若希望安裝到使用者層級，供多個專案使用，改用：

```powershell
npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global
```

兩者擇一即可。需要指定 agent 或非互動選項時，先查看 CLI 說明：

```powershell
npx skills --help
```

以上是官方 README 安裝指令的 PowerShell 單行寫法；本筆記沒有實際執行安裝。[官方安裝說明](https://github.com/cloudflare/security-audit-skill#installation)

### 在 Claude Code 中呼叫

開啟受審專案的 Claude Code 工作階段後，可輸入：

```text
security audit this codebase
```

Claude Code 也支援透過 `/skill-name` 明確呼叫 Skill，因此安裝並載入成功後，可使用 `/security-audit` 搭配需求。若選單未出現，先確認安裝器選取的 agent 與安裝範圍。Claude Code 原生專案級 Skills 位置為 `.claude/skills/`，個人級位置為 `~/.claude/skills/`；實際安裝器可能透過連結配置檔案。[Claude Code Skills 文件](https://code.claude.com/docs/en/skills)

建議在第一次使用時明確限制範圍與模式，例如：

```text
請使用 security-audit 的 Guidance mode，針對目前專案的認證、授權與租戶隔離流程進行原始碼檢視，使用繁體中文回答。
不要建立審計報告檔案；不要執行目標程式碼。缺少的執行或部署事實請明確列出。
```

確認環境與成本後，再要求完整流程，例如：

```text
請使用 security-audit 的 Full audit mode，以 standard profile 審計目前專案，報告使用繁體中文。
開始前請列出範圍、預估 agent 呼叫數與沙箱能力。
維持原始碼唯讀，輸出使用預設的專案外目錄。
只有在符合 Skill 全部隔離要求時才執行受限的本機驗證；缺少能力時列為待驗證阻礙。
```

這些是使用需求範例，並非本次已執行的動作。安裝階段可能需要網路；審計時禁止的是目標受控程式對外連線及下載相依套件，兩者應分開處理。[執行安全規則](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/SKILL.md)

## 5. Guidance 與 Full Audit

| 項目 | Guidance mode | Full audit mode |
| --- | --- | --- |
| 適用需求 | 資安問答、方法討論、聚焦檢視、特定漏洞調查。 | 明確要求程式庫審計、滲透測試、完整審查，或要求審計報告產物。 |
| 執行方式 | 只使用相關段落，不自動展開六階段。 | 執行完整工作流程，依 profile 調整廣度與重複覆核。 |
| 檔案產物 | 不因載入 Skill 就自動建目錄或寫報告。 | 產生 metadata、架構、覆蓋清單、JSON 與 Markdown 報告。 |
| 安全要求 | 仍須遵守相同執行隔離限制。 | 同樣須遵守，並落實各 agent 的寫入隔離。 |

Full Audit 預設輸出到 `~/security-audit-skill/<repo-name>/run-<N>`。只有使用者明確指定，而且版本控制已忽略整個輸出目錄時，才可寫進受審專案。**本筆記放在 `docs/` 是知識整理，不是啟動該 Skill 所產生的審計報告。**[模式及輸出規則](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/SKILL.md)

### Full Audit 的三種 profile

| Profile | 執行差異 | 適合情況 |
| --- | --- | --- |
| `quick` | 一輪 hunter、一輪最後覆蓋檢視；每個候選由一位新的獨立 verifier 同時負責候選與最終紀錄檢查。新發現的後續搜尋工作延後處理。 | 小範圍、重跑、第一次快速掌握問題；必須標示部分覆蓋。 |
| `standard` | 預設流程；候選驗證與最終紀錄覆核分開進行。 | 一般正式評估。 |
| `deep` | 更細分子系統及生命週期、反覆檢視覆蓋缺口，對部分既有同版本覆蓋單位再做獨立檢查。 | 大型或高風險目標，且有足夠成本預算。 |

也可指定 scoped run，只審查某些路徑、子系統、領域或版本差異；範圍外應標示 `out_of_scope`。profile 調整不降低證據門檻，也不能省略確認漏洞的獨立驗證。預算以跨階段的 agent 呼叫次數管理，不等同固定 Token 費用。[Profile 與預算規則](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/SKILL.md)

## 6. Sandbox 安全限制

**Skill 提供的是執行規範，安裝本身不會建立沙箱。**實際執行環境必須以作業系統機制強制限制目標程式，而不是只在提示詞中要求它不要越界。

執行目標控制的建置、測試、程式、瀏覽器、模擬器、fuzzer 或測試資料處理時，必須同時具備：

1. **網路隔離**：禁止外部網路；本機 client/server 驗證只可使用隔離的 loopback 命名空間。
2. **乾淨環境**：從空白環境變數開始，只加入白名單安全值；HOME、暫存及快取均指向專屬 scratch。
3. **檔案限制**：受審來源與工具鏈唯讀；目標程式只能寫入分配的 `scratch/`。必要時由外部可信任端建立可丟棄的原始碼副本供建置。
4. **資源上限**：明確限制 CPU、記憶體、程序數、單檔大小、磁碟與執行時間。

不得將主機家目錄、憑證、socket、共享服務、其他 agent 目錄或保留成果目錄暴露給目標程式。審計執行期間不得安裝或下載相依套件，只能使用已備妥的本機工具與套件。測試使用虛構帳號、資料與機密值，不接觸正式端點、外部服務、真實使用者資料或付費 API 配額。[完整安全邊界](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/SKILL.md)

各 agent 的 `scratch/` 與保留成果 `artifacts/` 分離。只有可信任的主控端能在沙箱及子程序結束後，將預先允許且大小受限的普通檔案安全移入成果區；過程須防止符號連結、硬連結、路徑穿越及檢查後替換檔案的競態，不能直接遞迴複製整個暫存目錄。Windows 等非 POSIX 平台也必須提供等效的安全操作。[寫入與成果隔離規則](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/SKILL.md)

只要缺少任一必要控制，就不能執行目標程式碼；若影響漏洞判定，需明確列為 `needs_validation` 阻礙。對 Windows 使用者而言，是否使用 WSL、容器或其他隔離工具並非唯一判準，必須逐項確認控制確實存在；本筆記未驗證任何本機環境是否符合要求。

## 7. 優點與限制

以下為依工作流程設計所做的分析判斷，並非本次實測效能。

### 優點

- **降低單一判斷的誤報風險**：發現與驗證由不同 agent 負責，驗證者需尋找能推翻候選的既有防護。
- **結果可追蹤**：原始碼位置、fingerprint、覆蓋單位與結構化判定有助於複核與後續修正。
- **適合需要理解上下文的問題**：授權邊界、租戶隔離及業務流程是值得優先評估的方向。
- **清楚揭露未知事項**：把待驗證、排除、延後與範圍外分開，避免把推測寫成已確認漏洞。
- **支援累積式檢查**：可參考前次覆蓋缺口與證據，並在來源變更後重新驗證。[歷次紀錄規則](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/SKILL.md)

### 缺點與限制

- **模型與時間成本可能高**：搜尋、critic、候選驗證、最終覆核都會增加呼叫量；重大改判可能再增加獨立覆核。
- **品質仍受模型影響**：不同 agent 並不保證沒有共同盲點，框架機制、部署控制與跨服務流程仍可能被誤解。
- **執行環境要求高**：沙箱與安全成果移轉需要平台實際支援，不能因為有 Skill 就視為已落實。
- **覆蓋不是完整性的保證**：官方 README 表示，其測試中的單次執行約只發現多次累積結果的一半；這是作者測試觀察，不是對所有專案的固定檢出率承諾。[官方設計原則](https://github.com/cloudflare/security-audit-skill#design-principles)
- **部署事實可能不可得**：外部 IAM、proxy 或真實執行狀態不在原始碼內時，只能交由系統擁有人安全確認。
- **不宜取代其他安全機制**：導入時仍應搭配人工審查、SAST、相依套件分析（SCA）、機敏資訊掃描及經授權的滲透測試；這是本筆記的實務建議。

## 8. 建議使用情境

| 情境 | 建議方式 |
| --- | --- |
| 想了解某段程式的安全性 | Guidance mode，先釐清信任邊界及缺少的事實。 |
| 第一次導入 | 選熟悉、範圍小的非正式專案副本，以 scoped／quick 試行，記錄誤報、成本與覆蓋缺口。 |
| Laravel／ASP.NET Core API／Vue 專案 | 優先聚焦授權、跨使用者資料存取、租戶隔離、token 生命週期、前端信任邊界；這些是評估方向，不是效果保證。 |
| 上線前重要功能評估 | 明確設定範圍與預算，使用 standard，並由熟悉業務規則的人員複核。 |
| 高風險或大型系統 | 分階段設定範圍，有足夠資源時採 deep，保留可追蹤的歷次紀錄。 |
| 沒有合格沙箱 | 維持原始碼檢視，列出待驗證阻礙，不執行目標程式碼。 |

導入時可先回答三個問題：它是否找到人工確認有價值的問題？每個有效發現花費多少時間與模型成本？報告是否如實交代未檢查與無法驗證的範圍？再據此決定是否擴大使用。

## 9. 參考連結

- [Cloudflare security-audit-skill 儲存庫與 README](https://github.com/cloudflare/security-audit-skill)
- [SKILL.md：模式、執行安全、profile、預算及流程](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/SKILL.md)
- [RECONNAISSANCE.md：前期盤點](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/RECONNAISSANCE.md)
- [HUNTING.md：搜尋與覆蓋檢視](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/HUNTING.md)
- [ATTACK-CLASSES.md：攻擊類別與領域指引](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/ATTACK-CLASSES.md)
- [VALIDATION-AND-REPORTING.md：獨立驗證與報告](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/VALIDATION-AND-REPORTING.md)
- [report-schema.json：結果格式](https://github.com/cloudflare/security-audit-skill/blob/main/skills/security-audit/report-schema.json)
- [Claude Code：Skills 官方文件](https://code.claude.com/docs/en/skills)
- [Cloudflare：Build your own vulnerability harness（延伸閱讀）](https://blog.cloudflare.com/build-your-own-vulnerability-harness/)
- [MIT License](https://github.com/cloudflare/security-audit-skill/blob/main/LICENSE)

本筆記未實測安裝、模型成本、漏洞檢出率或沙箱實作，也未完成該 Skill 驗證器的程式碼安全稽核。使用前應重新核對官方版本與實際執行環境。
