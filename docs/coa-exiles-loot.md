# Exiles Blackrock Spire loot slice

This migration adds 35 source-visible drops for six existing creatures: Rookery Whelp (10161),
Halycon (10220), Solakar Flamewreath (10264), Gizrul the Slavener (10268), Urok Doomhowl (10584),
and Mother Smolderweb (10596). Examples include Draconic Warhorn: Rookery Whelp (1180298) at 1%,
Sigil of Halycon (59882) at 1%, and Worldforged Key Fragment (97730) at 6%.

These are partial visible loot lists. Of 15,238 drop-bearing pages, 11,116 contain exactly 20 rows
and none exceeds 20. Halycon and Mother Smolderweb are capped. Missing source rows are never removals.
Probabilities are rendered percentages with observed counts of zero, not measured drop rates.

New rows use Reference=0, QuestRequired=0, LootMode=1, GroupId=0, MinCount=MaxCount=1. These are
explicit reconstruction defaults; the source does not specify groups, modes, quest flags or stacks.
Existing rows, exact probabilities, groups, references, stacks and comments are preserved.
The only creature field changed is lootid=entry when a matching creature currently has lootid=0
and that entry has no loot rows or other owners. No templates or spawns are added.

The planner rejects shared/redirected loot, reference templates, conditional loot, duplicate source
item keys, unknown/zero chances, missing items, name conflicts/stubs, and quest-sensitive items.
Quest sensitivity includes class 12, Bonding 4, startquest, all six quest RequiredItemId slots and
all four ItemDrop slots. Runtime checks repeat the creature ownership, references, condition and
quest-item checks, so a changed target can safely skip rows. Verify actual rows after application.

## Reproduce

Python 3.10+, standard library only. Provide the locally held npcs.jsonl.gz and JSON arrays exported
from the target world as creature_template.json, item_template.json, creature_loot_template.json,
quest_template.json and conditions.json. The planner accesses explicit named columns and refuses
missing required columns. Item exports need entry, name, class, startquest and Bonding; creature
exports need entry, name and lootid. Loot/condition/quest exports retain their schema column names.
No input archive, catalog, database export or credentials belong in this repository.

```
python -B tools/coa_loot_sql.py --npcs /local/npcs.jsonl.gz --baseline /local/exports \
  --creatures 10161,10220,10264,10268,10584,10596 --output /local/loot.sql --report /local/report.json
python -B apps/test-framework/test_coa_loot_generator.py -v
python -B apps/test-framework/test_coa_loot_migrations.py --mysql-bin /local/mysql/bin
```

The migration test uses the repository's disposable MySQL lifecycle: temporary datadir, unique
socket/named pipe, no TCP listener, automatic shutdown/cleanup. Passing --before-ref c3beca68b makes
the named-drop test fail because that revision does not supply the migration.

## Validation and provenance

The six-creature migration was applied twice against a separate copy of the preserved CoA world:
exactly the planned 35 Entry/Item pairs appeared, all 93,662 preexisting loot rows remained identical,
and the second application left both loot and creature tables identical to the first application.
The source snapshot contains Halycon / Opulent Robes (14284, 0.01%) and Mother Smolderweb /
Sigil of Mother Smolderweb (59921, 1%) among the verified additions.

Source: the db.exil.es third-party HTML mirror crawled 2026-08-29 and published by Duff-SPP.
Archive SHA256: 6bcecd0faa6c2e7084d8015e1d931431c30e3013a9122810d593868196a3578b.
Parsed NPC stream SHA256: ae86f84db5eab26450db7274049f16d3e8d85f612a488f61bdd0d69b4ab95e54.
The API specification's AGPL-3.0-or-later label covers software; no data license is asserted.
Only the derived SQL and conversion/test source are included. Applied SQL, credentials, profiles,
client JSON and game archives are unchanged/excluded.

No in-game validation has occurred. Base c3beca68b compiled successfully using CMake 3.31,
OpenSSL 3.5.8, eight jobs and BelowNormal priority; nothing was installed. Full C++ lint passed.
All unchanged SQL lint check functions pass on the migration. The full repository SQL linter cannot
finish because it fetches the absent origin/master branch; that existing entry-point limitation is
reported separately from the contribution's SQL validation.
