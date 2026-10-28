# 可移植 Harness 設計：套用到新的 .NET 工作專案

來源：這個 HWDC-2026 課堂專案（`eng/verify.ps1`、`team-kit/`）。
目標：另一個實際的 .NET / C# 工作專案，開發工具只有 Claude Code（不含 VS Code Copilot Agent、Codex）。
本文件只是設計稿，放在 `docs/` 下；實際專案建立後再把對應檔案搬過去、依該專案架構調整路徑。

## 1. 直接複製、不用重寫的部分

這些檔案跟語言／工具無關，是治理規則與 Claude Code 掛載設定，複製過去後只要把專案名稱、層級對照改掉：

| 來源 | 用途 | 需要調整的地方 |
|---|---|---|
| `team-kit/AGENTS.md` | 主流程入口、工作流程、授權範圍 | 檔案路徑如果跟新專案不同就改 |
| `team-kit/docs/team-rules/*.md`（core-principles、architecture、naming、code-quality、testing、security） | 治理規則本體 | 依新專案實際分層、命名慣例調整範例；規則條號可以不變 |
| `team-kit/.agents/skills/team-pipeline/SKILL.md` 等四個 Skill | 主 Agent 派工、Coding、Review、Fortify 預檢 | 內容引用規則檔案路徑要同步 |
| `team-kit/eng/verify-on-stop.ps1` | Coding 結束前強制跑 verify.ps1 | 不用改，純粹呼叫同目錄的 verify.ps1 |
| `team-kit/eng/reviewer-git-only.ps1` | Reviewer 唯讀 git 限制 | 不用改 |
| `.claude/agents/*-claude.md`（來自 `other-tools/claude/.claude/agents/`） | Claude Code 的三個子 Agent 定義 | 檔名可以拿掉 `-claude` 後綴（因為新專案只用 Claude Code，不需要跟 VS Code 版本並存） |
| `.claude/skills/team-pipeline-claude/`（來自 `other-tools/claude/.claude/skills/`） | Claude Code 專用的 Skill 入口 | 同上，不需要跟 VS Code 版本區分命名 |

VS Code（`.github/agents/`）、Codex（`.codex/`）相關檔案新專案不需要，不用搬。

## 2. verify.ps1：在既有骨架上加兩步

新專案照抄 `eng/verify.ps1` 的 restore → build → test 骨架，但在 test 迴圈裡每個專案加 `--collect:"XPlat Code Coverage"`，跑完三個測試專案後，新增「涵蓋率門檻」與「秘密掃描」兩個步驟，一樣用 `Invoke-VerifyStep` 的模式、exit code 不為 0 就整支失敗。

```powershell
# 测试步骤改成收集 coverage
Invoke-VerifyStep -Name "test $($t.Name)" -DotnetArgs @(
    'test', $t.Project, '--no-build', '--no-restore',
    '--logger', "trx;LogFileName=$trxName",
    '--results-directory', "TestResults/$($t.Name)",
    '--collect:XPlat Code Coverage'
)

# --- 新增步驟 1：涵蓋率門檻 ---
# 需要 dotnet tool：dotnet tool install -g dotnet-reportgenerator-globaltool
Write-Output '### coverage gate'
reportgenerator `
    -reports:"TestResults/**/coverage.cobertura.xml" `
    -targetdir:"TestResults/CoverageReport" `
    -reporttypes:"JsonSummary"
$summary = Get-Content 'TestResults/CoverageReport/Summary.json' -Raw | ConvertFrom-Json
$lineCoverage = [double]$summary.summary.linecoverage
$threshold = 70   # 門檻依專案現況訂，不是越高越好；先求「不倒退」
if ($lineCoverage -lt $threshold) {
    Write-Output "VERIFY FAILED at 'coverage gate' (line coverage $lineCoverage% < $threshold%)"
    exit 1
}
Write-Output "coverage: $lineCoverage% (threshold $threshold%)"

