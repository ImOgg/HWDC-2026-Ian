# TicketWorkshop：AI Coding Agent Team Workshop（Claude Code CLI 版）

HWDC 2026 Lab「AI Coding 治理實戰：從開發到交付的 Harness 工程」的課堂專案，Claude Code CLI 版本。

使用 Claude Code CLI，把一套 Agent Team（主 Agent 加上 Coding、Code Review、Fortify preverify 三個子 Agent，以及四個 Skill）配置到這個 .NET 10 MVC 專案，再用 OpenSpec 從需求討論、產出 Spec，一路走到程式碼交付。

**操作步驟請看 [WORKSHOP.md](WORKSHOP.md)。**

## 內容

| 位置                                     | 用途                                                                                          |
| ---------------------------------------- | --------------------------------------------------------------------------------------------- |
| `Workshop.slnx`、`src/`、`tests/`        | 起始方案：Domain、Application、Infrastructure、Web 四層與測試專案，目前只有 MVC 範本          |
| `tests/Workshop.Architecture.Tests/`     | 架構相依測試（ARCH-01、02、03、05、06）                                                       |
| `eng/verify.ps1`                         | 團隊唯一的驗證入口：restore、build、test                                                      |
| `Directory.Build.props`、`.editorconfig` | 警告視為錯誤、分析器等級、命名規則在建置時檢查                                                |
| `docs/project-context.md`                | 本專案的層級對照與執行方式                                                                    |
| `team-kit/`                              | 課堂上逐步配置進專案的 CLAUDE.md、AGENTS.md、團隊規範、Skills、子 Agent、hook 腳本、OpenSpec 指引；Claude Code 設定放在 `team-kit/claude/`，複製進專案的 `.claude/` |

## 需求環境

.NET 10 SDK、Node.js 20.19 以上、Git for Windows（含 Git Bash）、PowerShell 7、Claude Code CLI。
