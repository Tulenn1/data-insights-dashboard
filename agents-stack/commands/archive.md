---
description: Archive completed tasks and optionally reset pipeline for fresh cycle
---

There is a subagent available called @task-archiver that archives completed
tasks to reduce file count and index size. It reads the task index, moves
completed task specs to an archive file, and optionally resets the pipeline
for a fresh cycle (starting from Task 1).

Invoke the @task-archiver subagent now.

$ARGUMENTS
