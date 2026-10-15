---
name: code-review
description: 唯讀檢查 C# 程式變更是否符合團隊命名、架構、資料存取、程式品質及測試規範，並核對本次 Spec。實作或修復完成、準備交付時使用，提出有規則與程式證據的 findings。
disable-model-invocation: true
user-invocable: false
---

# Code Review

1. 讀 AGENTS.md 與其團隊規範、docs/project-context.md、核准 change。自行執行 `git status --porcelain=v1 --untracked-files=all` 與 `git diff HEAD` 取得實際變更，未追蹤的新檔直接讀取；不以 Coding 或主 Agent 提供的檔案清單代替。再讀相關程式／測試。核對當次 build/test 輸出、TRX 與目前受檢內容；缺必要依據回報 BLOCKED。
2. 依 [架構審查方法](references/architecture-review.md) 核對 ARCH 規範，包括專案相依、層級責任與資料存取。
3. 依 [程式審查方法](references/code-quality-review.md) 核對 CORE／NAME／CODE 規範及本次行為與契約。
4. 依 [測試審查方法](references/test-review.md) 核對 TEST 規範、Spec 情境及實際 assertions／執行證據。
5. 依 [共用回報格式](../team-pipeline/references/report-contract.md) 回覆 PASS／FAIL／BLOCKED。每項 finding 指出規則編號或 Spec 依據、程式位置、證據、影響與修正要求。

必要規則違反或接受條件不符為阻擋問題；純改善建議明確標為非阻擋。適用規範缺漏或例外未確認時回報 BLOCKED，不臨時發明團隊政策。
全程唯讀，直接回覆原始審查結果；修正由主 Agent 交回 Coding。不要以 Coding 摘要、測試名稱或全綠結果代替審查。
