---
name: fortify-preverify
description: 依團隊安全規範唯讀分析 C#／ASP.NET Core 原碼資料流，預先辨識可能的安全問題，並對照正式 Fortify 掃描的分類名稱。Code Review 通過或受派原碼安全預檢時使用；提出具體修正要求，不執行 Fortify 引擎。
disable-model-invocation: true
---

# Fortify Preverify

1. 讀 AGENTS.md、docs/team-rules/security.md、project context、核准 Spec／design。自行執行 `git status --porcelain=v1 --untracked-files=all` 與 `git diff HEAD` 取得實際變更，未追蹤的新檔直接讀取。再讀實際程式與測試、當次 build/test 結果及目前 Code Review 回覆。Team 流程需先取得目前受檢內容的 Code Review PASS。
2. 依 [資料流方法](references/data-flow.md) 識別本次實際入口、信任邊界與敏感操作，再依 SEC 規範逐條核對。
3. 依 [設定與安全機制檢查](references/security-checks.md) 檢查相關機密、身分／授權、日誌、錯誤與依賴。適用性依本次設計判定，不假設一律有登入、資料庫或外部服務。
4. 依 [Fortify 分類對照](references/fortify-categories.md) 逐類核對本次變更的觸發點，預估正式掃描可能標出的分類。
5. Finding 列出來源、轉換、防護、敏感操作、程式位置、SEC 規則、預期 Fortify 分類名稱及修正要求，並標示類型：
   - 可證實問題：違反 SEC 規則，屬阻擋問題。
   - 預期誤報：正式掃描可能標出，但已確認有防護或不可利用；非阻擋，附抑制說明草稿（資料來源、防護位置、判斷依據）。
   - 需補資訊：必要安全邊界未確認，回報 BLOCKED。
   - 不適用：本次沒有該資料流，或依 Spec／design 的部署邊界不適用。
6. 依 [共用回報格式](../team-pipeline/references/report-contract.md) 唯讀回覆 PASS／FAIL／BLOCKED，修正交回 Coding。

不捏造 Fortify rule ID、引擎結果或漏洞掃描紀錄；不宣稱符合所有掃描規則或不存在漏洞。分類名稱以 fortify-categories.md 為準，表中標 [需查證] 的名稱引用時保留標記。
