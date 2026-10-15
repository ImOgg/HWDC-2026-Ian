# 架構審查方法

標準來源：AGENTS.md 連結的 docs/team-rules/architecture.md。先讀規範，再讀 docs/project-context.md 的實際專案對照。

1. **建立相依圖**：先讀本次架構測試（tests/Workshop.Architecture.Tests）的執行結果，它檢查組件層級的相依方向。再讀 .csproj 的 ProjectReference／PackageReference，與 using、建構子依賴及實際呼叫一起核對 ARCH-01。追查循環、反向依賴與包裝後的洩漏；架構測試通過不代表責任放置正確。
2. **核對責任**：檢查改動是否放在適當層；Controller／View 是否夾帶用例或資料存取，Application 是否協調而非直接操作資料庫，Domain 是否被框架與 I/O 耦合。依 ARCH-02～06 判斷。
3. **追查資料存取**：從用例追到契約及實作，檢查 DbContext、SQL、connection、儲存型別是否流入 Application／Web；確認 Infrastructure 只透過組裝入口注入。
4. **檢查領域設計**：依 ARCH-07～08 與本次 Spec／design 檢查模型責任、業務規則、聚合邊界、交易與一致性。不要預設某個 Entity、方法或狀態必須存在。
5. **核對變更邊界**：評估契約相容性、既有系統影響及已核准例外。未受影響的舊問題列技術債，阻礙本次必要規則時回報具體原因。

Finding 要以實際專案、檔案與符號說明違反哪條規則；不能只說「不符合 DDD」或要求增加無用途的抽象。
