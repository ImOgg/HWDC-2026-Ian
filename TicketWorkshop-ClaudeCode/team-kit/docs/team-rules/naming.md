# 命名規範

- **NAME-01 必要**：型別、namespace、公開成員採 PascalCase；參數與區域變數採 camelCase；私有 instance 欄位採 _camelCase；常數採 PascalCase。測試方法可使用描述情境與期望的名稱，以底線分段。
- **NAME-02 必要**：介面名稱以 I 開頭；回傳 Task／ValueTask 的非同步方法以 Async 結尾。覆寫或實作既有框架契約時遵循該契約，不改 MVC action 路由契約來湊命名。
- **NAME-03 必要**：領域用語與 Spec 一致；同一概念不使用多個同義名稱。若需求詞彙不清楚，先確認；不得用範例名詞代替當次領域。
- **NAME-04 必要**：namespace 對應專案及資料夾責任，遵循專案既有 RootNamespace；類別與方法名稱表達用途，不採無意義縮寫、拼音或流水編號。
- **NAME-05 建議**：避免過度泛稱的 Manager、Helper、Data、Process；只有名稱無法表達實際責任時提出具體替代，不對慣用框架名稱任意挑剔。

本次未修改的公開 API 不因命名規則擅自造成相容性破壞；必要更名須納入核准任務。
NAME-01、NAME-02 由 .editorconfig 的命名規則在建置時檢查；只能比對 async 修飾詞的部分與 NAME-03～05 由 Code Review 判斷。
參考：[C# 命名慣例](https://learn.microsoft.com/dotnet/csharp/fundamentals/coding-style/identifier-names)。Async 後綴與私有欄位前綴是本團隊選定的政策。
