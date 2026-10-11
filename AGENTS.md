# AGENTS.md

AzerothCore is a C++ MMORPG server emulator for World of Warcraft 3.3.5a (WotLK), built with CMake, backed by MySQL.

## Agent rules

- Configure and build when needed to implement the requested work; prefer focused incremental targets.
- **Never edit SQL files outside `data/sql/updates/pending_db_*/` unless explicitly requested.** `data/sql/base/`, `data/sql/archive/`, and `data/sql/updates/db_*/` are immutable.
- Formatting follows `.editorconfig`: UTF-8, LF, max 120 cols, trailing newline, no trailing whitespace; 4-space indent for C++ (tabs forbidden), 2-space for JSON/YAML/sh/ts/js.
- Keep ordinary plans and results in the conversation. If a planning document is requested or necessary,
  use `.agents/plans/<task-slug>/` (gitignored); no per-task document is required.
- Use existing tools. Routine edits need no source snapshots, backup folders, receipts, or standalone reports.
  Preserve unique untracked work and use Git diffs for tracked files.
- A source-only task ends with the requested change and its verification. Deployment and in-game acceptance
  are separate scopes. Repeat passing checks only after changes or a specific unresolved concern.
- In CoA-owned code, express intent through names, structure and tests; do not add explanatory comments or
  docstrings. Preserve legal notices, tool directives and test generator markers. Scope is
  `src/server/coa/`, `apps/coa-tests/`, `apps/coa-bugreport/`,
  `apps/coa-{dbc,gameplay-test,mechanics,world-content}/`, `tools/` and `.github/scripts/`.
  The `source` stage of `tools/verify_all.py` enforces this for C++ and Python; without `--base` it audits the
  full scope.
- In inherited AzerothCore source, keep existing comments so upstream merges stay clean; change a comment only
  with the code it describes. Add comments there only for non-obvious external constraints or rationale that
  the code cannot express. Preserve legal attribution and machine-consumed directives.

## Investigating reported defects

Follow this sequence within the task's authorized scope:
**Report → inspect effective data → establish expected behavior → reproduce → minimal fix → verification → PR.**

- Treat the report as evidence to investigate. For spells and quests, inspect effective DBC/SQL data, acquisition
  and the execution path using the inspector and mechanic map. Derive expectations independently of the current
  implementation and use a metric that can distinguish correct behavior from the reported failure.
- Before changing gameplay, classify the finding as **confirmed defect**, **already works**, **incorrect test**,
  or **uncertain expectation**. Correct a faulty test; preserve evidence of working behavior; keep unresolved
  expectations explicit. Apply a gameplay fix only to an established defect.
- Seek a focused reproduction and a regression that fails before the fix and passes after it, both run through
  `tools/verify_all.py`. State when runtime reproduction is unavailable (an `unavailable` gameplay stage);
  explain the missing prerequisites and complete the remaining stages. Report their actual scope.
- Review the final diff. Continue to a PR when publication is part of the requested workflow; a local edit alone
  does not authorize a push or PR. Use the issue-to-PR skill for an explicitly requested issue queue workflow.
- In existing task/PR results, summarize available time from investigation start to verified outcome, observed
  regressions, flaky checks (different outcomes with unchanged inputs), and required human corrections.
  Mark unavailable measurements as unknown; do not infer zero or create separate tracking files for routine work.

## Verification

- Freeze the fetched `origin/main` revision when starting PR qualification and record the tested base and
  candidate. Keep the checkout stable while checks run. Review later main changes for relevance before
  integrating them: rebuild or repeat verification only when they affect the changed behavior, its callers,
  build interfaces or effective data, or when an actual failure requires it. Unrelated main updates do not
  restart qualification or delay publication. Finish in-flight checks before integrating relevant updates,
  reuse existing build artifacts, and reverify the affected scope. After required checks pass, publish against
  the recorded base instead of repeatedly chasing the newest main revision. If the user requests publication
  while checks remain pending, open a draft PR and state the pending verification explicitly.
- When resuming an empty unpublished branch, advance its ref to the fetched base before switching, after
  checking ancestry and preserving stashes, or create a fresh branch at that base. Avoid checking out an old
  tree and then fast-forwarding: that touches unchanged source and headers and invalidates incremental builds.
- Verify changes only with `python -B tools/verify_all.py` ([guide](docs/coa/verification.md)). It runs the
  source checks, build, unit tests, Python test scripts, `apps/coa-tests` harnesses and gameplay scenarios. Do not
  run `check_source.py`, `ctest`, test scripts, harnesses, `run.py run` or `batch.py` yourself; where a guide
  names one, use the matching selection (`--stages harness --harness <name>`, `--stages source`).
- While iterating, pair `--stages` with a focus filter (`--scenario`/`--spell`/`--quest`/`--query`, `--harness`)
  and include `build` whenever sources changed. Before a PR, or when full verification is requested, run every
  stage with the PR base: `python -B tools/verify_all.py --base origin/main`.
- Leave `--jobs` unset: the default is the CPU count, and fewer jobs only slow the build (a measured replay of
  1,416 compiles took 700 s at `--jobs 6` against 549 s at 10 or 14).
