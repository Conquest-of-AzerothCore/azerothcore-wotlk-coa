# General rules

- Configure and build when needed to implement the requested work; prefer focused incremental targets.
- **Never edit SQL files outside `data/sql/updates/pending_db_*/` unless explicitly requested.** `data/sql/base/`,
  `data/sql/archive/`, and `data/sql/updates/db_*/` are immutable.
- Formatting follows `.editorconfig`: UTF-8, LF, max 120 cols, trailing newline, no trailing whitespace; 4-space
  indent for C++ (tabs forbidden), 2-space for JSON/YAML/sh/ts/js.
- Keep ordinary plans and results in the conversation. If a planning document is requested or necessary,
  use `.agents/plans/<task-slug>/` (gitignored); no per-task document is required.
- Use existing tools. Routine edits need no source snapshots, backup folders, receipts, or standalone reports.
  Preserve unique untracked work and use Git diffs for tracked files.
- A source-only task ends with the requested change and its verification. Deployment and in-game acceptance
  are separate scopes. Repeat passing checks only after changes or a specific unresolved concern.
- Everything written to the repository or GitHub (code, commits, branch names, PR titles and bodies, issue
  comments) is English. Talk to the user in their language.

## Comments

- In CoA-owned code, express intent through names, structure and tests; do not add explanatory comments or
  docstrings. Preserve legal notices, tool directives and test generator markers. Scope is
  `src/server/coa/`, `apps/coa-tests/`, `apps/coa-bugreport/`,
  `apps/coa-{dbc,gameplay-test,mechanics,world-content}/`, `tools/` and `.github/scripts/`.
  The `source` stage of `tools/verify_all.py` enforces this for C++ and Python; without `--base` it audits the
  full scope.
- In inherited AzerothCore source, keep existing comments so upstream merges stay clean; change a comment only
  with the code it describes. Add comments there only for non-obvious external constraints or rationale that
  the code cannot express. Preserve legal attribution and machine-consumed directives.

## Values and expectations

- Never invent a value (damage, amount, rate, ID). Read it from the DBC, the DB or the code, or say it is unknown.
- Expected behavior comes from the spell's tooltip first, then the community references listed in
  `.agents/skills/coa-development/references/sources.md`, then the user. The installed DBC, DB and code win
  over a community snapshot; a snapshot value they lack needs its source and date in the commit and PR, and the
  user's approval.
