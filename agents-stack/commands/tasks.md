---
description: Decompose plan/ into atomic, ordered, testable tasks. Produces tasks/ directory with index.md + task-NN.md files
---

There is a subagent available called @task-splitter that specializes in
breaking down plans into atomic tasks with test specifications.

Invoke the task-splitter subagent now. It will read section files from
`docs/pipeline/plan/` and produce `docs/pipeline/tasks/index.md` (task index)
plus individual `docs/pipeline/tasks/task-NN.md` files with ordered,
dependency-aware, individually testable tasks.

$ARGUMENTS
