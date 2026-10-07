# Classic Zul'Gurub cache restoration

SQL 54 restores the three scriptless HAS_LOOT containers below. All are empty in the supplied loot export;
this is not a live database query. Their RequiredLevel is 60.

| Cache | Exported depth range | Guaranteed families | Optional families |
| --- | --- | --- | --- |
| 1278052 Zul'Gurub | 106-145 | Heroic Dungeon; Normal ZG | None |
| 1278053 Heroic Zul'Gurub | 146-185 | Normal ZG | Heroic ZG |
| 1278055 Mythic Zul'Gurub | 186-220 | Heroic ZG | Mythic ZG; Mythic Dungeon |

Exact exported descriptions:

    1278052
    Obtained from Manastorm Levels: 106 to 145
    Contains:
    + Heroic Dungeon Gear
    + Normal Zul'Gurub Gear

    1278053
    Obtained from Manastorm Levels: 146 to 185
    Contains:
    + Normal Zul'Gurub Gear
    Chance to contain:
    + Heroic Zul'Gurub Gear

    1278055
    Obtained from Manastorm Levels: 186 to 220
    Contains:
    + Heroic Zul'Gurub Gear
    Chance to contain:
    + Mythic Zul'Gurub Gear
    + Mythic Dungeon Gear

## Reconstruction policy

The chosen default is one item from each guaranteed family and an independent 25% roll for each optional
family. The descriptions identify families but do not establish original quantities or probabilities.
These quantities and odds are CoA reconstruction policy, not recovered Ascension behavior.

1278052 awards two items. 1278053 awards one or two. 1278055 awards one to three; both bonus rolls can succeed.
Each family uses its own explicit-chance loot group. Grouped reference rolls avoid global reference chance
multipliers changing 25% odds. The existing OnAfterRefCount guard is extended to these caches and five owned
pools, giving one reference iteration per successful family roll regardless of reference amount rates.
Existing primary-stat preference selects gear within each family while the module is enabled.

Standard container opening, the three restored dungeon caches, depth brackets, progression and Mode 1/2
transport remain unchanged. These cache IDs are recognized even outside the active depth catalogue so
already-owned or manually granted copies receive stat preference.

## Candidate evidence and gaps

[ZULGURUB_CACHE_CANDIDATES.csv](ZULGURUB_CACHE_CANDIDATES.csv) records 1586 family/item assignments with exact
descriptions, metadata, base relationships and item-export line numbers.

| Reference pool | Family | Candidates |
| --- | --- | --- |
| 9003201 | Normal Zul'Gurub | 122 |
| 9003202 | Heroic Zul'Gurub | 120 |
| 9003203 | Mythic Zul'Gurub | 122 |
| 9003204 | Heroic Dungeon | 611 |
| 9003205 | Plain Mythic Dungeon | 611 |

The 122 ZG base IDs reuse SQL 26's explicit ZulGurub catalogue. Variant mapping uses exact names, classes,
subclasses, slots and display models, epic quality and RequiredLevel at most 60. Specific ZG markers take
priority over generic raid markers. No variant selection is ambiguous after that preference.

Four Heroic variants have the generic @Heroic Raid@ marker: Zulian Hacker (319921), Zulian Ceremonial Staff
(320258), Shadow Panther Hide Gloves (320259), and Shadow Panther Hide Belt (320261).
The corresponding Mythic variants are 1319921, 1320258, 1320259, and 1320261 with @Mythic Raid@ markers.
Two additional generic Mythic raid variants are Teebu's Blazing Longsword (1301728) and Cloak of Flames
(1403475). These generic-marker mappings reuse the SQL 26 identity-based reconstruction rule; their
descriptions alone do not establish a specific raid source.

No Heroic variant was recovered for base 1728 Teebu's Blazing Longsword or base 3475 Cloak of Flames. They
remain in Normal/Mythic pools but are omitted from Heroic rather than replaced by another tier. The Heroic
pool intentionally has 120 items. These gaps remain documented for future evidence recovery.

Dungeon families reuse SQL 50/53 mappings. All Mythic Dungeon candidates have the exact unranked
@Mythic Dungeon@ description. No Mythic+ ranks are included. The known Idol of Brutality tier exceptions
remain documented in the dungeon mapping reports.

## Safeguards and validation

SQL 54 embeds all five pools; SQL 26/50/53 need not be applied first. It requires CREATE ROUTINE permission,
InnoDB loot tables and the three scriptless HAS_LOOT containers. Preflight checks every candidate's captured
identity and metadata, existing item/reference conditions and reference ownership/consumers across all loot
stores. Persistent writes are transactional and limited to these caches and reference pools.
Temporary-table count checks use a single scan, avoiding MySQL error 1137.

SQLite checks passed for all candidate assignments, family counts, generated mutation statements, separate
guaranteed/optional groups, independent bonus probabilities, idempotent reapplication, preserved unrelated
cache rows, Mythic+ exclusion and missing-family rejection. SQL formatting, INSERT/DELETE safety and engine
checks passed; the linter flags the intentional module base-directory migration. C++ checks passed except
for pre-existing blank-line warnings in ManastormRewards.cpp.

Rebuild the module, apply SQL 54 to acore_world and restart worldserver. MySQL procedure execution, C++
compilation and in-game cache opening remain untested. No live database writes were performed.

Source item dump SHA-256: 3e36f8748b12b89605ec278953ad4c9c3db505757d4bc9a7294ea19c052e243e.
