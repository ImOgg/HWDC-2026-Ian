# Fortify 分類對照

標準來源：docs/team-rules/security.md。這份表把 SEC 規則對應到正式 Fortify SCA 對 C#／.NET 常用的分類名稱，用途是預估正式掃描可能標出的項目。判定 PASS／FAIL 仍以 SEC 規則與實際資料流為準，分類名稱只作為補充標示。

- 只使用分類名稱，不寫 rule ID。
- 「查證」欄：已確認＝vulncat 有 .NET 規則或 C# 範例；名稱已確認＝分類存在，.NET 適用性未確認；[需查證]＝名稱或適用性都未確認。引用 [需查證] 的分類時保留標記。
- 名稱查證來源：https://vulncat.fortify.com （2026-10-11）。正式掃描使用的規則包版本以企業的 Fortify 環境為準。

## 注入與輸出

| Fortify 分類 | 團隊規則 | .NET 常見觸發點 | 預檢重點 | 查證 |
|---|---|---|---|---|
| SQL Injection | SEC-03 | FromSqlRaw、ExecuteSqlRaw、SqlQueryRaw、CommandText、Dapper 以字串插值組 SQL | 參數化；排序欄位、方向等無法參數化的片段以 allow-list 對應 | 已確認 |
| Cross-Site Scripting: Reflected | SEC-02 | Html.Raw、HtmlString、以字串組 HTML 或 JavaScript 回應 | Razor 預設編碼；attribute、JavaScript、URL 使用對應上下文編碼 | 已確認 |
| Cross-Site Scripting: Persistent | SEC-02 | 儲存後再輸出的使用者內容 | 同上，追查儲存到輸出的路徑 | 名稱已確認 |
| Command Injection | SEC-04 | Process.Start、ProcessStartInfo.Arguments | 不以不可信字串組命令；使用 ArgumentList 與 allow-list | 已確認 |
| Log Forging | SEC-10 | ILogger 或其他記錄 API 寫入使用者輸入 | 訊息範本參數；移除或編碼 CR／LF | 已確認 |
| Header Manipulation | SEC-11 | Response.Headers 指派使用者輸入 | 驗證並移除 CR／LF | 名稱已確認 |
| Header Manipulation: Cookies | SEC-11 | Response.Cookies.Append 的值來自使用者輸入 | 驗證並移除 CR／LF | 已確認 |
| Path Manipulation | SEC-04 | Path.Combine、File 類別、FileStream、上傳或下載檔名 | Path.GetFileName 取檔名；GetFullPath 後比對信任的基準目錄 | 名稱已確認 |
| Server-Side Request Forgery | SEC-04 | HttpClient 的目標 URL 來自輸入 | scheme、host、port allow-list；拒絕 loopback、link-local、私有網段 | 已確認 |
| Open Redirect | SEC-04 | Redirect(returnUrl) | Url.IsLocalUrl、LocalRedirect 或網域 allow-list | 已確認 |
| XML External Entity Injection | SEC-09 | XmlDocument、XmlReader、DataSet.ReadXml | DtdProcessing.Prohibit；XmlResolver 設為 null | 已確認 |
| Dynamic Code Evaluation: Unsafe Deserialization | SEC-09 | BinaryFormatter、Newtonsoft TypeNameHandling、多型反序列化 | System.Text.Json 搭配明確 DTO | 已確認 |

## 存取控制與表單

| Fortify 分類 | 團隊規則 | .NET 常見觸發點 | 預檢重點 | 查證 |
|---|---|---|---|---|
| Mass Assignment: Insecure Binder Configuration | SEC-07 | Action 參數直接綁定 Entity；未限制可綁定欄位 | 專用輸入模型與明確對應 | 已確認 |
| ASP.NET MVC Bad Practices: Controller Action Without AntiForgery Validation | SEC-06 | 狀態變更的 POST action 未驗證 antiforgery token | 全域 AutoValidateAntiforgeryTokenAttribute 或逐一標註 ValidateAntiForgeryToken | 已確認 |
| ASP.NET MVC Bad Practices: Form Without AntiForgery Token | SEC-06 | 手寫 form 未產生 token | 使用 form tag helper 或 Html.AntiForgeryToken() | 已確認 |

物件層級授權缺漏（SEC-05）在正式掃描的 .NET 分類名稱未確認 [需查證]，仍依 SEC-05 審查。

## 密碼學與秘密

