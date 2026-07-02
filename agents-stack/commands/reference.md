---
description: Import an external repository reference to docs/references/ — fetches URL + project structure for AI agent context
---

There is a subagent available called @reference-extractor that imports external
repository documentation into `docs/references/`.

Invoke the reference-extractor subagent now. It will:
1. Fetch the repository file tree via GitHub/GitLab API
2. Generate a `.md` file with the URL + filtered project structure
3. Ask if you want to add any notes

Usage:

```bash
opencode run "/reference --repo https://github.com/user/repo"
```

$ARGUMENTS
