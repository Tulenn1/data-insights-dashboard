---
description: Apply surgical fixes for minor validation issues reported by /validate
---

There is a subagent available called @fixer that specializes in applying
minimal, surgical fixes for minor issues found during validation.

Invoke the @fixer subagent now. It will:
1. Read the validation report for the specified task from
   `docs/pipeline/reports/validate/task-<id>.md`
2. Fix only minor issues (single-file, localized changes)
3. Escalate major issues to /planner
4. Run tests to confirm nothing is broken
5. Report what was fixed

$ARGUMENTS
