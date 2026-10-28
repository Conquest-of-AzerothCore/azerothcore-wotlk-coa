# Ruins of Ahn'Qiraj cache restoration

SQL 58 restores three scriptless HAS_LOOT containers, all empty in the supplied loot export.
It embeds all six gear pools and is self-contained; SQL 57 and older cache migrations are not prerequisites.

## Descriptions and selected default policy

| Cache | Depth | Guaranteed items | Independent optional items |
| --- | --- | --- | --- |
| 1278070 Normal AQ20 | 511-535 | Mythic BWL + Normal AQ20 | Mythic Dungeon 11-20 |
| 1278072 Heroic AQ20 | 536-560 | Normal AQ20 | Second Normal AQ20; Heroic AQ20; Mythic Dungeon 11-20 |
| 1278074 Mythic AQ20 | 561-610 | Heroic AQ20 | Mythic AQ20; Mythic Dungeon 21-30 |

Defaults retain the MC/BWL policy: one item per guaranteed family, independent 10% optional family rolls,
and 50% for the second Normal item in the Heroic cache. The latter realizes the advertised Normal AQ20
1-2 range. These quantities and probabilities are CoA choices, not recovered Ascension odds.
Item descriptions establish the advertised families, not the exact original cache item list.

Exact exported descriptions (trailing spaces in labels omitted for Markdown formatting):

    1278070
    Obtained from Manastorm Levels: 511 to 535
    Contains:
    + Mythic Blackwing Lair Gear
    + Normal Ruins of AQ Gear
    Chance to contain:
    + Mythic 11-20 Dungeon Gear

    1278072
    Obtained from Manastorm Levels: 536 to 560
    Contains:
    + Normal Ruins of AQ Gear (1-2)
    Chance to contain:
    + Heroic Ruins of AQ Gear
    + Mythic 11-20 Dungeon Gear

    1278074
    Obtained from Manastorm Levels: 561 to 610
    Contains:
    + Heroic Ruins of AQ Gear
    Chance to contain:
    + Mythic Ruins of AQ Gear
    + Mythic 21-30 Dungeon Gear

## Catalogue evidence and mapping

Normal AQ20 candidates come from the Ascension-specific Classic RuinsofAQ menu and seven referenced
encounter/trash tables: 15348, 15341, 15340, 15370, 15369, 15339 and 15318.
The source contains 290 rows and 201 unique IDs, all present in the supplied item export.
Filtering to epic equippable weapons/armor, RequiredLevel at most 60, yields 144 Normal candidates.
Custom Ascension gear, equipment rewards listed by the catalogue, and its epic trash drops are retained.
Tokens, recipes, currencies, sigils, containers and non-epic items do not enter these equipment pools.

Source: Szyler/AtlasLootAscension, verified 2026-10-07:

- [Items](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/Databases/Items/Classic/Instances.lua)
- [Menu](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/UI/Menus/ClassicInstances.lua)

Item-file Git blob: dd69a91b91e79c7056c78669ee1e2b8e7471d407.
Menu-file Git blob: 0be89e11d314385cc5c3a6fc0a56fdcd4f3bf5ff.

Heroic/Mythic variants match the base name, class, subclass, equipment slot, quality and display model,
with RequiredLevel at most 60. Specific Ruins of Ahn'Qiraj markers take precedence over generic Raid
markers. No equally preferred matches are ambiguous. There are 117 specific Heroic and 117 specific
Mythic matches, plus 7 generic Heroic and 27 generic Mythic matches. Generic mappings rely on item
identity and source catalogue membership; the generic description alone does not establish AQ20 membership.

Twenty epic trash items have no matching Heroic variant in the export. They remain in Normal/Mythic and
are omitted from Heroic. No cross-tier substitute is made:

