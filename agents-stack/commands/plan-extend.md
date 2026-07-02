---
description: Extend an existing plan with a new requirement — adds extension file to plan/extensions/ without losing prior planning
---

There is a subagent available called @planner that now supports an **append mode**.
When `docs/pipeline/plan/index.md` already exists, the planner reads the
existing plan and creates a new extension file in `docs/pipeline/plan/extensions/`
for the new requirement without modifying the original plan files.

Invoke the @planner subagent with the following instructions:

1. Read the argument: $ARGUMENTS
2. Read `docs/pipeline/plan/index.md` (it should already exist — if not, tell
   the user to run `/planner` first).
3. Read `docs/pipeline/tasks/index.md` and `docs/pipeline/state.json` to
   understand existing task statuses.
4. Enter append mode: clarify the new requirement with the user using the same
   thorough questioning workflow, then create a new extension file as
   `docs/pipeline/plan/extensions/N-<slug>.md`.
5. When done, tell the user to run `/spec` to generate feature specs for the
   extension, then `/tasks` to merge the new extension into the task index.
