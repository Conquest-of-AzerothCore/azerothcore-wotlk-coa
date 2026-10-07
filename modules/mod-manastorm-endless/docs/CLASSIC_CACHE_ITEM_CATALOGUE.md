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