| Fortify 分類 | 團隊規則 | .NET 常見觸發點 | 預檢重點 | 查證 |
|---|---|---|---|---|
| Insecure Randomness | SEC-09 | System.Random、Guid.NewGuid 用於 token、重設碼、金鑰 | RandomNumberGenerator；實體主鍵、追蹤 ID 等識別用途不屬此類 | 名稱已確認 |
| Weak Cryptographic Hash | SEC-09 | MD5、SHA1；以一般雜湊保存密碼 | 安全用途使用 SHA-256 以上；密碼使用 PasswordHasher 等專用雜湊器 | 已確認 |
| Weak Encryption | SEC-09 | DES、TripleDES、RC2、ECB 模式、固定 IV | AES-GCM，或 AES-CBC 搭配 HMAC 與隨機 IV | [需查證] |
| Key Management: Hardcoded Encryption Key | SEC-01 | 原碼中的金鑰位元組或字串 | 設定提供者、使用者祕密、Key Vault | 已確認 |
| Password Management: Hardcoded Password | SEC-01 | 常數或連線字串中的密碼 | 設定提供者、使用者祕密、Key Vault | 已確認 |
| Password Management: Password in Configuration File | SEC-01 | 提交到版本控制的 appsettings*.json 含密碼 | 同上 | 名稱已確認 |

## 資訊外洩

| Fortify 分類 | 團隊規則 | .NET 常見觸發點 | 預檢重點 | 查證 |
|---|---|---|---|---|
| Privacy Violation | SEC-08 | 記錄或回傳個資、token、Authorization 標頭 | 遮罩；只記錄必要欄位 | 名稱已確認 |
| System Information Leak | SEC-08 | 非開發環境啟用 DeveloperExceptionPage；回傳 ex.ToString() 或 ex.Message | UseExceptionHandler；ProblemDetails 不帶內部資訊 | 名稱已確認 |

## Cookie、傳輸與跨來源

| Fortify 分類 | 團隊規則 | .NET 常見觸發點 | 預檢重點 | 查證 |
|---|---|---|---|---|
| Cookie Security: Cookie not Sent Over SSL | SEC-11、13 | CookieOptions.Secure 未設；CookieSecurePolicy.None | 部署為 HTTPS 時 Secure 或 SecurePolicy.Always | 已確認 |
| Cookie Security: HTTPOnly not Set | SEC-11 | CookieOptions.HttpOnly 未設 | HttpOnly；前端必須讀取的 Cookie 需說明原因 | 已確認 |
| Cookie Security: Persistent Cookie | SEC-11 | 設定 Expires 或 MaxAge | 敏感 Cookie 不持久化 | 已確認 |
| HTML5: Overly Permissive CORS Policy | SEC-11 | AllowAnyOrigin、WithOrigins("*")、SetIsOriginAllowed 一律回 true | 明確來源清單 | 已確認 |
| Insecure Transport | SEC-13 | 對外呼叫使用 http://；資料庫連線未加密 | HTTPS；加密連線 | 已確認 |
| ASP.NET Middleware Out of Order: Insecure Transport | SEC-13 | UseHttpsRedirection 缺漏或位置錯誤 | 依官方中介軟體順序 | 已確認 |

## 阻斷服務

| Fortify 分類 | 團隊規則 | .NET 常見觸發點 | 預檢重點 | 查證 |
|---|---|---|---|---|
| Denial of Service: Regular Expression | SEC-12 | new Regex、Regex.IsMatch 等處理使用者輸入且未設逾時 | matchTimeout 或 RegexOptions.NonBacktracking | 已確認 |

## 由 Code Review 處理的品質類分類

正式掃描也會回報下列分類，對應 CODE 規則，由 Code Review 判定。預檢發現時只在 Findings 標註為非阻擋，不重複判定。

| Fortify 分類 | 團隊規則 | .NET 常見觸發點 | 查證 |
|---|---|---|---|
| Poor Error Handling: Overly Broad Catch Block | CODE-03 | catch (Exception) 後吞掉例外或回傳成功 | 已確認 |
| Unreleased Resource: Streams | CODE-04 | 未以 using 釋放的 Stream、Reader、Writer | 已確認 |

## 預期誤報的判斷

下列情況正式掃描常會標出，預檢確認有防護時列為「預期誤報」，附抑制說明草稿，不阻擋：

- Log Forging：已使用訊息範本參數，且值不可能含 CR／LF（例如已驗證格式的數字 ID）。
- Controller Action Without AntiForgery Validation：已在全域註冊 AutoValidateAntiforgeryTokenAttribute。
- Denial of Service: Regular Expression：已使用 RegexOptions.NonBacktracking。正式掃描是否接受此寫法 [需查證]。
- Insecure Randomness：Guid 只用於識別，不作為存取憑證。
- Cookie not Sent Over SSL、Insecure Transport：Spec／design 明定僅限本機 HTTP 練習，依 SEC-13 列為不適用，並在 Limitations 註明正式部署前需處理。

抑制說明草稿包含：資料來源、防護所在的檔案與符號、判斷可安全的依據、正式部署時是否需重新評估。
