# AGENTS.md

AzerothCore is a C++ MMORPG server emulator for World of Warcraft 3.3.5a (WotLK), built with CMake, backed by MySQL.
This fork implements Conquest of Azeroth (CoA).

## Rules

Read every rule file before starting work; they apply to all tasks. Claude Code imports them through the
references below.

- General rules, comments and expected values → @.agents/rules/general.md
- Development workflow, superpowers process skills and their repository overrides → @.agents/rules/workflow.md
- Investigating reported defects → @.agents/rules/defects.md
- Verification through `tools/verify_all.py` → @.agents/rules/verification.md
- Git safety, branches, worktrees and ownership → @.agents/rules/git-safety.md

## Skill

`.agents/skills/coa-development/SKILL.md` is the repository's development skill: task routing, the issue queue
workflow, gameplay scenarios, PR descriptions, the CoA Knowledge MCP and the optional guide tooling.

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
  `.agents/skills/coa-development/references/issue-queue.md` (topic requests default to 32 issues and one PR per
  batch)
- Subsystem-specific questions → the relevant section in `.agents/docs/systems/`
- Ascension damage/healing, AP/RAP/SP coefficients, triggered spells or tooltip parity →
  `.agents/docs/systems/ascension-spell-parity.md`
- Warcraft Reborn spell twins, namesakes, `GetSpellTwinFor` or stock code running for Reborn spells →
  `.agents/docs/systems/warcraft-reborn-spell-twins.md`
- DBC record retrieval, links, provenance or data comparison → `apps/coa-dbc/README.md` (`coa-dbc-viewer`, JSON CLI)
- Spell/quest ranks, acquisition, expected behavior, execution paths and regression links →
  `apps/coa-mechanics/README.md` (compact mechanic maps)
- Finding gameplay regression scenarios or checking recorded results → `apps/coa-gameplay-test/README.md`
- Class conformance (tooltip → behaviour proof per class) → `docs/coa/class-conformance.md`
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
- `src/server/scripts/` — content scripts grouped by region (`EasternKingdoms/`, `Northrend/`, …), class
  (`Spells/spell_mage.cpp`, …), and domain (`Commands/`, `Pet/`, `OutdoorPvP/`, `World/`).
- `src/server/coa/` — the CoA server component.
- `src/server/database/` — DB abstraction and schema updater.
- `src/server/shared/` — code shared by auth and world servers.
- `src/server/apps/{authserver,worldserver}/` — entry points (ports 3724 and 8085).
- `src/test/` — unit tests + mocks.
- `data/sql/` — `base/` (historical schema), `updates/db_*/` (merged), `updates/pending_db_*/` (in-flight),
  `custom/` (gitignored).
- `modules/` — external modules (see below).
- `apps/` — helper scripts; `apps/codestyle/` holds the lint scripts; `apps/coa-*` hold CoA tooling and tests.
- `conf/dist/` — distributed config templates; `conf/*.conf` is gitignored.
- `deps/` — vendored third-party dependencies.
- `.agents/` — agent rules, skills and docs ([README](.agents/README.md)); `.claude/` — Claude Code entry points.

## Modules

External modules live in `modules/`, each with its sources in `src/`. Disable one with
`-DMODULE_<DIRECTORY>=disabled`, the directory name in upper case with its hyphens (for example
`-DMODULE_MOD-SPELLBOOK=disabled`). See `modules/how_to_make_a_module.md`.

In this fork, CoA is a required server component in `src/server/coa/`, with focused tests in
`apps/coa-tests/`. `modules/mod-ascension/data/sql/` keeps its historical SQL migrations only.
`origin` is the CoA fork; `upstream` is the original AzerothCore
repository. Fetching upstream is separate from reviewing, merging, building or deploying its changes.

## Maintaining guidance

Keep only stable conventions and essential routing here; rules belong in `.agents/rules/`, task guides in
`.agents/docs/`, workflows in the skill. Update guidance when requested or when a durable correction is needed;
do not automatically offer lesson capture, install skills, or append task histories.
