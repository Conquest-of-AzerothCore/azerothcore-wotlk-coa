# SQL deployment completeness review

Initial review: 2026-10-08. This is an open deployment audit, not a clean-install certification.

## Findings requiring resolution before a complete deployment claim

- Module SQL 00 creates `manastorm_segment`, but the numbered module SQL does not insert
  the exported stage catalogue. Later migrations update existing stage IDs. A documented
  baseline seed or explicit prerequisite must supply those rows.
- `Creature_template.sql` supplies Heart 900025 and Manabomb 663028 through plain INSERTs,
  including schema-qualified `acore_world` targets and a NULL model VerifiedBuild value.
  NULL VerifiedBuild is allowed by the current model-table schema. Plain INSERTs still need
  ordering and repeat-application review; NULL alone is not a defect.
- Both cache and open-world migrations use prefix 55. Deployment instructions must use
  complete filenames, rather than relying on a numeric range or counting gaps.
- Some migrations depend on existing custom item templates and other data. Presence of
  reconstructed loot SQL does not establish that all referenced templates are packaged.
- Saved October 1/4/7 exports cannot certify later manual database changes.

## Required verification

1. Inventory tracked world and character SQL by full filename, purpose and prerequisites.
   Separate audits, staged content, optional operations and required migrations.
2. Capture a current working-world snapshot, preserving all `manastorm_*` tables and updater
   history. Preserve current creature/template/model/addon/spell/SmartAI, spawn, teleport,
   item/loot/condition, vendor and gameobject data for relationship comparisons.
3. On an isolated database with the intended target-core baseline, apply the documented
   repository installation sequence. Do not use the working server for this test.
4. Compare module-owned rows and referenced dependencies with the working snapshot.
   Identify missing identities, changed fields and external baseline dependencies separately.
   Exclude character progression and unrelated world customizations from module seeds.
5. Author reviewed migrations for intended manual additions; avoid importing full unrelated
   tables, credentials, character data or destructive dump DROP TABLE statements.
6. Verify prerequisite ordering, target schemas, updater discovery, reapplication where
   promised, and referential integrity. Then validate stage spawning/completion in-game.

## Evidence available now

Numbered and unnumbered SQL under `data/sql/db-world/base`, five character migrations,
the module README and core updater source; supplied `ManasstormSQLsASRequest.sql`,
`Requested.sql`, `LastRequirements.sql`, `manastorm_world_live_2026-10-01.sql`, item and loot exports.
These support historical comparisons but are not a current live snapshot.

No database was modified, no clean-install execution was performed, and no completeness
guarantee is made by this initial review.

## Fresh database dependency audit

The supplied world snapshot is dated 2026-10-08 14:28:30. It was parsed as data without
executing dump statements. Character data was inspected for module schema presence only;
no character records are included in the audit artifacts.

Verified against this snapshot:

- All 38 extracted direct creature references and configured affix-helper dependencies
  have templates and models. Standard dungeon creatures are target-core baseline dependencies.
- All 12 configured affix helper identities are present and supplied by module SQL 04/22
  and the tracked Heart/Manabomb file. No missing summon-helper identity was found.
- All 124 enabled stage objectives have creature templates; their teleport IDs exist.
- All 1,704 authored segment-spawn rows reference existing creature GUIDs.
- The seven module character tables are present. This is not a complete column/index replay test.
- The six Manastorm spell bindings are present. Matrix 93309 and Escape 93311 are supplied by
  tracked core migration `data/sql/updates/pending_db_world/rev_20260920_00_manastorm_shared_tools.sql`;
  it must be included in the PR alongside the module. Other bindings are in module SQL.
- Read-only reference Spell.dbc audit found a 683-spell dependency closure, including
  transitive EffectTriggerSpell references. All those spell IDs exist. Its 33 summon effects
  use 13 distinct creature templates, all present in the fresh SQL snapshot. This validates
  ID dependencies, not complete spell mechanics or the actual deployment's loaded DBC files.
- Support spell range starting 1300400 is synthesized by `ManastormMobilityClient.cpp`.
  Its absence from reference Spell.dbc is intentional and requires no DBC edits.

Artifacts: `SQL_CREATURE_DEPENDENCY_AUDIT.csv` and `SQL_SPELL_SUMMON_DEPENDENCY_AUDIT.csv`.

The remaining packaging gap is baseline data, especially the 1,017 exported segment rows
and their existing world prerequisites. Later UPDATE migrations do not recreate them.
Database existence and module migration coverage must not be conflated.

One deliberate fallback differs from the working database: SQL 14's Treasure Keeper
10111377 is hostile faction 14 / rank 1 / type 7, while this snapshot retains faction 35 /
rank 0 / type 12. SQL 14 uses INSERT IGNORE, so both installs can retain different metadata.
This needs an explicit intended-behavior decision before promising identical installations;
the audit does not overwrite the original/template fallback automatically.

The core updater recursively discovers SQL below a module's `data/sql/db-world` directory.
Full dumps were therefore moved into ignored `.agents/plans/manastorm-db-audit/`, retaining
their filenames and contents outside migration discovery. They must not be committed or used
as an installation migration. No live DB changes, builds or DBC edits were performed.

## Resolved packaging differences

SQL 65 now packages Matrix/Escape/Potion bindings inside the module. The older tracked core
binding migration can coexist: both preserve unrelated bindings and install the same owners.
SQL 14's Treasure Keeper fallback now matches the working snapshot's metadata; SQL 65 aligns
existing older fallback rows as well. Apply SQL 65 after SQL 14/28; no rebuild is required.
Its statements passed a twice-applied SQLite check for ownership, metadata and unrelated-row
preservation. This is not a live MySQL execution test.
