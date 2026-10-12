# 架構、分層與資料存取規範

## 層級與編譯相依
| 層             | 責任                                           | 允許引用的產品層                         |
| -------------- | ---------------------------------------------- | ---------------------------------------- |
| Domain         | 領域模型、業務規則與領域服務                   | 無                                       |
| Application    | 用例協調、輸入輸出契約及資料存取／外部服務介面 | Domain                                   |
| Infrastructure | 資料庫、檔案、外部服務等介面的具體實作         | Application、Domain                      |
| Web            | HTTP、身分上下文、輸入模型、畫面及組裝入口     | Application；Infrastructure 僅限組裝入口 |

- **ARCH-01 必要**：遵循上表相依方向，禁止循環相依。用 .csproj、套件引用、using 與實際呼叫一起核對；只放對資料夾不等於符合分層。
- **ARCH-02 必要**：Domain 不依賴 MVC、HTTP、ORM、資料庫連線、檔案或外部 API；不要把業務規則放入傳輸或儲存模型。團隊核准的純計算函式庫可使用。
- **ARCH-03 必要**：Application 協調用例與 Domain，透過介面取得資料或呼叫外部服務；禁止直接使用 DbContext、SQL、資料庫連線、Infrastructure 具體類別或 HTTP 回應型別。
- **ARCH-04 必要**：本團隊將 repository／外部服務介面定義於 Application，Infrastructure 實作；介面不洩漏 DbSet、資料庫 connection、ORM tracking 等儲存細節。
- **ARCH-05 必要**：Controller 負責模型驗證、呼叫用例與映射 HTTP；Razor 負責呈現。禁止在 Controller／View 寫資料查詢、跨物件業務流程或直接建立 Infrastructure 服務。
- **ARCH-06 必要**：只有組裝入口可引用 Infrastructure 完成 DI。一般 Web 程式透過 Application 契約工作，禁止 Service Locator 與隱藏的全域服務取得方式。
- **ARCH-07 必要**：業務狀態與不變條件由適當的領域模型管理；Entity、Value Object、Aggregate 的選擇依需求與生命週期說明，禁止為了湊 DDD 名詞引入無用途的框架或物件。
- **ARCH-08 必要（涉及時）**：跨資料操作的交易、並行一致性與失敗回復策略，須在 design 說明並在適當層實作；具體業務條件由 Spec 定義。
- 架構測試在建置驗證時檢查 ARCH-01、02、03、05、06 的組件相依（位置見 docs/project-context.md）；ARCH-04、07、08 與測試無法涵蓋的責任放置由 Code Review 判斷。
- **ARCH-09 建議**：保持契約與類別責任清楚；避免把多個無關用例集中成巨大服務。只有可指出耦合或維護影響時才提出拆分建議。

## 既有系統及例外
新增／修改的程式須符合規範；未受本次變更影響的既有問題記為技術債，不擅自擴大重構。若既有架構使核准任務無法符合必要規則，回報 BLOCKED。
例外須由使用者確認，記錄於本次 design：規則編號、原因、影響範圍、替代措施與後續處置。Spec 不會自行覆寫規範，Agent 也不能自行批准例外。