# --- 新增步驟 2：秘密掃描 ---
# 需要 gitleaks（choco install gitleaks 或下載 release 放進 PATH）
Invoke-VerifyStep -Name 'secret scan' -DotnetArgs @()  # 下面直接呼叫，不走 dotnet
gitleaks detect --source . --config .gitleaks.toml --no-git -v
if ($LASTEXITCODE -ne 0) {
    Write-Output "VERIFY FAILED at 'secret scan' (exit $LASTEXITCODE)"
    exit 1
}
```

說明：
- 涵蓋率門檻只檔「倒退」，不是信仰數字；新專案第一次跑出來是多少，就先設門檻等於那個數字或略低幾趴，之後只升不降。
- 已經有 `Directory.Build.props` 的 `NuGetAudit`（弱點套件）與 `TreatWarningsAsErrors`，秘密掃描（gitleaks）補的是「憑證/金鑰被提交進 git」這塊，兩者互不重疊，不用重工。
- `.gitleaks.toml` 新建一份極簡設定即可（排除 `.nuget/`、`TestResults/`），不用自己刻規則，gitleaks 內建的 rule set 已經涵蓋常見 key 格式。

## 3. CI/CD：PR 自動跑同一支 verify.ps1

核心原則延續 `docs/project-context.md` 第 36 行那句「人、主 Agent、Coding 結束 hook 與 CI 都使用這個入口」——CI 不另外寫一套驗證邏輯，只是觸發同一支腳本。

`.github/workflows/ci.yml`（放目標專案根目錄）：

```yaml
name: CI
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  verify:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'
      - name: Install verify tooling
        shell: pwsh
        run: |
          dotnet tool install -g dotnet-reportgenerator-globaltool
          choco install gitleaks -y --no-progress
      - name: Run verify.ps1
        shell: pwsh
        run: pwsh -NoProfile -File eng/verify.ps1
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: TestResults/
```

如果公司用 Azure DevOps 而不是 GitHub Actions，把上面三個步驟（checkout／setup-dotnet／pwsh -File eng/verify.ps1）對應成 pipeline yaml 的 `task:` 即可，邏輯不變。

## 4. Claude Code hook 掛載方式不變

延用 `team-kit/eng/` 兩支腳本的既有掛法：
- `.claude/agents/coding-agent*.md` 的 `hooks.Stop` 掛 `pwsh -NoProfile -File eng/verify-on-stop.ps1`
- `.claude/agents/code-reviewer*.md`、`fortify-reviewer*.md` 的 `hooks.PreToolUse`（matcher: Bash）掛 `pwsh -NoProfile -File eng/verify-on-stop.ps1` 改成 `reviewer-git-only.ps1`

两支 hook 腳本本身不用改，因為它們都是用腳本自己所在目錄（`$PSScriptRoot`）推算專案根目錄，跟專案名稱、路徑無關。

## 5. 落地步驟（Checklist）

1. 新專案建立 `.NET 10` 方案，確認三層＋測試專案的架構對照表（仿 `docs/project-context.md`）
2. 複製 `Directory.Build.props`、`.editorconfig`（警告視為錯誤、分析器、命名規則）
3. 複製 `eng/verify.ps1` 為基礎，依第 2 節加上 coverage 與 secret scan 兩步；同步改測試專案清單
4. 新增 `.gitleaks.toml`（排除 `.nuget/`、`TestResults/`、`bin/`、`obj/`）
5. 複製 `team-kit/` 整包（AGENTS.md、docs/team-rules、.agents/skills），依新專案調整規則範例
6. 複製 `other-tools/claude/.claude/` 內容到新專案 `.claude/`，拿掉 `-claude` 後綴命名
7. 新增 `.github/workflows/ci.yml`（第 3 節）
8. 跑一次 `pwsh -NoProfile -File eng/verify.ps1` 確認全線 PASS，再把涵蓋率門檻設成「目前實測值」
9. 用一個小變更試跑完整流程：Coding 子 Agent 寫改動 → Stop hook 擋到 verify 過 → 主 Agent 派 Review → Reviewer 唯讀審查 → 全綠才算完成

以上第 3、4、7 步是本次新加的「CI/CD、涵蓋率門檻、安全掃描」三項，其餘都是照抄既有 harness 模式，不重新設計。
