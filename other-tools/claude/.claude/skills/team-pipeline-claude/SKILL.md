---
name: team-pipeline-claude
description: 在 Claude Code 中啟動 OpenSpec 需求確認、實作與兩道審查的團隊流程。使用者要求依團隊 SOP 開發、修復或交付功能時使用。
disable-model-invocation: true
---

讀專案根目錄 `.agents/skills/team-pipeline/SKILL.md` 並依正文執行。
讀它直接列出的 references，從目前 Claude Code 主對話委派三個帶 -claude 尾綴的原生子 Agent。
不要把此入口再委派成主 Agent 的子 Agent。
