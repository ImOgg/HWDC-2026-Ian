#requires -Version 7.0
<#
.SYNOPSIS
    Reviewer 子 Agent 的 PreToolUse hook：只允許單一唯讀 git 指令，其他命令執行或寫入一律拒絕。

.DESCRIPTION
    掛載位置：
      Claude Code  .claude/agents/code-reviewer.md、fortify-reviewer.md 的 hooks.PreToolUse（matcher: Bash）

    放行：不輸出內容、exit 0，交由工具原本的核准流程。
    拒絕：輸出 hookSpecificOutput.permissionDecision = "deny"。

    允許的 git 子命令：status、diff、log、show、ls-files、blame、rev-parse。
    拒絕：串接、管線、重導向、命令替換；--output（會寫檔）、--ext-diff、--textconv（會執行外部程式）。
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Write-Deny {
    param([Parameter(Mandatory)][string]$Reason)
    $json = [ordered]@{
        hookSpecificOutput = [ordered]@{
            hookEventName            = 'PreToolUse'
            permissionDecision       = 'deny'
            permissionDecisionReason = $Reason
        }
    } | ConvertTo-Json -Compress -Depth 4 -EscapeHandling EscapeNonAscii
    Write-Output $json
    exit 0
}

$payload = $null
$raw = [Console]::In.ReadToEnd()
if (-not [string]::IsNullOrWhiteSpace($raw)) {
    try { $payload = $raw | ConvertFrom-Json } catch { $payload = $null }
}
if (-not $payload) { Write-Deny 'Reviewer hook 無法解析輸入，不執行此工具呼叫。' }

$toolName = [string]$payload.tool_name
$toolInput = $payload.tool_input
$command = $null
if ($toolInput -and $toolInput.PSObject.Properties['command']) { $command = [string]$toolInput.command }

# 非命令型工具：讀取、搜尋放行；可寫入或可執行的工具拒絕
if ($null -eq $command) {
    if ($toolName -match '(?i)(edit|write|create|delete|rename|patch|task|notebook|terminal|execute|run)') {
        Write-Deny "Reviewer 唯讀，不可使用 $toolName。修正交回 Coding。"
    }
    exit 0
}

$cmd = $command.Trim()
$allowed = 'status、diff、log、show、ls-files、blame、rev-parse'

if ($cmd -match '[;&|<>`\r\n]' -or $cmd.Contains('$(')) {
    Write-Deny "Reviewer 只能單獨執行一個唯讀 git 指令，不接受串接、管線、重導向或命令替換：$cmd"
}
if ($cmd -notmatch '^git\s+(status|diff|log|show|ls-files|blame|rev-parse)(\s|$)') {
    Write-Deny "Reviewer 只能執行唯讀 git 指令（$allowed）：$cmd"
}
if ($cmd -match '(^|\s)--(output|ext-diff|textconv)(=|\s|$)') {
    Write-Deny "不接受會寫檔或執行外部程式的 git 參數（--output、--ext-diff、--textconv）：$cmd"
}

exit 0
