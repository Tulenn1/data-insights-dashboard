---
description: Generate or update project context docs (overview, tech stack, roadmap) to onboard AI agents about your project's domain
---

There is a subagent available called @context-generator that generates and
maintains structured business/domain documentation for this project.

Invoke the context-generator subagent now. It will:
1. If `docs/context/` doesn't exist: interactive Q&A for overview, tech stack, and roadmap sections
2. If `docs/context/` exists: update mode — shows current content, asks what changed
3. With `--add <name>`: adds a new custom section (e.g., `--add domain-model`)

After generation, the @planner will automatically read this context if it exists.

$ARGUMENTS
