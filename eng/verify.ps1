#requires -Version 7.0
<#
.SYNOPSIS
    團隊單一驗證入口：依序執行 restore、build、各測試專案，任一步 exit code 不為 0 即失敗。

.DESCRIPTION
    人、主 Agent、Coding 結束 hook 與 CI 都呼叫這支腳本，命令只維護這一份。
    方案或測試專案變更時，修改下方 $solution 與 $testProjects，並同步更新 docs/project-context.md。
    執行前先刪除 TestResults/，避免讀到前次結果。

.EXAMPLE
    pwsh -NoProfile -File eng/verify.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

# 以腳本位置決定專案根目錄（eng/ 的上一層），不依賴目前工作目錄
$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root

$solution = 'Workshop.slnx'
$testProjects = @(
    @{ Name = 'Domain'; Project = 'tests/Workshop.Domain.Tests/Workshop.Domain.Tests.csproj' }
    @{ Name = 'Web';    Project = 'tests/Workshop.Web.Tests/Workshop.Web.Tests.csproj' }
    @{ Name = 'Architecture'; Project = 'tests/Workshop.Architecture.Tests/Workshop.Architecture.Tests.csproj' }
)

function Invoke-VerifyStep {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string[]]$DotnetArgs
    )
    Write-Output "### $Name"
    Write-Output "> dotnet $($DotnetArgs -join ' ')"
    & dotnet @DotnetArgs
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        Write-Output "VERIFY FAILED at '$Name' (exit $code)"
        exit 1
    }
}

Remove-Item -LiteralPath (Join-Path $root 'TestResults') -Recurse -Force -ErrorAction SilentlyContinue

Invoke-VerifyStep -Name 'restore' -DotnetArgs @('restore', $solution, '-m:1')
Invoke-VerifyStep -Name 'build' -DotnetArgs @('build', $solution, '--no-restore', '-m:1')

foreach ($t in $testProjects) {
    $trxName = "$($t.Name.ToLowerInvariant()).trx"
    Invoke-VerifyStep -Name "test $($t.Name)" -DotnetArgs @(
        'test', $t.Project, '--no-build', '--no-restore',
        '--logger', "trx;LogFileName=$trxName",
        '--results-directory', "TestResults/$($t.Name)"
    )
}

Write-Output 'VERIFY PASSED'
exit 0
