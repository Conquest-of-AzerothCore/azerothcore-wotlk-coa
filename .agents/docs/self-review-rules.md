# Self-review rules

Use these rules when preparing an actual PR, together with [code-review.md](code-review.md).
Routine local edits need a focused diff review, not a separate review workflow or report.

## Review scope

- Review the final requested changes and their affected consumers. A working-tree diff is a valid review target;
  uncommitted changes do not block review. Do not commit merely to satisfy a review procedure.
- Identify the reviewed commit/diff when publishing a PR review. Re-review only new changes or unresolved findings.
- For shared core C++ and headers, inspect affected callers and lifecycle behavior. For contained content/module
  changes, concentrate on the affected mechanic. For SQL, check selection scope and unintended data changes.

## Validation

- Use relevant existing tests and the affected language's scoped lint. Add tests when a meaningful behavior change
  needs coverage; do not create tests for documentation or trivial edits.
- Stop after the relevant checks pass unless the code changes or a specific concern remains.
- Report known in-game results and their source. If gameplay is untested, say so; do not invent acceptance or
  require a user test before completing a source-only task. Ask for missing results only when needed for the task.
- Client launches still require the user's permission. Deployment remains a separate scope.
