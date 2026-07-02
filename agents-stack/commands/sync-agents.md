---
description: Regenerate the AGENTS.md template from agents/, commands/, and skills/ metadata
---

Invoke the @manifest-generator subagent now. It will:
1. Scan all agents, commands, and skills in agents-stack/
2. Read models.json for model recommendations
3. Identify auto-generated sections in AGENTS.md
4. Regenerate each section (pipeline table, utility commands, skills list, model config)
5. Show a summary of changes
6. Ask for confirmation before writing

$ARGUMENTS
