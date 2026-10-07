# Classic Manastorm cache item catalogue

Verified 2026-10-07 from the user-supplied `item_template.sql` dump at `C:/Users/Andreas/Downloads/Items/item_template.sql`. This is dump evidence, not a live database inspection. Names below omit the common `Manastorm Cache: ` prefix.

## Classic endgame items

All 35 entries from 1278050 through 1278084 exist in the dump. Item existence does not prove populated loot, award eligibility, or working opening behavior.

| Item ID | Cache name |
|---|---|
| 1278050 | Normal Dungeons |
| 1278051 | Heroic Dungeons |
| 1278052 | Zul'Gurub |
| 1278053 | Heroic Zul'Gurub |
| 1278054 | Mythic Dungeons |
| 1278055 | Mythic Zul'Gurub |
| 1278056 | Molten Core |
| 1278057 | Ascended Zul'Gurub |
| 1278058 | Heroic Molten Core |
| 1278059 | Mythic 1-10 |
| 1278060 | Mythic Molten Core |
| 1278061 | Onyxia & Molten Core |
| 1278062 | Ascended Molten Core |
| 1278063 | Heroic Onyxia & Molten Core |
| 1278064 | Mythic 11-20 |
| 1278065 | Mythic Onyxia & Molten Core |
| 1278066 | Blackwing Lair |
| 1278067 | Ascended Onyxia & Molten Core |
| 1278068 | Heroic Blackwing Lair |
| 1278069 | Mythic Blackwing Lair |
| 1278070 | Ruins of Ahn'Qiraj |
| 1278071 | Ascended Blackwing Lair |
| 1278072 | Heroic Ruins of Ahn'Qiraj |
| 1278073 | Mythic 21-30 |
| 1278074 | Mythic Ruins of Ahn'Qiraj |
| 1278075 | Temple of Ahn'Qiraj |
| 1278076 | Ascended Ruins of Ahn'Qiraj |
| 1278077 | Heroic Temple of Ahn'Qiraj |
| 1278078 | Mythic Temple of Ahn'Qiraj |
| 1278079 | Naxxramas |
| 1278080 | Ascended Temple of Ahn'Qiraj |
| 1278081 | Heroic Naxxramas |
| 1278082 | Mythic 31-40 |
| 1278083 | Mythic Naxxramas |
| 1278084 | Ascended Naxxramas |

## Leveling and generic items

| Item ID | Exact item name |
|---|---|
| 97877 | Manastorm Cache (11-24) |
| 97878 | Manastorm Cache (25-30) |
| 97879 | Manastorm Cache (31-35) |
| 97880 | Manastorm Cache (36-45) |
| 97881 | Manastorm Cache (46-50) |
| 97882 | Manastorm Cache (51-59) |
| 97883 | Manastorm Cache (60) |
| 97884 | Manastorm Cache |

The generic 97884 item is not independently established as Vanilla-only by its name. Bonus caches 1478051 and 1478052 also exist but are not classified as Vanilla-only from their names.

## Award catalogue versus item catalogue

SQL 47 (`data/sql/db-world/base/47_manastorm_classic_cache_unlocks.sql`) selects 20 Classic endgame items: 1278050, 1278051, 1278052, 1278053, 1278055, 1278056, 1278058, 1278060, 1278066, 1278068, 1278069, 1278070, 1278072, 1278074, 1278075, 1278077, 1278078, 1278079, 1278081, 1278083. The other 15 existing items are not selected by that migration. SQL 48 updates labels only.

User policy: Vanilla/Classic caches and segments; TBC excluded for now. The supplied bracket snapshot had TBC brackets 100–126 disabled and Classic brackets 1000–1019 enabled. This historical snapshot does not verify current live configuration or Vanilla-only cache contents.

## Reuse

Read this compact catalogue before rescanning the full item dump. Recheck the source when IDs/names change or when investigating descriptions, spell slots, loot contents, or live availability. Keep confirmed evidence separate from reconstructed behavior.

## Restoration migration index

All 35 endgame cache IDs now have reviewed restoration definitions. This describes repository work,
not live installation, original Ascension odds or completed in-game validation. The installed-loot audit
below remains the historical supplied snapshot. Reuse the linked family reports and candidate CSVs.

