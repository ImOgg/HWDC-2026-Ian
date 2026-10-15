---
name: mvc-coding
description: 依團隊規範與核准 Spec／Tasks 實作 C# ASP.NET Core MVC，包含新增、缺陷修復、重構及既有功能調整。受派 Coding 或修復 Review findings 時使用，執行實際 build/test 並回報結果。
disable-model-invocation: true
user-invocable: false
---

# MVC Coding

1. 讀 AGENTS.md、其連結的團隊規範、docs/project-context.md、本次 change 的 proposal/spec/design/tasks，以及受影響的現有程式。確認修改範圍與核准需求；缺關鍵資訊回報 BLOCKED。
2. 依 [實作方法](references/implementation.md) 對照每項 task、適用規範與驗證方式，再實作。全程遵守 CORE 共通行為準則：先寫出假設、只寫 Spec 需要的程式、只改 task 或 finding 需要的地方、先定驗證方式再動手。具體類別、行為、錯誤及測試期望由本次 Spec 決定。
3. 修復時讀原始 findings 與失敗輸出；保留需求、公開契約及有效測試。只改主 Agent 授權範圍，不自行改團隊規範或核准需求。
4. 執行 docs/project-context.md 的驗證入口 `pwsh -NoProfile -File eng/verify.ps1`（restore、build、test）。讀當次輸出與 TRX，確認必要測試實際通過；依失敗原因修復，環境或必要資訊不足回報 BLOCKED。
5. 只勾選實際完成的 tasks。回報第一行寫 `status: DONE` 或 `status: BLOCKED`，再回傳實作摘要、修改檔案、tasks 對照、驗證命令與結果、TRX 路徑及限制。不能自行宣告兩道 Review 通過。

結束時工具 hook 會再執行 eng/verify.ps1，未通過會要求你繼續修正。屬規格、環境或需人工處理的問題時，回報 `status: BLOCKED` 並說明原因，不要反覆嘗試。不得修改 eng/ 下的腳本或 hook 設定來讓驗證通過。

收到主 Agent 的修復要求時，針對原始問題修改；修改後重新執行驗證，再交回主 Agent 安排審查。
