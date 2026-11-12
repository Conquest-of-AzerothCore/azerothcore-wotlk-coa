# Git safety

Applies to every agent working in this repository and to every agent it dispatches.

- Name branches `<type>/<short-name>` with the Conventional Commit type of the change (`fix/`, `feat/`, `chore/`,
  `docs/`, `test/`, `refactor/`), never after the agent or tool (`codex/`, `claude/`).
- Create branches from freshly fetched `origin/main`, never from a local `main`. Never push to `main` or
  `upstream`, never force-push, never merge a PR unless the user asks.
- Never rewrite committed work: no `git reset` in any mode, no `git rebase`, no forced ref move over commits you
  did not create in this session. No `git clean -fd`, no tree-wide `git checkout -- .`/`git restore .`, no
  `git gc --prune=now`, no `git reflog expire`.
- `git commit --amend` only on an unpublished commit you made yourself in this session. Follow-ups to published
  work are new, tested, scoped commits.
- Before any operation that moves a branch tip over commits worth keeping, create a real ref
  (`git branch backup/<task>-<what> <sha>`); delete it once the branch is verifiably correct and report one left
  behind. Only committed content is protected: commit early rather than holding work in the working tree.
- A "before" state is never rebuilt by undoing history. Use `git stash` or a throwaway worktree, and remember the
  verification rules: no pre-fix tree runs just to show a regression failing.
- One worktree per implementing agent. A dispatched implementer works in its own `git worktree` on its own branch,
  never in the main checkout or another agent's worktree; name the path and branch in the dispatch prompt and
  forbid every other path. Only the controller commits to shared branches, pushes, and writes to GitHub.
- One agent owns each build directory, database and gameplay stage at a time. Never run two builds or two
  gameplay stages in the same build directory; check for running `ninja`/`cmake`/`cl` processes first.
- A `Fixes #N` line belongs only on a commit whose issue was proved fixed. A reverted attempt leaves no `Fixes`
  line anywhere, including on the revert.
- Remove a worktree once its PR is pushed and nothing is left to do in it, after confirming it has no uncommitted,
  untracked or unpushed work. Report a worktree you could not remove; never force it.
