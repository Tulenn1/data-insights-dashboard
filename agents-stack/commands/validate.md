---
description: Validate an implemented task against its plan, run tests, and classify issues
---

There is a subagent available called @validator that specializes in
validating implemented tasks against their plan specifications.

Invoke the @validator subagent now. It will:
1. Read the task from `docs/pipeline/tasks/task-<N>.md`
2. Check files, tests, and test results
3. Cross-reference with relevant section files in `docs/pipeline/plan/`
4. Check spec scenario coverage from `docs/pipeline/features/`
5. Classify issues as minor (fixable by @fixer) or major (needs /planner)
6. Produce a structured validation report with next steps

$ARGUMENTS
