@AGENTS.md

## Claude Code 補充

- 子 Agent 定義在 `.claude/agents/`：coding-agent、code-reviewer、fortify-reviewer。只在使用者以 `/team-pipeline` 啟動流程後，由主 Agent 依 team-pipeline 委派；不要以一般 Agent 或主對話自行模擬獨立審查。
- mvc-coding、code-review、fortify-preverify 三個工作者 Skill 由子 Agent 依 Agent 檔指定的路徑讀取，主 Agent 不自行載入。
- git commit 與 push 由人在另一個終端機執行；`.claude/settings.json` 已禁止 Claude 執行這兩個命令。