| Family | Cache IDs | Migration |
| --- | --- | --- |
| Normal Dungeon | 1278050 | SQL 49 |
| Heroic Dungeon | 1278051 | SQL 50 |
| Plain Mythic Dungeon | 1278054 | SQL 53 |
| ZG Normal/Heroic/Mythic | 1278052, 1278053, 1278055 | SQL 54 |
| MC Normal/Heroic/Mythic | 1278056, 1278058, 1278060 | SQL 26, then SQL 55 |
| Later MC/Onyxia | 1278061, 1278062, 1278063, 1278065, 1278067 | SQL 26, then SQL 62 |
| BWL Normal/Heroic/Mythic | 1278066, 1278068, 1278069 | SQL 57 |
| AQ20 Normal/Heroic/Mythic | 1278070, 1278072, 1278074 | SQL 58 |
| AQ40 Normal/Heroic/Mythic | 1278075, 1278077, 1278078 | SQL 59 |
| Naxx Normal/Heroic/Mythic | 1278079, 1278081, 1278083 | SQL 60 |
| Dungeon rank bands 1-40 | 1278059, 1278064, 1278073, 1278082 | SQL 61 |
| Remaining Ascended raids | 1278057, 1278071, 1278076, 1278080, 1278084 | SQL 63 |

SQL 57-61 and SQL 63 are self-contained. SQL 55/62 validate and reuse installed SQL 26 pools.
If SQL 26 is already installed, apply the follow-ups without rebuilding its pools. If SQL 26 is absent,
apply SQL 26, then SQL 55 and SQL 62. Rerunning SQL 26 resets its eight roots; reapply both follow-ups.
Source runtime changes require a module rebuild and restart. Restoring inactive caches does not add them
to SQL 47's active award catalogue.

The separate level-60 physical cache 97883 is corrected by SQL 64: 612 existing candidates certified
against the full Classic 1.12 database and Ascension's Classic catalogue are retained. All 1725 above-60
items and 255 further uncertified later/foreign items are excluded. SQL-only application requires a
worldserver restart, without a rebuild. See [LEVEL60_CACHE_REVIEW.md](LEVEL60_CACHE_REVIEW.md) and its
complete candidate decision CSV for provenance and acquisition limitations.
97884 is intentionally the generic Potential Rewards UI identity, not a physical-cache fallback;
SQL 15 and LoadPotentialRewards establish its role. Its empty loot is not a restoration gap.

See [ONYXIA_MOLTEN_CORE_CACHE_REVIEW.md](ONYXIA_MOLTEN_CORE_CACHE_REVIEW.md),
[RANKED_DUNGEON_CACHE_MAPPING.md](RANKED_DUNGEON_CACHE_MAPPING.md) and
[ASCENDED_RAID_CACHE_MAPPING.md](ASCENDED_RAID_CACHE_MAPPING.md) for the later reconstruction policies.

## Exact item descriptions

Extracted against the declared SQL column order (all 43 selected rows matched the schema column count). SQL string escapes are decoded; line breaks and placeholders below are retained. Empty descriptions are explicitly marked. Depth descriptions record the source snapshot; they do not override SQL 47. `946 to -1` is preserved literally.

### 97877 — Manastorm Cache (11-24)

Description field is empty.

### 97878 — Manastorm Cache (25-30)

Description field is empty.

### 97879 — Manastorm Cache (31-35)

Description field is empty.

### 97880 — Manastorm Cache (36-45)

Description field is empty.

### 97881 — Manastorm Cache (46-50)

Description field is empty.

### 97882 — Manastorm Cache (51-59)

Description field is empty.

### 97883 — Manastorm Cache (60)

Description field is empty.

### 97884 — Manastorm Cache

```text
@1-59@
```

### 1278050 — Manastorm Cache: Normal Dungeons

```text
Obtained from Manastorm Levels: 1 to 24
Contains:
+ Normal Dungeon Gear
```

### 1278051 — Manastorm Cache: Heroic Dungeons

```text
Obtained from Manastorm Levels: 25 to 105
Contains: 
+ Normal Dungeon Gear
+ Heroic Dungeon Gear
```

