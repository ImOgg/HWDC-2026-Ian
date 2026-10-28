# pstack-claude 用途、工作流程與導入評估

核實日期：2026-10-28（Asia/Taipei）  
專案：[michael-denyer/pstack-claude](https://github.com/michael-denyer/pstack-claude)  
查閱版本：marketplace 標示 `0.9.107`；查閱時 `main` 為 [`e2cbd491f94ee4ece30e028b9ff69a8b418d1723`](https://github.com/michael-denyer/pstack-claude/commit/e2cbd491f94ee4ece30e028b9ff69a8b418d1723)。  
文件性質：工具介紹與導入評估。已核對官方 README、參考文件、部分 Skill、Hook 與 Claude Code 官方文件；未安裝外掛、執行其腳本或進行完整資安審計。文件與版本需求可能持續變動。

## 1. 用途與定位

**pstack-claude 是一套擴充 AI 程式開發代理工作方式的 Skills、流程範本、子代理設定與 Hook。** 使用者提出任務後，由 `poteto-mode` 選擇適合的流程，要求代理先理解問題、設計最小修改，再實作、審查與提出驗證證據。[專案 README](https://github.com/michael-denyer/pstack-claude/blob/main/README.md)

它源自 Lauren Tan 的 Cursor pstack，由 Michael Denyer 移植並維護。除了 Claude Code，repo 也提供其他代理執行環境的整合或共用 Skills；不同環境的工具、模型、Hook 與實測程度有差異。專案採 MIT 授權，另保留匯入內容的授權與歸屬聲明。[來源與移植範圍](https://github.com/michael-denyer/pstack-claude/blob/main/docs/reference.md#port-scope-and-attribution)

它適合解決這些問題：

- 代理尚未理解現有程式，就開始修改。
- 修正只有「看起來合理」，沒有重現、根因與修復後證據。
- 任務跨越多個模組，需要設計比較、分工及整合審查。
- 長任務缺少工作紀錄、進度與交接方式。
- 團隊想把驗證方法與反覆發生的錯誤，整理成可重用的規則。

這可視為 Harness Engineering 的實作案例：把工作方法、工具、權限與驗證步驟納入代理的執行環境。這是依其結構做出的歸納；Skills 仍是提供給模型的指令，不能單獨保證代理遵循每一步、產出沒有漏洞，或形成作業系統層級的隔離。

## 2. 核心工作流程

### 2.1 任務如何進入流程

Claude Code 外掛透過 `SessionStart` Hook，在啟動、恢復、清除與壓縮對話時加入路由指引。涉及多檔案、對外函式簽章、架構選擇、未知根因的 Bug 或效能問題時，指引會要求使用 `poteto-mode`；小任務可直接處理。也可由使用者明確呼叫 Skill。[自動路由說明](https://github.com/michael-denyer/pstack-claude/blob/main/docs/reference.md#automatic-routing)、[Hook 設定](https://github.com/michael-denyer/pstack-claude/blob/main/plugins/pstack/hooks/hooks.json)

```text
提出目標與限制
    ↓
poteto-mode 選擇流程範本
    ↓
理解現況／重現問題／蒐集證據
    ↓
必要時進行架構設計、方案比較與分工
    ↓
實作最小變更
    ↓
審查、執行適當驗證、彙整結果
    ↓
依使用者授權決定是否進入 PR 或交付流程
```

以上最後一步加入了本機使用規則的授權界線。原專案部分流程會接續 Git 與 PR 操作，不能直接套用至只允許唯讀 Git 的工作環境。

### 2.2 以「切換分頁後搜尋條件消失」為例

| 階段 | pstack 的工作重點 | 應取得的證據 |
| --- | --- | --- |
| 重現 | 在發生問題的實際介面重現，不只猜測程式碼。 | 觸發步驟、原本預期與實際結果。 |
| 找根因 | 用 `how` 理解資料流、用 `why` 查歷史與設計脈絡，再逐一排除假設。 | 哪個狀態或資料傳遞機制讓條件遺失。 |
| 規劃 | 若修改跨越函式邊界，先使用 `architect`。 | 修改範圍、呼叫端影響與驗證方式。 |
| 實作 | 由範圍明確的子代理處理修改，主代理負責整合。 | 可檢閱的程式差異。 |
| 驗證 | 在相同介面重跑原本失敗案例。 | 修復前失敗、修復後通過的結果。 |
| 交付 | 說明問題、根因、修改與證據；原流程也包含測試先於修復的提交安排及建立 PR。 | 在本機規則下，Git 與驗證操作改由使用者執行。 |

來源：[Bug fix 流程](https://github.com/michael-denyer/pstack-claude/blob/main/plugins/pstack/skills/poteto-mode/playbooks/bug-fix.md)。這是流程設計，並非本次實際修復案例。若未獲准執行測試，就應明確標示「尚未驗證」，不能把閱讀程式碼當成測試通過。

其他範本涵蓋功能開發、重構、效能改善、唯讀調查、原型、多階段計畫、PR 維護與交接。大型任務另有自訂流程與長期協調機制；不必為小問題啟用所有流程。[流程清單](https://github.com/michael-denyer/pstack-claude/blob/main/plugins/pstack/skills/poteto-mode/SKILL.md#playbooks)

## 3. 主要 Skills

查閱時參考文件列出 **43 個公開 Skills 與 24 個 `principle-*` 原則參考目錄，共 67 個目錄**。下表是主要入口，並非完整清單。Claude Code 使用 `/pstack:<名稱>`；參考文件中省略前綴的 `/how` 等名稱，不能直接當成 Claude Code 的完整指令。[完整指令表](https://github.com/michael-denyer/pstack-claude/blob/main/docs/reference.md#slash-commands)

| Skill | 主要用途 | 使用時機 |
| --- | --- | --- |
| `poteto-mode` | 選擇流程、協調分工與驗證。 | 非簡單任務的主要入口。 |
| `how` | 釐清子系統如何運作。 | 修改前理解資料流、依賴與行為。 |
| `why` | 蒐集設計與歷史脈絡。 | 追查回歸或了解既有設計原因。 |
| `architect` | 決定型別、模組與介面形狀。 | 修改跨越函式邊界。 |
| `arena` | 平行嘗試同一任務，再選取較好的方案或部分成果。 | 存在值得比較的實作選項。 |
| `swarm` | 將工作切成多個範圍平行處理，再彙整報告。 | 大範圍探索、分工與驗證。 |
| `interrogate` | 以多模型對變更提出反例與質疑。 | 重要差異或有爭議的設計。 |
| `tdd` | 先建立失敗測試，再修復。 | 有便宜、明確本機測試路徑的 Bug。 |
| `blast-radius` | 查變更對差異範圍以外的影響，並用執行證據確認。 | 共用程式、介面或跨模組修改。 |
| `create-verification-skill` | 產生專案專用驗證 Skill 與功能對照。 | 把人工操作與驗證方法留下來重用。 |
| `create-formal-verification-skill` | 選擇一項高風險性質，建立可重跑的形式化驗證。 | 並行、狀態轉換與重要不變條件。 |
| `thermos` | 同時執行正確性／資安審查與嚴格可維護性審查。 | 需要較深入的變更審查。 |
| `unslop` | 移除文字中的 AI 套語與空泛表達。 | 文件、說明與回覆潤飾。 |
| `deslop` | 清理變更中的多餘註解、規避型別檢查及不符既有風格的程式。 | 提交前整理差異；應保持行為不變。 |
| `setup-pstack` | 選擇各角色模型、推理強度與是否自動路由。 | 初次導入或調整成本與流程。 |
| `poteto-help` | 回答 pstack 用法並指出對應來源。 | 不確定應呼叫哪個 Skill。 |

**與先前對話的修正：** `unslop` 主要處理文字，程式碼清理由 `deslop` 負責。兩者不是同一個 Skill。[unslop](https://github.com/michael-denyer/pstack-claude/blob/main/plugins/pstack/skills/unslop/SKILL.md)、[deslop](https://github.com/michael-denyer/pstack-claude/blob/main/plugins/pstack/skills/deslop/SKILL.md)

形式化驗證的結論只涵蓋選定性質、模型與假設，不能擴大為整套系統正確。README 另介紹獨立的 `agent-formal-verify` 外掛，可深入 TLA+、Lean 與 Rust Kani；不能把該外掛全部能力都算成安裝 pstack 後自動具備。[形式化驗證說明](https://github.com/michael-denyer/pstack-claude/blob/main/README.md)

## 4. Claude Code 安裝與使用

以下均為供使用者自行執行的步驟。本次整理沒有安裝或變更 Claude Code 設定。

### 4.1 前置條件與 Windows 注意事項

目前 pstack README 要求 **Claude Code 2.1.292 或更新版本**。先確認已安裝並完成帳號登入。若尚未安裝，Windows 可依官方文件使用 WinGet；安裝後開啟新的終端機。[pstack 版本需求](https://github.com/michael-denyer/pstack-claude/blob/main/README.md#install)、[Claude Code 安裝文件](https://code.claude.com/docs/en/setup)

```powershell
winget install Anthropic.ClaudeCode
claude --version
```

已安裝者不必重裝。WinGet 安裝的版本可由使用者執行 `winget upgrade Anthropic.ClaudeCode` 更新。

Claude Code 本身可在原生 Windows 執行，沒有 Git for Windows 時可使用 PowerShell 工具；但本次看到的 **pstack Claude Hook 仍是 POSIX `session-start.sh`**。因此不應由「Claude Code 可用 PowerShell」推論「pstack 的所有腳本都不需要 Bash」。導入原生 Windows 時應確認 Git Bash／`sh` 與腳本工具可用；也可使用完整的 WSL 環境。本次未測試這兩種環境的端到端相容性。[Claude Code Windows 說明](https://code.claude.com/docs/en/setup#set-up-on-windows)、[pstack Hook](https://github.com/michael-denyer/pstack-claude/blob/main/plugins/pstack/hooks/session-start.sh)

### 4.2 安裝 pstack 外掛

在 PowerShell 進入預定使用的專案並啟動 Claude Code：

```powershell
Set-Location -LiteralPath "C:\Users\User\Desktop\HWDC-2026"
claude
```

接著在 **Claude Code 對話輸入框**執行：

```text
/plugin marketplace add michael-denyer/pstack-claude
/plugin install pstack@pstack-claude
```

`pstack-claude` 是 marketplace 名稱，`pstack` 是外掛名稱。依當前 Claude Code 官方說明，對話中的安裝指令會開啟外掛詳細面板，再由使用者選範圍與完成安裝。初次試用可選只在目前 repo 對自己生效的 Local 範圍；User 範圍會套用到本機所有專案，Project 範圍則會寫入專案共用設定。[外掛安裝與範圍](https://code.claude.com/docs/en/discover-plugins)

完成後從 `/plugin` 檢查是否啟用，並確認可找到 `/pstack:poteto-mode`。若未出現，先檢查版本、外掛狀態與載入錯誤，再依介面提示重載或開啟新 Session。

### 4.3 設定模型與自動路由

在 Claude Code 輸入：

```text
/pstack:setup-pstack
```

此 Skill 會確認可用模型、各角色模型與推理強度，並設定自動路由。模型清單依實際帳號及執行環境為準，不宜直接照抄其他環境的模型名稱。[setup-pstack](https://github.com/michael-denyer/pstack-claude/blob/main/plugins/pstack/skills/setup-pstack/SKILL.md)

Claude Code 的模型覆寫表預設位於 `~/.claude/pstack-models.md`；若有設定 `CLAUDE_CONFIG_DIR`，則使用該目錄。Skill 會處理在全域或專案 `CLAUDE.md` 加入引用，讓角色設定進入後續對話。**外掛選 Local 範圍，不代表 setup 產生的模型表也自動成為專案專用檔案。** 執行前應確認其預計寫入位置，避免意外影響其他專案。

自動路由預設開啟。可透過 setup 關閉；Hook 會讀取模型表中的 `session hook: off`。不過腳本在模型表不存在或無法解碼時，仍預設注入路由指引，因此關閉後應在新 Session 確認實際效果。[路由設定與載入](https://github.com/michael-denyer/pstack-claude/blob/main/docs/reference.md#automatic-routing)、[Hook 原始碼](https://github.com/michael-denyer/pstack-claude/blob/main/plugins/pstack/hooks/session-start.sh)

### 4.4 使用範例

唯讀理解既有系統：

```text
/pstack:how 請以繁體中文說明搜尋條件如何從 Vue 元件傳入 API，指出狀態保存位置。只閱讀程式，不修改檔案或執行測試；不得讀取 appsettings*.json。
```

先規劃 Bug 修復，保留本機核准流程：

```text
/pstack:poteto-mode 請分析切換分頁後搜尋條件消失的原因。先閱讀相關程式與呼叫端，說明修改位置、原因、方式及驗證方法，等待我明確核准後才修改。只允許唯讀 Git；build、test、lint 只提供指令。不讀取 appsettings*.json，也不變更 UI 樣式。
```

先從既有差異做審查：

```text
/pstack:interrogate 請審查目前差異的正確性、相容性與資安問題，附具體證據。只做唯讀分析，不修正、執行測試、提交、推送或建立 PR。
```

這些範例是針對目前使用規則撰寫的建議提示，未做實機執行驗證。若流程需要尚未授權的操作，應停在該步並交代缺少的證據。

### 4.5 更新與選用相依工具

README 說明第三方 marketplace 的自動更新預設關閉。可在 `/plugin` 的 Marketplaces 頁面選 `pstack-claude` 啟用，或在終端機手動更新：

```powershell
claude plugin update pstack@pstack-claude
```

導入團隊時，宜先閱讀變更再決定更新，因為更新可能改變工作流程與 Hook。下列工具依需求安裝，不是所有使用者都需要：[更新說明](https://github.com/michael-denyer/pstack-claude/blob/main/README.md#install)、[相依工具](https://github.com/michael-denyer/pstack-claude/blob/main/docs/reference.md#configuration-and-dependencies)

| 工具 | 需要時機 |
| --- | --- |
| GitHub CLI `gh` | PR 監控、交付與部分協調腳本；會使用登入身分。部分流程在可用時改用 Origin CLI。 |
| Bun | `watch-pr`、`orch` 等內附工具，首次啟動會安裝腳本相依套件。 |
| `plugin-dev` | Claude Code 的 Skill 編寫指引，例如 `automate-me`、`reflect` 相關工作；一般調查與修復不必因此一律安裝。 |

## 5. 與 Herdr 的差異

本文件的 Herdr 指現行官方專案 [herdrdev/herdr](https://github.com/herdrdev/herdr)。Herdr 管理代理所在的終端機、工作區與執行中 Session；pstack 管理代理採用的開發方法。兩者處於不同層級。

| 比較項目 | pstack-claude | Herdr |
| --- | --- | --- |
| 核心用途 | 理解、設計、實作、審查與驗證流程。 | 終端機 Pane、工作區、本機／遠端代理與 Session 管理。 |
| 使用介面 | 安裝到 Claude Code 等環境中的 Skills、Hook 與代理設定。 | 提供執行 CLI 的終端機工作環境與控制介面。 |
| 多代理能力 | 用 `arena`、`swarm` 等組織比較、分工及檢查。 | 可透過 CLI／Socket 操作 Pane、啟動代理、送入提示與等待狀態。 |
| 程式品質 | 流程明確要求根因、審查與驗證證據。 | 主要管理執行環境；品質仍依賴代理及其流程。 |
| 關閉前景介面 | pstack 本身不提供 Herdr 式背景終端機 Server。 | detach 後由背景 Server 保持程序執行。 |
| 重新開機 | 不提供程序存活保證。 | 可恢復儲存版面及支援的代理對話；原程序不會跨重開機存活。 |
| 與 Claude Code 搭配 | 直接擴充 Claude Code 的工作方法。 | 在 Pane 中執行已安裝的 `claude` CLI。 |

來源：[pstack 參考文件](https://github.com/michael-denyer/pstack-claude/blob/main/docs/reference.md)、[Herdr README](https://github.com/herdrdev/herdr/blob/master/README.md)。

不能把 Herdr 簡化為「只有視窗管理、沒有代理協作」：現行版本提供代理可用的 CLI／Socket 自動化能力。不過這仍不同於 pstack 的開發流程與品質要求。

概念上可以在 Herdr Pane 中啟動裝有 pstack 的 Claude Code，形成「Herdr 管執行工作區、Claude Code 執行代理、pstack 提供流程」的組合。這是依功能定位推導的搭配方式，**本次未驗證兩者整合相容性、子代理顯示或 Session 恢復後的 Hook 行為**。更多 Herdr 比較可參考同目錄的 `ai-agent-management-tools.md`。

## 6. 資安與權限注意事項

### 6.1 沒有自建遙測，不等於程式碼不會外送

pstack README 聲明自身沒有 Server 或 telemetry，腳本在本機執行；但同一段也明確指出，Skills 要求代理讀取的內容，包括 Session 紀錄，會進入模型供應商的處理流程。PR 工具使用 GitHub CLI 的登入身分。[資料處理聲明](https://github.com/michael-denyer/pstack-claude/blob/main/README.md#data-handling)

因此，私有程式碼、客戶資料、憑證與聊天紀錄都應按實際模型供應商、帳號與組織政策評估。不要把「本機腳本」或「無 pstack 遙測」解讀成離線執行。`automate-me`、`reflect`、`recall` 等涉及既有紀錄的工作，尤其要先限制允許讀取的範圍。

### 6.2 Hook 與 Skill 的權限性質不同

Skill 文字會影響代理如何使用現有工具；命令型 Hook 則直接執行本機程式。Anthropic 官方說明，外掛可用目前使用者權限執行程式，Hook 等外掛自行啟動的程序不受代理工具呼叫的相同沙箱保護。因此不能只靠聊天中的「不要讀取機密」當成完整的外掛隔離措施。[外掛安全與信任](https://code.claude.com/docs/en/plugins/security)

本次檢查的 pstack Claude Hook 會讀取模型設定表，檢查路由開關並載入本機指引；它仍屬可執行程式碼，而且日後更新可改變行為。安裝前至少應檢視 manifest、`hooks/hooks.json`、對應腳本與要使用的 Skill，並維持一般使用者權限。[Hook 原始碼](https://github.com/michael-denyer/pstack-claude/blob/main/plugins/pstack/hooks/session-start.sh)

### 6.3 原始預設偏向自主操作，必須與本機規則對齊

`poteto-mode` 的自主操作段落允許可逆工作及部分外部操作直接進行；Bug fix 原流程則包含 Git 提交安排與建立 PR。這些是上游流程內容，不構成本機授權。[自主操作規則](https://github.com/michael-denyer/pstack-claude/blob/main/plugins/pstack/skills/poteto-mode/SKILL.md#autonomy)、[Bug fix 流程](https://github.com/michael-denyer/pstack-claude/blob/main/plugins/pstack/skills/poteto-mode/playbooks/bug-fix.md)

依本次提供的全域規則，導入時應在 Claude Code 適用的 `CLAUDE.md` 與工具權限中維持以下限制，並確認規則確實載入。不能假設本次對話或其他代理的 `AGENTS.md` 會自動完整套用到 Claude Code。

| 本機要求 | 對 pstack 流程的影響 |
| --- | --- |
| 修改程式前必須規劃並等待明確核准。 | 不能依自主操作預設直接開始修改。 |
| Git 只允許唯讀。 | 不自動 stage、commit、push、rebase 或建立／清理 Worktree；必要指令交給使用者。 |
| build、test、lint 預設由使用者執行。 | 只列驗證指令，未執行時明確標示缺少驗證證據。 |
| 未授權不得讀取 `appsettings.json`／`appsettings.*.json`。 | 調查、子代理與紀錄擷取都必須保留相同限制。 |
| 未要求不得更動 UI 外觀。 | 不因清理或原型流程擴張到 CSS、字型、顏色及間距。 |
| 非程式碼文件放在 `docs/`。 | 工作紀錄與報告路徑需調整；代理指令與 Skill 檔案依既有例外處理。 |

也應明確限制未授權的訊息傳送、PR 操作與第三方服務寫入。平行子代理需收到相同限制；分開對話或 Worktree 不代表取得額外授權，也不代表隔離憑證與網路。

### 6.4 供應鏈、成本與驗證限制

- 安裝來源是第三方 marketplace。記錄版本、檢查更新內容與相依套件，尤其是首次會下載依賴的 Bun 工具。[相依工具說明](https://github.com/michael-denyer/pstack-claude/blob/main/docs/reference.md#configuration-and-dependencies)
- `arena`、`swarm`、多模型審查會增加模型呼叫與等待時間。先限制工作範圍與角色數量；多個模型一致也不等於證明正確。
- GitHub CLI 等工具會沿用登入身分。只在已授權的 repo 與範圍操作，避免讓一般分析任務擁有不必要的寫入能力。
- `deslop` 與註解清理屬於程式修改。不能為了縮短程式而刪除信任邊界驗證、避免資料遺失的錯誤處理或必要的領域限制。
- 安全政策表示只維護 `main` 最新發行版，沒有舊版修補分支。發現漏洞應使用 GitHub 私密漏洞通報，不要先貼到公開 Issue。[SECURITY.md](https://github.com/michael-denyer/pstack-claude/blob/main/SECURITY.md)

上述為依已讀文件與部分原始碼提出的導入建議，不是對整個外掛「安全無虞」的認證。

## 7. 適用情境與導入方式

| 情境 | 評估 |
| --- | --- |
| 陌生程式庫，需要理解實際行為與設計理由。 | 適合先用唯讀的 `how`／`why`。 |
| 難重現的 Bug、跨模組修復或有量測依據的效能問題。 | 有價值，但重現與驗證必須符合使用者授權。 |
| 多方案比較、較大範圍調查或重要變更審查。 | 可評估 `arena`／`swarm`／`interrogate`；先確認額度、模型與子代理能力。 |
| 希望把重複的驗證流程留給後續代理。 | 可建立專案驗證 Skill，再按程式變動維護。 |
| 只改錯字、單一常數或一行簡單邏輯。 | 完整流程可能增加負擔，使用最小必要步驟即可。 |
| 只是想切換終端機與追蹤不同代理 Session。 | Herdr 更直接對應需求。 |
| 需要完全離線、禁止任何原始碼外送。 | pstack 本身不能滿足；必須另外確認代理、模型與網路架構。 |
| 希望一裝好就自動合併、部署且保證正確。 | 不適合如此期待；仍需權限控制、驗證及人工責任界線。 |

建議先在沒有敏感資料的試用專案，以 Local 範圍安裝並關閉自動路由，從一個唯讀問題確認指令、模型與限制都符合預期。之後才評估是否啟用自動路由或平行工作。依目前工作習慣，優先採用 `how`、`why` 與唯讀審查即可，不需一開始導入 PR 監控、交付及長期自主流程。這是採用建議，尚未在本機試用驗證。

## 8. 查核範圍與來源

本次先檢查目標 `docs/`，既有文件多採英文連字號命名，因此使用 `pstack-claude.md`。查核時沒有同名檔案；以新增方式保存，不覆蓋既有文件。

主要一手來源如下；各節也附有對應連結：

- [pstack README](https://github.com/michael-denyer/pstack-claude/blob/main/README.md)：定位、安裝、資料處理與授權。
- [pstack reference](https://github.com/michael-denyer/pstack-claude/blob/main/docs/reference.md)：Skills 清單、執行環境、路由與相依工具。
- [poteto-mode](https://github.com/michael-denyer/pstack-claude/blob/main/plugins/pstack/skills/poteto-mode/SKILL.md)：流程選擇、自主操作與代理協調。
- [Bug fix](https://github.com/michael-denyer/pstack-claude/blob/main/plugins/pstack/skills/poteto-mode/playbooks/bug-fix.md)：重現、根因、實作與驗證步驟。
- [setup-pstack](https://github.com/michael-denyer/pstack-claude/blob/main/plugins/pstack/skills/setup-pstack/SKILL.md)：模型表、設定載入與路由開關。
- [marketplace manifest](https://github.com/michael-denyer/pstack-claude/blob/main/.claude-plugin/marketplace.json)：外掛名稱與查閱版本。
- [Herdr README](https://github.com/herdrdev/herdr/blob/master/README.md)：終端機工作區、代理自動化與 Session 生命週期。
- [Claude Code 安裝](https://code.claude.com/docs/en/setup)、[外掛管理](https://code.claude.com/docs/en/discover-plugins)、[外掛安全](https://code.claude.com/docs/en/plugins/security)：平台原生能力與信任邊界。

未檢查事項：未逐一審閱所有 Skill、全部相依程式與網路行為，未執行安裝、build、test、lint 或 Herdr 整合測試，也未讀取任何 `appsettings*.json`。主要限制是上游內容會持續更新，而文件中的工作流程不等於已在使用者電腦驗證的行為。
