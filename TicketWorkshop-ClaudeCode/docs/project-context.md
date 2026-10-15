# 本專案背景

這份文件是專案背景與命令入口，換 repository 時更新；具體功能需求放本次 OpenSpec change。

| 層              | 專案                                                                                           |
| --------------- | ---------------------------------------------------------------------------------------------- |
| Domain          | src/Workshop.Domain                                                                            |
| Application     | src/Workshop.Application                                                                       |
| Infrastructure  | src/Workshop.Infrastructure                                                                    |
| Web／組裝入口   | src/Workshop.Web／Program.cs                                                                   |
| Domain 單元測試 | tests/Workshop.Domain.Tests                                                                    |
| Web 整合測試    | tests/Workshop.Web.Tests                                                                       |
| 架構相依測試    | tests/Workshop.Architecture.Tests（NetArchTest.eNhancedEdition，檢查 ARCH-01、02、03、05、06） |

方案為 Workshop.slnx，目標 net10.0。
目前由標準 .NET 範本建立，未實作業務功能。開始工作前重新讀實際程式；此描述不代替程式現況。

## 驗證入口

在專案根目錄執行（需 PowerShell 7）：

```text
pwsh -NoProfile -File eng/verify.ps1
```

腳本先刪除 TestResults/，再依序執行下列命令，任一步 exit code 不為 0 即以 exit 1 結束，全部通過輸出 VERIFY PASSED：

```text
dotnet restore Workshop.slnx -m:1
dotnet build Workshop.slnx --no-restore -m:1
dotnet test tests/Workshop.Domain.Tests/Workshop.Domain.Tests.csproj --no-build --no-restore --logger "trx;LogFileName=domain.trx" --results-directory TestResults/Domain
dotnet test tests/Workshop.Web.Tests/Workshop.Web.Tests.csproj --no-build --no-restore --logger "trx;LogFileName=web.trx" --results-directory TestResults/Web
dotnet test tests/Workshop.Architecture.Tests/Workshop.Architecture.Tests.csproj --no-build --no-restore --logger "trx;LogFileName=architecture.trx" --results-directory TestResults/Architecture
```

人、主 Agent、Coding 結束 hook（eng/verify-on-stop.ps1）與 CI 都使用這個入口。
查看當次輸出與 TestResults/Domain/domain.trx、TestResults/Web/web.trx、TestResults/Architecture/architecture.trx，確認必要測試實際執行且通過。命令成功但零測試不能當作交付完成；不要使用前次結果。
新增測試專案時，同步更新 eng/verify.ps1 的測試專案清單與此處的命令、路徑。

NuGet 套件快取由專案根目錄的 nuget.config 指到 .nuget/packages（已列入 .gitignore）。

## 建置層規則

| 檔案                              | 檢查內容                                                                                                                     |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Directory.Build.props             | TreatWarningsAsErrors、AnalysisLevel latest-recommended、EnforceCodeStyleInBuild；NuGetAudit 弱點警告視為錯誤（NU1900 除外） |
| .editorconfig                     | NAME-01／02 命名規則（IDE1006）；Controllers 不強制 Async 後綴；tests/ 允許底線分段的測試方法名稱                            |
| tests/Workshop.Architecture.Tests | ARCH-01、02、03、05、06 的組件相依；組裝入口為 Program                                                                       |

這三者由 eng/verify.ps1 的 build 與 test 執行，違反即驗證失敗。

本機執行：

```text
dotnet run --project src/Workshop.Web 
```

資料存放、身分驗證及部署邊界由本次需求討論確認。
