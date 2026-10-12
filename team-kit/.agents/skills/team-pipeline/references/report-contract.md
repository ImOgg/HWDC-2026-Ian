# 委派與回報約定

## 委派

提供本次 change、AGENTS.md、docs/project-context.md、實際變更範圍、相關程式與測試、主 Agent 當次執行 eng/verify.ps1 的結果，以及必要的 TRX 路徑。Fortify preverify 另接收目前的 Code Review 回覆。
規範是檢查標準，Spec 是本次功能期望。Reviewer 以唯讀 git 指令自行核對實際變更，不以派工內容的檔案清單代替。Review 期間暫停修改受檢內容。

## 原始 Review

子 Agent 直接回覆 Markdown 正文，填寫實際值：

```markdown
status: PASS 或 FAIL 或 BLOCKED
reviewer: code-reviewer 或 fortify-reviewer

## Scope
實際檢查的 change、變更檔案、相關上下文與適用規範。
## Checks
規範／Spec → 程式／測試證據的對照，標明不適用的檢查。
## Findings
每項：阻擋與否、規則編號或 Spec 依據、檔案／符號、證據、影響、修正要求。
## Limitations
未驗證範圍與原因；無額外限制時明確說明。
```

必要違規或需求錯誤未解為 FAIL；缺必要上下文或驗證依據為 BLOCKED；完成實際檢查且無阻擋問題才 PASS。改善建議不冒充必要規範。
主 Agent 使用子 Agent 原始回覆，不代填結論；修正交 Coding。修正後的內容重新驗證與審查，不能沿用修改前的 PASS。
模型安全預檢不是正式掃描結果。
