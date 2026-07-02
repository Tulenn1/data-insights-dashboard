---
description: Generate Gherkin .feature spec files from plan/ — human-readable specs that drive unit tests
---

There is a subagent available called @spec-writer that specializes in
converting requirement plans into Gherkin feature files as human-readable
specifications.

Invoke the spec-writer subagent now. It will:
1. Read section files from `docs/pipeline/plan/` and `docs/pipeline/features/.specconfig` (if exists)
2. Auto-detect or use the configured language (default: `en`)
3. Group functional requirements into feature files
4. Write `docs/pipeline/features/<domain>/<feature>.feature` with Given/When/Then scenarios
5. Create `docs/pipeline/features/.specconfig` if not present
6. Ask for user approval before marking specs as final

Use `--lang <code>` to override the language (e.g., `--lang es`, `--lang fr`).

$ARGUMENTS
