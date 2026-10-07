# Dedicated Classic ranked dungeon cache restoration

SQL 61 restores four scriptless HAS_LOOT containers, all empty in the supplied loot export.
It embeds four independent gear pools and is self-contained; previous cache migrations are not prerequisites.
These four caches are outside SQL 47's active Classic award catalogue. Restoration does not activate them,
change brackets or replace any current raid cache rewards. Existing/manual copies can use their loot.

## Exported descriptions and selected reconstruction policy

| Cache | Exported depth | Selected gear band | Candidates |
| --- | --- | --- | --- |
| 1278059 Mythic 1-10 | 501-550 | Dungeon ranks 1-10 | 6109 |
| 1278064 Mythic 11-20 | 751-800 | Dungeon ranks 11-20 | 6110 |
| 1278073 Mythic 21-30 | 1301-1350 | Dungeon ranks 21-30 | 6110 |
| 1278082 Mythic 31-40 | 1851-1900 | Dungeon ranks 31-40 | 6110 |

Each opening selects one item from the named band, personalized by the existing stat preference.
This is a CoA reconstruction policy. The wording 'up to' establishes a ceiling, but does not establish
original lower-tier mixing, tier probabilities, quantities or exact cache membership. No lower-band,
plain Mythic, raid or Ascended items are added under this policy. Candidate metadata and rank identity
are supported by the supplied item export and the previously reviewed Classic dungeon catalogue.
Exported depths are historical evidence; SQL 47's active progression remains unchanged.

Exact descriptions:

    1278059
    Manastorm 501 to 550
    Contains gear up to Mythic 1-10!

    1278064
    Manastorm 751 to 800
    Contains gear up to Mythic 11-20!

    1278073
    Manastorm 1301 to 1350
    Contains gear up to Mythic 21-30!

    1278082
    Manastorm 1851 to 1900
    Contains gear up to Mythic levels 31-40!

## Mapping evidence and gap

The saved Normal Dungeon mapping supplies 611 Classic dungeon equipment base identities from the
Ascension-specific AtlasLoot catalogue. Ranked variants match base name, class, subclass, equipment slot
and display model, require at most level 60, have epic quality and carry the exact advertised rank prefix.
Same-name raid and higher-level variants are excluded. Existing rank 11-40 mappings are reused from the
BWL/AQ/Naxx restorations; ranks 1-10 reuse SQL 26's identity rule and ambiguity exclusion.

One unresolved identity: base 22253 Tome of the Lost at Mythic +3 has two exact-name/model/slot matches:

| Item ID | Item level | Exact description |
| --- | --- | --- |
| 8263152 | 71 | @Mythic 3@The title reads "The Brode to Nowhere" |
| 8263154 | 66 | @Mythic 3@The title reads "The Brode to Nowhere" |

Both are excluded rather than guessing the intended variant. Rank 3 has 610 candidates; every other
rank 1-40 has 611. There are no other gaps or equally preferred ambiguities in the selected mapping.
Each candidate is a configured item ID, not an additional item per opening.

[RANKED_DUNGEON_CACHE_CANDIDATES.csv](RANKED_DUNGEON_CACHE_CANDIDATES.csv) records all assignments,
base relationships, exact descriptions, metadata, item-export line numbers and explicit ranks.

Underlying catalogue: Szyler/AtlasLootAscension, verified 2026-10-07:

- [Items](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/Databases/Items/Classic/Instances.lua)
- [Menu](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/UI/Menus/ClassicInstances.lua)

Item-file Git blob: dd69a91b91e79c7056c78669ee1e2b8e7471d407.
Menu-file Git blob: 0be89e11d314385cc5c3a6fc0a56fdcd4f3bf5ff.
Original cache membership and odds have not been fully recovered.

| Owned reference | Family | Candidates |
| --- | --- | --- |
| 9003801 | Mythic Dungeon 1-10 | 6109 |
| 9003802 | Mythic Dungeon 11-20 | 6110 |
| 9003803 | Mythic Dungeon 21-30 | 6110 |
| 9003804 | Mythic Dungeon 31-40 | 6110 |

## Runtime and migration

Each cache has one explicit 100% root group referencing one pure gear band. The scoped OnAfterRefCount
guard preserves one selected item regardless of global reference amount rates while the module is enabled.
Existing stat preference selects within that pool. The four cache IDs are recognized outside active
brackets so already-owned or manually granted copies retain personalized opening.

SQL 61 owns only roots 1278059/1278064/1278073/1278082 and references 9003801-9003804. It does not update
items, scripts, names/descriptions, depth brackets, progression, other loot pools or Mode 1/2 transport.
Preflight checks InnoDB loot tables, four scriptless HAS_LOOT containers, all 24439 captured item
assignments and their exact metadata, four pool counts, namespace ownership, external consumers across
all loot stores and existing loot conditions. Persistent changes are transactional and idempotent.
Each temporary table appears once per statement, avoiding MySQL 1137.

Rebuild the module, apply SQL 61 to acore_world, then restart worldserver. CREATE ROUTINE permission is
required. No live database write was performed. Previous cache migrations do not need rerunning.

## Validation

SQLite checks passed for all 24439 generated SQL/CSV tuples and exact metadata, four pool counts,
rank-band boundaries and the +3 ambiguity exclusion, four guaranteed one-item root groups, repeat
application and preservation of unrelated Naxx rows. The actual metadata predicate rejected wrong
descriptions, level-80 gear, changed display models and wrong quality. The four-container preflight was
checked. Memberships match reviewed SQL 26 and the BWL/AQ40/Naxx CSVs. Formatting and single temporary-table
references were checked.
SQL formatting, quoting, insert/delete safety and engine checks passed; the directory check flags the
intentional module base migration. C++ checks passed except for pre-existing blank-line warnings in
ManastormRewards.cpp, confirmed unchanged against HEAD.
MySQL procedure execution, C++ compilation and in-game openings remain untested.

Source item dump SHA-256: 3e36f8748b12b89605ec278953ad4c9c3db505757d4bc9a7294ea19c052e243e.
