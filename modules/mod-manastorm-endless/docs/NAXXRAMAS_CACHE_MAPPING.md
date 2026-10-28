# Naxxramas cache restoration

SQL 60 restores three scriptless HAS_LOOT containers, all empty in the supplied loot export.
It embeds all six gear pools and is self-contained; SQL 59 and older cache migrations are not prerequisites.

## Descriptions and selected default policy

| Cache | Depth | Guaranteed items | Independent optional items |
| --- | --- | --- | --- |
| 1278079 Normal Naxx | 741-840 | Mythic AQ40 + Normal Naxx | Mythic Dungeon 21-30 |
| 1278081 Heroic Naxx | 841-945 | Normal Naxx | Heroic Naxx; Mythic Dungeon 31-40 |
| 1278083 Mythic Naxx | 946 to -1 | Heroic Naxx | Mythic Naxx; Mythic Dungeon 31-40 |

Defaults retain the MC/BWL/AQ policy: one item per guaranteed family and independent 10% optional family
rolls. Heroic Naxx does not advertise a 1-2 range, so it has no second guaranteed-family item roll.
These quantities and probabilities are CoA choices, not recovered Ascension odds. Item descriptions
establish advertised families, not the exact original cache item list. The exported depth range
946 to -1 is preserved literally; this migration does not change depth brackets.

Exact exported descriptions (trailing spaces in labels omitted for Markdown formatting):

    1278079
    Obtained from Manastorm Levels: 741 to 840
    Contains:
    + Mythic Temple of AQ Gear
    + Normal Naxxramas Gear
    Chance to contain:
    + Mythic 21-30 Dungeon Gear

    1278081
    Obtained from Manastorm Levels: 841 to 945
    Contains:
    + Normal Naxxramas Gear
    Chance to contain:
    + Heroic Naxxramas Gear
    + Mythic 31-40 Dungeon Gear

    1278083
    Obtained from Manastorm Levels: 946 to -1
    Contains:
    + Heroic Naxxramas Gear
    Chance to contain:
    + Mythic Naxxramas Gear
    + Mythic 31-40 Dungeon Gear

## Catalogue evidence and mapping

Normal Naxx candidates come from the Ascension-specific Classic Naxxramas60 menu and sixteen referenced
encounter/trash tables: 16028, 15931, 15932, 15928, 15956, 15953, 15952, 16061, 16060, 30549, 15954,
15936, 16011, 15989, 15990 and 15975. The menu's custom Four Horsemen entry 30549 is retained.
The source contains 381 rows and 179 unique IDs, all present in the supplied item export.
Filtering to epic equippable weapons/armor, RequiredLevel at most 60, yields 129 Normal candidates.
Custom Ascension gear, equipment rewards listed by the catalogue and its epic trash drops are retained.
Tokens, recipes, currencies, sigils, containers and non-epic items do not enter these equipment pools.
This is the Classic catalogue; WotLK Naxxramas level-80 gear is not included.

Source: Szyler/AtlasLootAscension, verified 2026-10-07:

- [Items](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/Databases/Items/Classic/Instances.lua)
- [Menu](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/UI/Menus/ClassicInstances.lua)

Item-file Git blob: dd69a91b91e79c7056c78669ee1e2b8e7471d407.
Menu-file Git blob: 0be89e11d314385cc5c3a6fc0a56fdcd4f3bf5ff.

Heroic/Mythic variants match base name, class, subclass, equipment slot, quality and display model,
with RequiredLevel at most 60. Specific Naxxramas markers take precedence over generic Raid markers.
No equally preferred matches are ambiguous. There are 102 specific Heroic and 102 specific Mythic
matches, plus 7 generic Heroic and 27 generic Mythic matches. Generic mappings rely on item identity
and source catalogue membership; a generic description alone does not establish Naxx membership.
Ascended variants are excluded from these three raid difficulty pools.

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

Mythic AQ40 reuses the reviewed SQL 59 mapping. Dungeon mappings reuse the saved 611-base Classic dungeon
catalogue, with exact identity/display matches and rank markers. Each rank 21-40 has 611 unambiguous items.
Normal Naxx uses ranks 21-30 only; Heroic/Mythic Naxx use ranks 31-40 only. Plain Mythic and other ranks
are excluded. Original cache membership and odds have not been fully recovered.

[NAXXRAMAS_CACHE_CANDIDATES.csv](NAXXRAMAS_CACHE_CANDIDATES.csv) records every assignment, item ID,
base relationship, exact item description, captured metadata and source export line number.

| Owned reference | Family | Candidates |
| --- | --- | --- |
| 9003701 | Normal Naxxramas | 129 |
| 9003702 | Heroic Naxxramas | 109 |
| 9003703 | Mythic Naxxramas | 129 |
| 9003704 | Mythic AQ40 | 139 |
| 9003705 | Mythic Dungeon 21-30 | 6110 |
| 9003706 | Mythic Dungeon 31-40 | 6110 |

## Runtime and migration

Each family roll has a separate explicit-chance root group. Grouped chances avoid global reference
chance multipliers. The existing scoped OnAfterRefCount guard covers the three Naxx caches and their
six owned references, preserving one item per successful family roll regardless of reference amount rates
while the module is enabled. Existing stat preference remains within the selected pure gear pool.
The three cache IDs are recognized outside active depth brackets for already-owned/manual grants.

SQL 60 owns only roots 1278079/1278081/1278083 and references 9003701-9003706. It does not update item
names/descriptions, scripts, depth brackets, progression, other loot pools or Mode 1/2 transport.
Preflight checks InnoDB loot tables, three scriptless HAS_LOOT containers, all 12726 captured item
assignments and their exact metadata, six pool counts, namespace ownership, external reference consumers
across all loot stores, and existing loot conditions. Writes are transactional and idempotent.
Each temporary table appears once per statement to avoid MySQL 1137.

Rebuild the module, apply SQL 60 to acore_world, then restart worldserver. CREATE ROUTINE permission is
required. No live database write was performed. SQL 60 does not require rerunning SQL 26, 57, 58 or 59.

## Validation

SQLite checks passed for all 12726 generated SQL/CSV tuples and exact metadata, six pool counts,
rank boundaries with 611 items per rank, nine independent root groups and their configured probabilities,
repeat application and preservation of unrelated AQ40 rows. The actual metadata predicate rejected
wrong descriptions, level-80 gear, changed display models and wrong quality. Reused Mythic AQ40 and
ranked 21-30 dungeon memberships match the SQL 59 CSV. Heroic gaps and excluded difficulties were
checked. Formatting and single temporary-table references were checked.
SQL formatting, quoting, insert/delete safety and engine checks passed; the directory check flags the
intentional module base migration. C++ checks passed except for pre-existing blank-line warnings in
ManastormRewards.cpp, confirmed unchanged against HEAD.
MySQL procedure execution, C++ compilation and in-game openings remain untested.

Source item dump SHA-256: 3e36f8748b12b89605ec278953ad4c9c3db505757d4bc9a7294ea19c052e243e.
