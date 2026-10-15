#requires -Version 7.0
<#
.SYNOPSIS
    Coding 子 Agent 結束前的 harness hook：執行 eng/verify.ps1，未通過就要求 Coding 繼續修正。

.DESCRIPTION
    掛載位置：
      Claude Code  .claude/agents/coding-agent.md 的 hooks.Stop（以子 Agent 執行時轉為 SubagentStop）

    輸入：stdin 的 hook JSON。
    輸出：只輸出一行 JSON。
      放行：{}
      阻擋：{"decision":"block","reason":"..."}

    例外放行：
      1. agent_type 不是 Coding 角色（防止誤掛到 Reviewer）。
      2. Coding 回報中有 status: BLOCKED 行（讀 hook 輸入的 last_assistant_message）。
      3. MaxAttempts 大於 0 且同一次 Coding 執行已被擋滿 MaxAttempts 次。放行後由主 Agent 自行執行 eng/verify.ps1 判定。

    次數上限：
      MaxAttempts 預設 0，表示不限次數，verify 沒過就一直擋到通過為止。
      需要上限時在 hook 指令加上 -MaxAttempts <次數>。

    判定紀錄：
      每次判定都在 .agent-state/hook-log.txt 附加一行（時間、角色、執行代號、判定、說明）。
      驗證通過後計數檔會刪除，這份紀錄保留，最後全綠時仍看得出中間被擋過幾次。
      .agent-state/ 已列入 .gitignore，不進版控，也不在 Reviewer 的 git status 內。

.EXAMPLE
    hook 設定的 command：pwsh -NoProfile -File eng/verify-on-stop.ps1
#>
[CmdletBinding()]
param(
    [int]$MaxAttempts = 0,
    [int]$TailLines = 40
)

$ErrorActionPreference = 'Continue'
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$root = Split-Path -Parent $PSScriptRoot
$logFile = Join-Path $root '.agent-state/hook-log.txt'

function Write-HookLog {
    param(
        [Parameter(Mandatory)][string]$Decision,
        [string]$Detail = ''
    )
    # 紀錄失敗不影響 hook 判定，也不輸出到 stdout（stdout 只能有一行 JSON）
    try {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $logFile) | Out-Null
        $who = if ($script:agentType) { $script:agentType } else { '(unknown)' }
        $run = if ($script:key) { $script:key } elseif ($script:agentId) { $script:agentId } else { '-' }
        $line = '{0} | {1} | {2} | {3} | {4}' -f (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'), $who, $run, $Decision, $Detail
        Add-Content -LiteralPath $logFile -Value $line -Encoding utf8
    } catch { }
}

function Write-Allow {
    Write-Output '{}'
    exit 0
}

function Write-Block {
    param([Parameter(Mandatory)][string]$Reason)
    # EscapeNonAscii：中文與 dotnet 輸出一律轉成 \uXXXX，避免主控台編碼造成 JSON 損毀
    $json = [ordered]@{ decision = 'block'; reason = $Reason } |
        ConvertTo-Json -Compress -EscapeHandling EscapeNonAscii
    Write-Output $json
    exit 0
}

# 1. 讀取 hook 輸入
$payload = $null
$raw = [Console]::In.ReadToEnd()
if (-not [string]::IsNullOrWhiteSpace($raw)) {
    try { $payload = $raw | ConvertFrom-Json } catch { $payload = $null }
}

$agentType   = if ($payload) { [string]$payload.agent_type } else { '' }
$agentId     = if ($payload) { [string]$payload.agent_id } else { '' }
$sessionId   = if ($payload) { [string]$payload.session_id } else { '' }
$lastMessage = if ($payload) { [string]$payload.last_assistant_message } else { '' }

# 2. 只處理 Coding 角色
if ($agentType -and $agentType -notmatch '^coding-agent(-claude)?$') {
    Write-HookLog -Decision 'SKIP' -Detail '非 Coding 角色，不驗證'
    Write-Allow
}

# 3. Coding 主動回報 BLOCKED 時放行，交由主 Agent 處理
if ($lastMessage -match '(?im)^\s*status:\s*BLOCKED\b') {
    Write-HookLog -Decision 'ALLOW' -Detail 'Coding 回報 status: BLOCKED，交主 Agent 處理'
    Write-Allow
}

# 4. 嘗試次數（每次 Coding 執行各自計數）
$stateDir = Join-Path $root '.agent-state'
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
$key = if ($agentId) { $agentId } elseif ($sessionId) { $sessionId } else { 'default' }
$key = $key -replace '[^\w-]', '_'
$counterFile = Join-Path $stateDir "verify-attempts-$key.txt"

$attempt = 1
if (Test-Path -LiteralPath $counterFile) {
    $previous = 0
    if ([int]::TryParse((Get-Content -LiteralPath $counterFile -Raw).Trim(), [ref]$previous)) {
        $attempt = $previous + 1
    }
}
Set-Content -LiteralPath $counterFile -Value $attempt -NoNewline

# 5. 執行驗證入口
$verifyScript = Join-Path $PSScriptRoot 'verify.ps1'
$output = & pwsh -NoProfile -File $verifyScript 2>&1 | Out-String
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Remove-Item -LiteralPath $counterFile -Force -ErrorAction SilentlyContinue
    Write-HookLog -Decision 'PASS' -Detail "第 $attempt 次驗證通過"
    Write-Allow
}

# 失敗摘要：第一行錯誤，沒有就用 verify 的失敗步驟
$firstError = ($output -split "`r?`n" | Where-Object { $_ -match '(?i)\berror\b|^\s*Failed\s' } | Select-Object -First 1)
if (-not $firstError) { $firstError = ($output -split "`r?`n" | Where-Object { $_ -match 'VERIFY FAILED' } | Select-Object -First 1) }
$firstError = if ($firstError) { $firstError.Trim() } else { '見 eng/verify.ps1 輸出' }
# 絕對路徑改成相對於專案根目錄，紀錄比較好讀
$firstError = $firstError.Replace($root + [System.IO.Path]::DirectorySeparatorChar, '')
if ($firstError.Length -gt 200) { $firstError = $firstError.Substring(0, 200) + '…' }

# 次數標示：不限次數時只顯示第幾次
$attemptText = if ($MaxAttempts -gt 0) { "$attempt/$MaxAttempts" } else { "$attempt" }

if ($MaxAttempts -gt 0 -and $attempt -ge $MaxAttempts) {
    Remove-Item -LiteralPath $counterFile -Force -ErrorAction SilentlyContinue
    Write-HookLog -Decision 'ALLOW' -Detail "第 $attemptText 次仍未通過（exit $exitCode），放行交主 Agent 判定：$firstError"
    Write-Allow
}

# 6. 未通過：阻擋結束，附上輸出尾段
$tail = (($output -split "`r?`n") | Select-Object -Last $TailLines) -join "`n"
$reason = @"
eng/verify.ps1 未通過（第 $attemptText 次，exit $exitCode）。請依下列輸出修正後再結束。
若屬規格、環境或需人工處理的問題，不要繼續嘗試，在回報中寫一行 status: BLOCKED 並說明原因。

$tail
"@
Write-HookLog -Decision 'BLOCK' -Detail "第 $attemptText 次未通過（exit $exitCode）：$firstError"
Write-Block -Reason $reason