- The `codestyle-cpp.py`/`codestyle-sql.py --files` linters are separate; still run them on changed C++ and SQL.
- Report the final `VERIFY ALL: PASSED|FAILED|INCOMPLETE` line with its `report.json`, the stages that ran,
  unavailable or blocked scope with reasons, and any `batch_sensitive` scenarios. Only `PASSED` is a pass, and
  only for what ran. A full run is not yet all green on any setup; classify each failure or unavailable item as a
  documented prerequisite, pre-existing on the base, acceleration-specific (a real-clock reference run passes it)
  or new ([full runs](docs/coa/verification.md#full-runs)). A new failure blocks a PR.
- Gameplay verification runs accelerated only by default: fix fast failures before accepting a batch.
  Slower same-server retries require `--gameplay-real-pace-rerun`; report their `acceleration_sensitive` ids as
  diagnostic-only passes. A passing retry alone does not prove a clock dependency. Confirm a repeatable timing
  defect with a focused `--gameplay-clock real` reference while repairing it, then use accelerated verification
  ([accelerated mode](docs/coa/verification.md#accelerated-single-server-mode)).
- `run.py validate`, `catalog.py` and `workflow.py` remain authoring and discovery tools, not verification.

## Task references

Read the relevant sections when needed for the work. Do not read every guide or turn examples into extra tasks.

- CMake configuration/build → `.agents/docs/build.md`
- Verification setup, stages, selection, outputs and gameplay queue-mode limits → `docs/coa/verification.md`
- Writing or modifying C++ → `.agents/docs/cpp-guidelines.md`
  - Script work (under `src/server/scripts/`) → also `.agents/docs/cpp-scripts.md`
- Creating or modifying SQL → `.agents/docs/sql-guidelines.md`
  - SmartAI work (`smart_scripts` data) → also `.agents/docs/cpp-scripts.md`
- Reviewing a changeset or PR → `.agents/docs/code-review.md`
- Preparing an actual PR → `.agents/docs/self-review-rules.md`
- Requested issue queue or topic fixes (class mechanics, quests, crashes, etc.) →
  `.agents/skills/coa-fix-issues/SKILL.md` (topic requests default to 32 issues and one PR per batch)
- Subsystem-specific questions → the relevant section in `.agents/docs/systems/`
- Ascension damage/healing, AP/RAP/SP coefficients, triggered spells or tooltip parity →
  `.agents/docs/systems/ascension-spell-parity.md`
- DBC record retrieval, links, provenance or data comparison → `apps/coa-dbc/README.md` (`coa-dbc-viewer`, JSON CLI)
- Spell/quest ranks, acquisition, expected behavior, execution paths and regression links →
  `apps/coa-mechanics/README.md` (compact mechanic maps)
- Finding gameplay regression scenarios or checking recorded results → `apps/coa-gameplay-test/README.md`
- Scoped source checks (boundaries, registrations, tooling regressions) →
  `python -B tools/verify_all.py --stages source --base <ref>`; `report.json` and `source.log` list the suites
  it selected (`--plan` shows only the command).
- SQL change boundaries → the `source` stage against `--base <ref>`; CI exceptions need a maintainer's
  `sql-change-authorized` PR label. A label does not replace the task's explicit SQL authorization.
- Ascension race/class availability or character creation → `.agents/docs/systems/ascension-character-creation.md`
- CoA talent points, ranks, specializations or the talent window's state → `.agents/docs/systems/ascension-talents.md`
- Capturing a lesson or adding/updating agent docs → `.agents/docs/README.md`

## Repository layout

- `src/common/` — networking (Asio), crypto, config, logging, shared utilities.
- `src/server/game/` — core gameplay; compiled into worldserver.
- `src/server/scripts/` — content scripts grouped by region (`EasternKingdoms/`, `Northrend/`, …), class (`Spells/spell_mage.cpp`, …), and domain (`Commands/`, `Pet/`, `OutdoorPvP/`, `World/`).
- `src/server/database/` — DB abstraction and schema updater.
- `src/server/shared/` — code shared by auth and world servers.
- `src/server/apps/{authserver,worldserver}/` — entry points (ports 3724 and 8085).
- `src/test/` — unit tests + mocks.
- `data/sql/` — `base/` (historical schema), `updates/db_*/` (merged), `updates/pending_db_*/` (in-flight), `custom/` (gitignored).
- `modules/` — external modules (see below).
- `apps/` — helper scripts; `apps/codestyle/` holds the lint scripts.
- `conf/dist/` — distributed config templates; `conf/*.conf` is gitignored.
- `deps/` — vendored third-party dependencies.

## Modules

External modules live in `modules/`, each with its sources in `src/`. Disable one with
`-DMODULE_<DIRECTORY>=disabled`, the directory name in upper case with its hyphens (for example
`-DMODULE_MOD-SPELLBOOK=disabled`). See `modules/how_to_make_a_module.md`.

In this fork, CoA is a required server component in `src/server/coa/`, with focused tests in
`apps/coa-tests/`. `modules/mod-ascension/data/sql/` keeps its historical SQL migrations only.
`origin` is the CoA fork; `upstream` is the original AzerothCore
repository. Fetching upstream is separate from reviewing, merging, building or deploying its changes.

## Maintaining guidance

Keep only stable conventions and essential routing here. Update guidance when requested or when a durable
correction is needed; do not automatically offer lesson capture, install skills, or append task histories.
