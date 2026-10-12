# 命名與程式品質審查方法

標準來源：docs/team-rules/core-principles.md、naming.md 與 code-quality.md。

- 以 `git diff` 逐段對照 tasks 與修復要求的 findings：找不到對應依據的變更（順手調整的相鄰程式、註解、格式，或未要求的重構）為 CORE-03 阻擋問題；未要求的功能、設定或抽象為 CORE-02 阻擋問題；寫法還能再簡化但不影響需求時，標為非阻擋建議。程式行為來自未經確認的假設時，依 CORE-01 提出。
- 核對本次名稱的大小寫、interface／async 後綴、namespace 與領域用語；尊重框架契約與未核准更名的公開 API。
- 從呼叫者追到用例結果及錯誤映射，核對 Spec 行為、相容性、nullable 邊界、例外傳遞及假成功。
- 涉及 I/O 時追查 await、阻塞、取消與資源釋放；涉及共享狀態時核對生命週期與並行策略。沒有該用途時標為不適用。
- 閱讀實際 build 日誌與本次變更，檢查新增警告、分析器抑制及無關相依。建置已啟用 TreatWarningsAsErrors 與命名規則；本次變更若修改 Directory.Build.props、.editorconfig，或新增 NoWarn、#pragma warning disable、SuppressMessage，視為 CODE-07 阻擋問題，除非 design 記錄了已核准的例外。
- 對重複邏輯、多重責任或過度抽象，指出具體維護影響；必要違規與改善建議分開標示。

Spec 定義本次功能，規範定義寫法；兩者都核對，禁止從教材案例反推所有功能的行為。
