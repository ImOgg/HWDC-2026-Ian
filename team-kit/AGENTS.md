# AI Coding Team

本團隊以 C# / ASP.NET Core MVC 與 DDD 分層進行開發。此入口適用新增功能、修復、重構及既有系統調整。

## 共用規範
開始工作先讀下列規範；它們是 Coding 與 Review 的共同依據：
- [共通行為準則](docs/team-rules/core-principles.md)：CORE-01～04，所有角色適用
- [架構、分層與資料存取](docs/team-rules/architecture.md)
- [命名](docs/team-rules/naming.md)
- [程式品質](docs/team-rules/code-quality.md)
- [測試](docs/team-rules/testing.md)
- [安全](docs/team-rules/security.md)

這是一套可採用或調整的示範團隊政策，不宣稱是唯一的 DDD 做法。規範由團隊維護，Skill 引用規範，不另寫一份標準。
讀取 docs/project-context.md 取得本專案的層級對照、執行方式及既有狀態；讀取本次 OpenSpec change 取得需求與任務。不得從 Skill 推測業務需求。

## 工作流程
- 需求討論先使用 OpenSpec；產出 proposal、spec、design、tasks，取得使用者確認後才實作。
- 使用者明確呼叫 team-pipeline Skill（VS Code `/team-pipeline`）後，內建主 Agent 依序委派 Coding、Code Review、Fortify preverify。主 Agent 不自行啟動 team-pipeline。
- Coding 依獲授權的修改範圍工作；Reviewer 唯讀，修改交回 Coding。
- Reviewer 實際核對程式、適用規範、Spec 與測試，不以 Coding 摘要代替審查。
- Coding 結束前由工具 hook 執行 eng/verify.ps1，未通過不得結束；主 Agent 派審前自行再執行一次。
- FAIL 修復後重新驗證與兩道審查；BLOCKED 回報原因並停止自動推進。
- 完成需本次 tasks 實際完成、最後內容 build/test 通過、兩道 Review PASS，且無未解阻擋問題。
- 使用者驗收後執行 OpenSpec archive，把本次 delta spec 合併進 openspec/specs，作為下一個 change 的 baseline。
- git commit 與 push 由人在 Terminal 執行；主 Agent 與子 Agent 都不執行 commit、push。
- 審查期間暫停修改受檢內容；修改後重新驗證與審查。不得捏造結果或沿用修改前的 PASS。
- 未經授權不得改團隊規範、Skill、Agent、eng/ 驗證腳本、hook 設定、Directory.Build.props、.editorconfig 或架構測試來消除失敗。政策例外依架構規範辦理。

## 小修改出口
使用者明確說明「小修改，不走 team-pipeline」時，主 Agent 可直接修改，不建立 OpenSpec change、不委派子 Agent；修改後仍須執行 `pwsh -NoProfile -File eng/verify.ps1` 並回報結果，未通過不得回報完成。
主 Agent 不得自行判定某個需求屬於小修改；使用者沒有明確說明時，依上方工作流程處理。共用規範、禁止改規則來過關、commit 與 push 由人執行等規定照常適用。

## 元件入口
- 主 Agent 流程（使用者明確呼叫時）：.agents/skills/team-pipeline/SKILL.md
- Coding：.agents/skills/mvc-coding/SKILL.md
- 工程審查：.agents/skills/code-review/SKILL.md
- 安全預檢：.agents/skills/fortify-preverify/SKILL.md
- 驗證入口：eng/verify.ps1；Coding 結束 hook：eng/verify-on-stop.ps1

專案命令讀 docs/project-context.md；在專案根目錄執行 `pwsh -NoProfile -File eng/verify.ps1`。
