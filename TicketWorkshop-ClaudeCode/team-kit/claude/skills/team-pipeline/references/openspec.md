# OpenSpec 工作方式

OpenSpec 負責需求、決策與工作清單；team-pipeline 負責派工、修復、審查與完成判定。

1. 讀現有 baseline 與團隊規範，使用 OpenSpec explore 討論範圍、行為、限制及接受條件。討論時不寫產品程式。
2. 使用 propose 指引產出 openspec/changes/<change>/ 的 proposal.md、specs/<capability>/spec.md、design.md、tasks.md；tasks 即實作 work items。
3. 根據既有 baseline 選擇 ADDED／MODIFIED／REMOVED，不假設每次都是新功能；修復或重構也要說明受影響行為及保持的契約。
4. 執行 `openspec validate <change> --strict`，讓使用者閱讀並確認；格式有效不等於需求正確。
5. 確認後由 team-pipeline 接手，不以 OpenSpec apply 取代子 Agent pipeline。openspec/config.yaml 的 operations.apply.guidance 會停止 apply，請使用者明確呼叫 team-pipeline。需要改接受條件時先重新確認。
6. team-pipeline 回報完成、使用者驗收後，由使用者執行 archive（`/opsx:archive` 或 `openspec archive <change>`）。archive 把本次 delta spec 合併進 openspec/specs，並把 change 移到 openspec/changes/archive/。下一個 change 以 openspec/specs 為 baseline 判斷 ADDED／MODIFIED／REMOVED。主 Agent 不自行 archive。

Tasks 列產品實作與 Coding 可完成的驗證工作，只勾選實際完成項目。兩道獨立 Review 由主 Agent 依流程 Skill 委派，使用子 Agent 的實際回覆判定結果。

使用已安裝的 OpenSpec 與它產生的原生指引（Claude Code 為 `/opsx:explore`、`/opsx:propose`、`/opsx:archive`）；命令名稱與版本以 init 輸出為準。Chat slash command 不在 Terminal 執行。
規格內容屬於當次 change，不能回填到共用 Skill、references 或 Agent 當固定工作。
