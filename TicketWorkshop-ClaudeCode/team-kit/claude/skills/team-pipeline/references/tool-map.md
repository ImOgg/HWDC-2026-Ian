# Claude Code 角色對照

| 角色     | 子 Agent         | Agent 檔                           | 工作者 Skill                                |
| -------- | ---------------- | ---------------------------------- | ------------------------------------------- |
| 實作     | coding-agent     | .claude/agents/coding-agent.md     | .claude/skills/mvc-coding/SKILL.md          |
| 工程審查 | code-reviewer    | .claude/agents/code-reviewer.md    | .claude/skills/code-review/SKILL.md         |
| 安全預檢 | fortify-reviewer | .claude/agents/fortify-reviewer.md | .claude/skills/fortify-preverify/SKILL.md   |

使用 Agent 工具原生委派（`subagent_type` 填上表的子 Agent 名稱），並等候回覆。主 Agent 不在同一上下文扮演子 Agent。
報告 reviewer 欄位使用 code-reviewer 或 fortify-reviewer。

## 工作者 Skill 只由子 Agent 讀取

mvc-coding、code-review、fortify-preverify 的 SKILL.md 設 `disable-model-invocation: true` 與 `user-invocable: false`：主 Agent 不會依 description 自動載入，使用者也不能從 `/` 叫出；子 Agent 依 Agent 檔指定的路徑直接讀 SKILL.md，不受影響。
team-pipeline 設 `disable-model-invocation: true`，只由使用者輸入 `/team-pipeline` 啟動，小修改才不會被自動帶進完整流程。

## Reviewer 的 git 權限

Reviewer 的 tools 為 Read、Grep、Glob、Bash。Agent 檔的 hooks.PreToolUse（matcher: Bash）執行 eng/reviewer-git-only.ps1，只放行單一唯讀 git 指令（status、diff、log、show、ls-files、blame、rev-parse），其他命令一律拒絕。

## Coding 結束驗證 hook

.claude/agents/coding-agent.md 的 hooks.Stop（子 Agent 執行時轉為 SubagentStop）執行 eng/verify-on-stop.ps1，由它呼叫 eng/verify.ps1；未通過時要求 Coding 繼續修正，不限次數，直到通過或 Coding 回報 status: BLOCKED。

子 Agent frontmatter 的 hook 要接受 workspace trust 才會執行。hook 未觸發時，主 Agent 仍依 team-pipeline 自行執行 eng/verify.ps1。claude 需在專案根目錄啟動，hook 以相對路徑呼叫腳本。
