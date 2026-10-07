# Blackwing Lair cache restoration

SQL 57 restores three scriptless HAS_LOOT containers, all empty in the supplied loot export. It embeds
all seven gear families and does not require SQL 26, 53, 54 or 55 to be applied first.

## Descriptions and selected default policy

| Cache | Depth range | Guaranteed items | Independent optional items |
| --- | --- | --- | --- |
| 1278066 Normal BWL | 426-450 | Mythic MC + Normal BWL | Mythic Onyxia; Mythic 11-20 Dungeon |
| 1278068 Heroic BWL | 451-475 | Normal BWL | Ascended Onyxia; Heroic BWL; Mythic 11-20 Dungeon |
| 1278069 Mythic BWL | 476-510 | Heroic BWL | Second Heroic BWL; Mythic BWL; Ascended Onyxia; Mythic 11-20 |

Defaults follow the previously retained Molten Core reconstruction policy: one item from each guaranteed
family, 10% independent rolls for optional families, and 50% for the second Heroic BWL item. These quantities
and probabilities are CoA choices, not recovered Ascension odds. Item descriptions establish the families.

Exact exported descriptions:

    1278066
    Obtained from Manastorm Levels: 426 to 450
    Contains:
    + Mythic Molten Core Gear
    + Normal Blackwing Lair Gear
    Chance to contain:
    + Mythic Onyxia Gear
    + Mythic 11-20 Dungeon Gear

    1278068
    Obtained from Manastorm Levels: 451 to 475
    Contains:
    + Normal Blackwing Lair Gear
    Chance to contain:
    + Ascended Onyxia Gear
    + Heroic Blackwing Lair Gear
    + Mythic 11-20 Dungeon Gear

    1278069
    Obtained from Manastorm Levels: 476 to 510
    Contains:
    + Heroic Blackwing Lair Gear (1-2)
    Chance to contain:
    + Mythic Blackwing Lair Gear
    + Ascended Onyxia Gear
    + Mythic 11-20 Dungeon Gear

## Catalogue and mapping evidence

Normal BWL candidates come from the Ascension-specific Classic BlackwingLair menu and its eight referenced
encounter loot tables: 12435, 13020, 12017, 11983, 1014601, 1011981, 14020 and 11583.
The menu uses custom Ascension entries 1014601/1011981 for two of the three dragons; ordinary creature IDs
were not substituted. The catalogue is a reconstruction source for family membership, not recovered cache
loot odds or a complete original cache drop table.

Sources in Szyler/AtlasLootAscension:

- [Items](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/Databases/Items/Classic/Instances.lua)
- [Menu](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/UI/Menus/ClassicInstances.lua)

Verified item-file blob: dd69a91b91e79c7056c78669ee1e2b8e7471d407.
Verified menu-file blob: 0be89e11d314385cc5c3a6fc0a56fdcd4f3bf5ff.

106 unique source IDs exist in the item export. Filtering to epic equippable weapons/armor, RequiredLevel
at most 60, yields 82 Normal BWL candidates. Custom Ascension equipment is retained. Tokens, recipes,
currencies, sigils, containers and non-epic gear are excluded from these equipment leaf pools.

Heroic/Mythic variants match base names, classes, subclasses, equipment slots and epic quality, with
RequiredLevel at most 60 and matching display models. Specific Blackwing Lair prefixes take precedence over
same-name generic Raid prefixes. There are no ambiguous equally preferred matches.

One omission: base 14996 Shadow Flame Legguards has no recovered matching Heroic variant. It remains in
Normal and Mythic pools, and is omitted from Heroic. No alternate tier is substituted.
Eight Heroic and nine Mythic BWL variants use generic Raid markers rather than a specific BWL marker;
these are identity-based mappings whose descriptions alone do not establish raid membership.

[BLACKWING_LAIR_CACHE_CANDIDATES.csv](BLACKWING_LAIR_CACHE_CANDIDATES.csv) records every assignment, item ID,
base relationship, exact description, captured metadata and source item-export line number.

| Owned reference | Family | Candidates |
| --- | --- | --- |
| 9003401 | Normal BWL | 82 |
| 9003402 | Heroic BWL | 81 |
| 9003403 | Mythic BWL | 82 |
| 9003404 | Mythic MC | 106 |
| 9003405 | Mythic Onyxia | 14 |
| 9003406 | Ascended Onyxia | 14 |
| 9003407 | Mythic Dungeon ranks 11-20 | 6110 |

The MC/Onyxia base catalogue and difficulty-preference rules reuse SQL 26. Saved dungeon mappings provide
611 unambiguous items at each rank 11-20. Ranked gear is intentionally included because all three cache
descriptions advertise it. Plain Mythic and ranks 1-10 or above 20 do not enter this ranked family.

## Runtime and migration

Each guaranteed or optional family roll has a separate explicit-chance root group. The core uses the
configured grouped chance without multiplying it by global reference drop-chance rates. The existing
scoped OnAfterRefCount guard now covers these three caches and their owned pools, limiting each successful
family roll to one gear item regardless of reference amount rates while the module is enabled.
Existing stat preference runs within the chosen pure gear leaf pool. The three cache IDs are recognized
outside active depth brackets so already-owned or manually granted copies retain personalization.

SQL 57 owns only the three cache root entries and references 9003401-9003407. It does not update item
names/descriptions, scripts, depth brackets, progression, other loot pools or Mode 1/2 transport.
Preflight validates three scriptless HAS_LOOT containers, 6489 candidate assignments, all captured item
identities and descriptions, seven family counts, InnoDB loot tables, reference namespace ownership and
external consumers across all loot stores, and existing loot conditions. Persistent changes are
transactional and idempotent. Each temporary table appears only once per statement, avoiding MySQL 1137.

Rebuild the module, apply SQL 57 to acore_world, then restart worldserver. CREATE ROUTINE permission is
required, as in the other cache migrations. No live database write was performed.

## Validation

SQLite checks passed for all 6489 generated candidate tuples and exact metadata, seven pool counts,
thirteen independent root groups and their configured probabilities, guaranteed family identities,
611 candidates per rank 11-20, the documented Heroic gap, unrelated cache preservation and repeat
application. Actual metadata predicates rejected wrong descriptions, level-80 gear, display changes and
wrong quality. Source formatting and single temporary-table references were checked.
MySQL procedure execution, C++ compilation and in-game openings remain untested.

SQL formatting, insert/delete safety, quoting and engine checks passed; the directory check flags the
intentional module base migration. C++ checks passed except for pre-existing blank-line warnings in
ManastormRewards.cpp.

Source item dump SHA-256: 3e36f8748b12b89605ec278953ad4c9c3db505757d4bc9a7294ea19c052e243e.