### 1278052 — Manastorm Cache: Zul'Gurub

```text
Obtained from Manastorm Levels: 106 to 145
Contains: 
+ Heroic Dungeon Gear
+ Normal Zul'Gurub Gear
```

### 1278053 — Manastorm Cache: Heroic Zul'Gurub

```text
Obtained from Manastorm Levels: 146 to 185
Contains: 
+ Normal Zul'Gurub Gear
Chance to contain:
+ Heroic Zul'Gurub Gear
```

### 1278054 — Manastorm Cache: Mythic Dungeons

```text
Manastorm 201 to 250
Contains gear up to Mythic Dungeons!
```

### 1278055 — Manastorm Cache: Mythic Zul'Gurub

```text
Obtained from Manastorm Levels: 186 to 220
Contains:
+ Heroic Zul'Gurub Gear
Chance to contain:
+ Mythic Zul'Gurub Gear
+ Mythic Dungeon Gear
```

### 1278056 — Manastorm Cache: Molten Core

```text
Obtained from Manastorm Levels: 221 to 280
Contains:
+ Mythic Zul'Gurub Gear
+ Normal Molten Core Gear
Chance to contain:
+ Mythic Dungeon Gear
```

### 1278057 — Manastorm Cache: Ascended Zul'Gurub

```text
@401 - 450@
```

### 1278058 — Manastorm Cache: Heroic Molten Core

```text
Obtained from Manastorm Levels: 281 to 340
Contains:
+ Normal Molten Core Gear
Chance to contain:
+ Heroic Molten Core Gear
+ Mythic Dungeon Gear
```

### 1278059 — Manastorm Cache: Mythic 1-10

```text
Manastorm 501 to 550
Contains gear up to Mythic 1-10!
```

### 1278060 — Manastorm Cache: Mythic Molten Core

```text
Obtained from Manastorm Levels: 341 to 425
Contains:
+ Heroic Molten Core Gear (1-2)
Chance to contain:
+ Mythic Molten Core Gear
+ Normal Onyxia Gear
+ Mythic 1-10 Dungeon Gear
```

### 1278061 — Manastorm Cache: Onyxia & Molten Core

```text
Manastorm 601 to 700
Contains gear up to Normal Onyxia's Lair!
```

### 1278062 — Manastorm Cache: Ascended Molten Core

```text
@651 - 700@
```

### 1278063 — Manastorm Cache: Heroic Onyxia & Molten Core

```text
Manastorm 701 to 750
Contains gear up to Heroic Onyxia's Lair!
```

### 1278064 — Manastorm Cache: Mythic 11-20

```text
Manastorm 751 to 800
Contains gear up to Mythic 11-20!
```

### 1278065 — Manastorm Cache: Mythic Onyxia & Molten Core

```text
Manastorm 801 to 900
Contains gear up to Mythic Onyxia's Lair!
```

### 1278066 — Manastorm Cache: Blackwing Lair

```text
Obtained from Manastorm Levels: 426 to 450
Contains:
+ Mythic Molten Core Gear
+ Normal Blackwing Lair Gear
Chance to contain:
+ Mythic Onyxia Gear
+ Mythic 11-20 Dungeon Gear
```

### 1278067 — Manastorm Cache: Ascended Onyxia & Molten Core

```text
@951 - 1000@
```

### 1278068 — Manastorm Cache: Heroic Blackwing Lair

```text
Obtained from Manastorm Levels: 451 to 475
Contains:
+ Normal Blackwing Lair Gear
Chance to contain: 
+ Ascended Onyxia Gear
+ Heroic Blackwing Lair Gear
+ Mythic 11-20 Dungeon Gear
```

### 1278069 — Manastorm Cache: Mythic Blackwing Lair

```text
Obtained from Manastorm Levels: 476 to 510
Contains: 
+ Heroic Blackwing Lair Gear (1-2)
Chance to contain:
+ Mythic Blackwing Lair Gear
+ Ascended Onyxia Gear
+ Mythic 11-20 Dungeon Gear
```

### 1278070 — Manastorm Cache: Ruins of Ahn'Qiraj

