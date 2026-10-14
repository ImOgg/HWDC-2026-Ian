# Native role mapping

| 執行環境 | 實作 | 工程審查 | 安全預檢 |
|---|---|---|---|
| VS Code Local | coding-agent | code-reviewer | fortify-reviewer |
| Claude Code CLI | coding-agent-claude | code-reviewer-claude | fortify-reviewer-claude |
| Codex CLI | coding-agent | code-reviewer | fortify-reviewer |

先確認目前 harness。Claude 名稱刻意加尾綴，避免 VS Code 同時發現 .github/agents 與 .claude/agents 時撞名。
報告 reviewer 欄位一律使用共同角色 code-reviewer 或 fortify-reviewer。
必須使用工具的原生委派功能並等候回覆。主 Agent 不以 handoff 按鈕切換取代子 Agent pipeline。
不要把 Claude 的 tools、Copilot 工具組或 Codex sandbox_mode 互相複製。

## 工作者 Skill 只由子 Agent 讀取

mvc-coding、code-review、fortify-preverify 關閉隱性觸發：SKILL.md 設 `disable-model-invocation: true`（VS Code），agents/openai.yaml 設 `policy.allow_implicit_invocation: false`（Codex）。主 Agent 不會依 description 自動載入它們；子 Agent 依 Agent 檔指定的路徑直接讀 SKILL.md，不受影響。Claude Code 不掃描 .agents/skills，透過子 Agent 讀檔使用。team-pipeline 也關閉隱性觸發，只由使用者明確呼叫啟動（VS Code `/team-pipeline`、Claude Code `/team-pipeline-claude`、Codex `$team-pipeline`），小修改才不會被自動帶進完整流程。

## Reviewer 的 git 權限

Reviewer 可執行唯讀 git 指令（status、diff、log、show、ls-files、blame、rev-parse）查看實際變更。

| 執行環境 | 做法 |
|---|---|
| VS Code Local | tools 含 execute；agent 的 hooks.PreToolUse 執行 eng/reviewer-git-only.ps1，非唯讀 git 的命令與寫入工具一律拒絕（Preview） |
| Claude Code CLI | tools 含 Bash；agent 的 hooks.PreToolUse（matcher: Bash）執行 eng/reviewer-git-only.ps1 |
| Codex CLI | read-only 沙箱本身禁止寫入，可直接執行 git 唯讀指令，不掛 hook |

## Coding 結束驗證 hook

三個工具都在 Coding 子 Agent 結束時執行 `eng/verify-on-stop.ps1`，由它呼叫 eng/verify.ps1；未通過時要求 Coding 繼續修正，不限次數，直到通過或 Coding 回報 BLOCKED。

| 執行環境 | 設定位置 | 前提 |
|---|---|---|
| VS Code Local | .github/agents/coding-agent.agent.md 的 hooks.Stop | Preview 功能；信任的 workspace；chat.useHooks 開啟（預設） |
| Claude Code CLI | .claude/agents/coding-agent-claude.md 的 hooks.Stop | 接受 workspace trust |
| Codex CLI | .codex/hooks.json 的 SubagentStop（matcher 為 agent_type） | 信任專案；以 /hooks 審核並信任，hook 內容變更後需重新信任 |

hook 未觸發時，主 Agent 仍依 team-pipeline 自行執行 eng/verify.ps1。三個工具都需在專案根目錄啟動，hook 以相對路徑呼叫腳本。
