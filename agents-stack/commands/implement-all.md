---
description: Batch implement all pending tasks — runs implement → validate → fix cycle automatically
---

There is a subagent available called @batch-implementer that orchestrates the
implement→validate→fix cycle for every pending task in batch mode.

Invoke the batch-implementer subagent now. It will:
1. Read `docs/pipeline/state.json` to verify the implementation phase
2. Read `docs/pipeline/tasks/index.md` for all pending tasks
3. For each pending task (in dependency order):
   - Implement the task via @implementer
   - Validate via @validator
   - Auto-fix minor issues via @fixer
   - Re-validate after fixes
4. Stop the batch if a major issue is found
5. Report final status with next steps

$ARGUMENTS