```text
Obtained from Manastorm Levels: 511 to 535
Contains: 
+ Mythic Blackwing Lair Gear
+ Normal Ruins of AQ Gear
Chance to contain: 
+ Mythic 11-20 Dungeon Gear
```

### 1278071 — Manastorm Cache: Ascended Blackwing Lair

```text
@1201 - 1250@
```

### 1278072 — Manastorm Cache: Heroic Ruins of Ahn'Qiraj

```text
Obtained from Manastorm Levels: 536 to 560
Contains:
+ Normal Ruins of AQ Gear (1-2)
Chance to contain: 
+ Heroic Ruins of AQ Gear
+ Mythic 11-20 Dungeon Gear
```

### 1278073 — Manastorm Cache: Mythic 21-30

```text
Manastorm 1301 to 1350
Contains gear up to Mythic 21-30!
```

### 1278074 — Manastorm Cache: Mythic Ruins of Ahn'Qiraj

```text
Obtained from Manastorm Levels: 561 to 610
Contains:
+ Heroic Ruins of AQ Gear
Chance to contain:
+ Mythic Ruins of AQ Gear
+ Mythic 21-30 Dungeon Gear
```

### 1278075 — Manastorm Cache: Temple of Ahn'Qiraj

```text
Obtained from Manastorm Levels: 611 to 655
Contains:
+ Normal Temple of AQ Gear
+ Mythic Ruins of AQ Gear
Chance to contain: 
+ Mythic 21-30 Dungeon Gear
```

### 1278076 — Manastorm Cache: Ascended Ruins of Ahn'Qiraj

```text
@1501 - 1550@
```

### 1278077 — Manastorm Cache: Heroic Temple of Ahn'Qiraj

```text
Obtained from Manastorm Levels: 656 to 700
Contains:
+ Normal Temple of AQ Gear (1-2)
Chance to contain:
+ Heroic Temple of AQ Gear
+ Mythic 21-30 Dungeon Gear
```

### 1278078 — Manastorm Cache: Mythic Temple of Ahn'Qiraj

```text
Obtained from Manastorm Levels: 701 to 740
Contains:
+ Heroic Temple of AQ Gear
Chance to contain:
+ Mythic Temple of AQ Gear
+ Mythic 21-30 Dungeon Gear
```

### 1278079 — Manastorm Cache: Naxxramas

```text
Obtained from Manastorm Levels: 741 to 840
Contains: 
+ Mythic Temple of AQ Gear
+ Normal Naxxramas Gear
Chance to contain:
+ Mythic 21-30 Dungeon Gear
```

### 1278080 — Manastorm Cache: Ascended Temple of Ahn'Qiraj

```text
@1751 - 1800@
```

### 1278081 — Manastorm Cache: Heroic Naxxramas

```text
Obtained from Manastorm Levels: 841 to 945
Contains: 
+ Normal Naxxramas Gear
Chance to contain: 
+ Heroic Naxxramas Gear
+ Mythic 31-40 Dungeon Gear
```

### 1278082 — Manastorm Cache: Mythic 31-40

```text
Manastorm 1851 to 1900
Contains gear up to Mythic levels 31-40!
```

### 1278083 — Manastorm Cache: Mythic Naxxramas

```text
Obtained from Manastorm Levels: 946 to -1
Contains:
+ Heroic Naxxramas Gear
Chance to contain: 
+ Mythic Naxxramas Gear
+ Mythic 31-40 Dungeon Gear
```

### 1278084 — Manastorm Cache: Ascended Naxxramas

```text
@1951 - 2000+@
```

## Installed-loot audit - 2026-10-07

The requested exports have now been inspected. [CLASSIC_CACHE_LOOT_AUDIT.md](CLASSIC_CACHE_LOOT_AUDIT.md) records every cache's installed row count, candidate count, script binding evidence, wrong-level gear findings, restoration priorities, and export fingerprints.

33 of 35 Classic endgame caches have no loot rows. The other two (1278050/1278051) contain exclusively level-80 gear. Level-60 cache 97883 has 1725 above-60 candidates among 2592 total. SQL 26's expected eight-cache result is absent from this snapshot. No restoration has been executed.

The exact descriptions above remain the advertised source intent; installed loot is evaluated separately in the audit. This checkpoint supersedes the earlier request for missing loot exports.
