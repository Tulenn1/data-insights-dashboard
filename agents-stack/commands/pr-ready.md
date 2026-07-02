---
description: Run tests, create a commit, and open a pull request with results summary
---

There is a subagent available called @pr-creator that specializes in validating
changes, running tests, and creating pull requests.

Invoke the pr-creator subagent now. It will:
1. Detect the remote base branch automatically
2. Require a new working branch if the current branch is the base branch, `main`, or `master`
3. Run the full test suite and stop with a failure report if any test fails
4. Summarize the changes and create a conventional commit only if tests pass 100%
5. Check for conflicts with the detected base branch
6. Create a new PR or comment on the existing PR for the current branch without replacing its body

$ARGUMENTS
