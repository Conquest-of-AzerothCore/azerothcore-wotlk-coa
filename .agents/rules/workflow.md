# Development workflow

Work in this repository uses the [superpowers](https://github.com/obra/superpowers) plugin for process and the
`coa-development` skill (`.agents/skills/coa-development/SKILL.md`) for this repository's specifics.

## Setup

At the start of a session, check whether the superpowers skills are available (for example
`superpowers:brainstorming` in the skill list). If they are missing, ask the contributor once, interactively,
before other work: "This repository uses the superpowers plugin. Install it now?"

- **Yes:** install it yourself, then tell the contributor whether a restart or `/reload-plugins` is needed.
  - Claude Code: `claude plugin install superpowers@claude-plugins-official --scope project` (the checked-in
    `.claude/settings.json` already enables it and knows the marketplace).
  - Codex and other agents: follow the superpowers README for that agent.
  - If the installation fails, report the error and continue as for **No**.
- **No:** accept it without asking again in this session. Follow the same phases by hand (design before code,
  root cause before fix, evidence before claims).

Every PR states whether superpowers was used and which models worked on it, as
`.agents/skills/coa-development/references/pr-description.md` describes.

## Which process skill

| Work | Process skill first | Then |
|---|---|---|
| New feature, new system, behavior change, multi-file refactor, new tooling | `superpowers:brainstorming` | `superpowers:writing-plans`, then `superpowers:subagent-driven-development` or `superpowers:executing-plans` |
| Bug, reported issue, failing test or scenario, unexpected behavior | `superpowers:systematic-debugging` | `superpowers:test-driven-development` for the regression |
| Issue queue or topic batch | `coa-development` (issue queue), with `superpowers:systematic-debugging` per issue | `superpowers:dispatching-parallel-agents` for independent investigations |
| Before claiming done, committing or opening a PR | `superpowers:verification-before-completion` | `superpowers:requesting-code-review` for larger diffs |
| Branch finished | `superpowers:finishing-a-development-branch` | |

A small, mechanical change with an obvious scope (a typo, a rename, a one-line data fix) does not need
brainstorming; a bug still needs its root cause before a fix.

## Repository overrides

The rules in `.agents/rules/` win where a superpowers skill differs:

- Specs and plans go to `.agents/plans/<task-slug>/` (gitignored) and are not committed, not
  `docs/superpowers/`. Give the user a short overview in the conversation instead of the document.
- Test-driven development: write the regression before or with the fix, but do not build or run the pre-fix tree
  or `main` to watch it fail. Systematic debugging reproduces through effective data, the execution path and
  the report's evidence; the regression proves the fix through `tools/verify_all.py`.
- Verification commands are `tools/verify_all.py` selections only (see `verification.md`).
- Worktrees follow `git-safety.md`; a new worktree needs its own build and `--settings` for `verify_all.py`
  (`docs/coa/verification.md`, Separate worktrees).
- Finishing a branch never merges to `main` locally; it pushes a branch and opens a PR when publication is
  authorized.