| Base item ID | Name |
| --- | --- |
| 647 | Destiny |
| 811 | Axe of the Deep Woods |
| 833 | Lifestone |
| 1168 | Skullflame Shield |
| 1263 | Brain Hacker |
| 1443 | Jeweled Amulet of Cainwyn |
| 1728 | Teebu's Blazing Longsword |
| 2099 | Dwarven Hand Cannon |
| 2243 | Hand of Edward the Odd |
| 2244 | Krol Blade |
| 2245 | Helm of Narv |
| 2246 | Myrmidon's Signet |
| 2801 | Blade of Hanna |
| 3475 | Cloak of Flames |
| 14552 | Stockade Pauldrons |
| 14553 | Sash of Mercy |
| 14554 | Cloudkeeper Legplates |
| 14555 | Alcor's Sunrazor |
| 14557 | The Lion Horn of Stormwind |
| 14558 | Lady Maye's Pendant |

Mythic BWL reuses the reviewed SQL 57 mapping. Dungeon mappings reuse the saved 611-base Classic dungeon
catalogue, with exact identity/display matches and rank markers. Each rank 11-30 has 611 unambiguous items.
Normal/Heroic AQ20 use ranks 11-20 only; Mythic AQ20 uses ranks 21-30 only. Plain Mythic and other ranks
are excluded from the ranked pools. Original cache membership and odds have not been fully recovered.

[RUINS_OF_AHNQIRAJ_CACHE_CANDIDATES.csv](RUINS_OF_AHNQIRAJ_CACHE_CANDIDATES.csv) records every assignment,
item ID, base relationship, exact item description, captured metadata and source export line number.

| Owned reference | Family | Candidates |
| --- | --- | --- |
| 9003501 | Normal AQ20 | 144 |
| 9003502 | Heroic AQ20 | 124 |
| 9003503 | Mythic AQ20 | 144 |
| 9003504 | Mythic BWL | 82 |
| 9003505 | Mythic Dungeon 11-20 | 6110 |
| 9003506 | Mythic Dungeon 21-30 | 6110 |

## Runtime and migration

Each family roll has a separate explicit-chance root group. Grouped chances avoid global reference
chance multipliers. The existing scoped OnAfterRefCount guard covers the three AQ20 caches and their
six owned references, preserving one item per successful family roll regardless of reference amount rates
while the module is enabled. Existing stat preference remains within the selected pure gear pool.
The three cache IDs are recognized outside active depth brackets for already-owned/manual grants.

SQL 58 owns only roots 1278070/1278072/1278074 and references 9003501-9003506. It does not update item
names/descriptions, scripts, depth brackets, progression, other loot pools or Mode 1/2 transport.
Preflight checks InnoDB loot tables, three scriptless HAS_LOOT containers, all 12714 captured item
assignments and their exact metadata, six pool counts, namespace ownership, external reference consumers
across all loot stores, and existing loot conditions. Writes are transactional and idempotent.
Each temporary table appears once per statement to avoid MySQL 1137.

Rebuild the module, apply SQL 58 to acore_world, then restart worldserver. CREATE ROUTINE permission is
required. No live database write was performed. SQL 58 does not require rerunning SQL 26 or SQL 57.

## Validation

SQLite checks passed for all 12714 generated SQL/CSV tuples and exact metadata, six pool counts,
rank boundaries with 611 items per rank, ten independent root groups and their configured probabilities,
repeat application and preservation of unrelated BWL rows. The actual metadata predicate rejected
wrong descriptions, level-80 gear, changed display models and wrong quality. Formatting and single
temporary-table references were checked.
SQL formatting, quoting, insert/delete safety and engine checks passed; the directory check flags the
intentional module base migration. C++ checks passed except for pre-existing blank-line warnings in
ManastormRewards.cpp, confirmed unchanged against HEAD.
MySQL procedure execution, C++ compilation and in-game openings remain untested.

Source item dump SHA-256: 3e36f8748b12b89605ec278953ad4c9c3db505757d4bc9a7294ea19c052e243e.
