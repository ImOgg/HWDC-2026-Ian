---
name: team-pipeline
description: 協調長期 AI Coding Team，以 OpenSpec 確認需求後依序派工 Coding、Code Review 與 Fortify preverify。使用者要求按團隊流程新增、修復、重構或交付功能時使用，管理修復與完成條件。
disable-model-invocation: true
---

# Team Pipeline

由目前工具的內建 Agent 擔任協調者。每次接收當次 change，業務需求由該 change 定義。

## 確認工作

讀 AGENTS.md、團隊規範、docs/project-context.md、現有程式及本次 OpenSpec change。需要討論或產出文件時依 [OpenSpec 方法](references/openspec.md)。
需求有多種解讀時依 CORE-01 列出並詢問，不自行選定。確認使用者已核准本次 proposal/spec/design/tasks 與修改範圍後才派工。延續既有對話中的授權；需求或範圍改變時重新確認。

## 派工與驗證

1. 依 [工具角色對照](references/tool-map.md) 原生委派 Coding，提供 change、規範與專案背景入口、授權範圍。Coding 使用 mvc-coding Skill。
2. 等待 Coding 回覆，查看回報首行的 status、實際修改、tasks 對照及驗證結果。Coding 結束前已由工具 hook 執行 eng/verify.ps1；hook 未觸發時，Coding 回報不代表驗證通過。
3. 主 Agent 自行執行 `pwsh -NoProfile -File eng/verify.ps1`，exit 0 才進入審查，並核對本次 TRX，確認必要測試實際執行且通過。Coding 回報 status: BLOCKED，或失敗原因屬環境、規格問題時，回報 BLOCKED；其他失敗交回 Coding 修復一次，仍未通過即回報 BLOCKED。

## 獨立審查

1. 依 [回報約定](references/report-contract.md) 原生委派 Code Review，提供核准 Spec、適用規範、實際變更與上下文、當次 build/test 結果。Reviewer 必須讀實際程式與測試。
2. 等待 Code Review 的原始回覆，檢查 PASS／FAIL／BLOCKED、findings 與限制。主 Agent 不代填審查結論。
3. Code Review PASS 後才原生委派 Fortify preverify，提供同一份受檢程式與目前的 Code Review 回覆。等待其原始結果。

## 修復與完成

- 任一 Review FAIL，將原始 findings 交回 Coding；修改後重新執行 eng/verify.ps1、Code Review 與 Fortify preverify。
- 審查期間暫停修改受檢程式；審查後再修改程式、測試、規格或適用規範，必須重新驗證與審查。
- BLOCKED 時停止自動推進，回報具體原因、已完成部分與需要處理的資訊。修復無法推進時說明原因，不重複無效嘗試。
- 只有本次 tasks 實際完成、最後內容 build/test 通過、Code Review PASS、Fortify preverify PASS，且無未解阻擋問題，才回報完成。
- 交付摘要包含需求與實作對照、修改檔案、實際驗證命令與結果、兩道審查結論及限制，最後提示使用者驗收後執行 OpenSpec archive。主 Agent 不自行 archive。

主 Agent 協調與判定完成；產品修改交 Coding，Reviewer 唯讀。原生子 Agent 不可用時回報具體缺失，不在同一上下文自行扮演兩位 Reviewer。
