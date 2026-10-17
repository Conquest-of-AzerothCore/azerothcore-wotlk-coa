# Classic Manastorm installed-loot audit - 2026-10-07

## Scope and evidence

Read-only inspection of user-supplied Navicat exports: LootTemplates.sql (2026-10-07 16:16:07), conditions.sql (2026-10-07 16:16:31), and item_template.sql. Export timestamps are copied from file headers. These establish the exported snapshot, not subsequent live changes. No SQL was executed.

Schema-aware parsing decoded SQL strings and checked every parsed tuple against its table column count. Traced item-loot reference edges recursively with cycle and missing-reference detection; checked leaf item existence, loot modes/counts, quest flags, and item/reference conditions. All 43 examined caches use direct rows or have no rows; none references a reference pool. Independent text counts confirm 207/1480 rows for the two dungeon caches and zero rows for 1278052-1278084.

## Findings

- Classic endgame 1278050-1278084: 33 empty profiles; two populated profiles contain exclusively RequiredLevel=80 gear.
- SQL 47 active catalogue: 18 empty caches and two populated but unsuitable for the Vanilla-only policy.
- All 28 named raid caches have zero installed item-loot rows in this export.
- Leveling 97877-97882 have populated equippable-gear pools with no RequiredLevel above 60. Their expansion provenance has not been individually certified.
- Level-60 cache 97883 has 2592 candidates; 1725 require levels above 60 (levels 61-79), including explicit Northrend dungeon/world-drop markers.
- Generic 97884 is empty.
- No matching item-loot conditions for the audited caches; no missing leaf item templates or malformed row chance/group/count/mode values found in populated pools. No reference chains are attached to these caches.

Candidate counts are unique configured item IDs, not items awarded per opening. Every populated pool uses Chance=0, GroupId=1, LootMode=1, MinCount=MaxCount=1. This is an equal-choice group, not a zero-chance empty pool. The module personalizes equippable leaf selection with positive stat weights; its candidate predicate checks weapon/armor and InventoryType, without a RequiredLevel or expansion exclusion. Runtime behavior was not tested.

## Per-cache inventory

| Item ID | Cache | SQL 47 active | Loot rows / candidates | RequiredLevel >60 | Verdict |
|---|---|---|---:|---:|---|
| 1278050 | Manastorm Cache: Normal Dungeons | Yes | 207 | 207 | Populated; level-80 gear only |
| 1278051 | Manastorm Cache: Heroic Dungeons | Yes | 1480 | 1480 | Populated; level-80 gear only |
| 1278052 | Manastorm Cache: Zul'Gurub | Yes | 0 | 0 | Empty profile |
| 1278053 | Manastorm Cache: Heroic Zul'Gurub | Yes | 0 | 0 | Empty profile |
| 1278054 | Manastorm Cache: Mythic Dungeons | No (endgame) | 0 | 0 | Empty profile |
| 1278055 | Manastorm Cache: Mythic Zul'Gurub | Yes | 0 | 0 | Empty profile |
| 1278056 | Manastorm Cache: Molten Core | Yes | 0 | 0 | Empty profile |
| 1278057 | Manastorm Cache: Ascended Zul'Gurub | No (endgame) | 0 | 0 | Empty profile |
| 1278058 | Manastorm Cache: Heroic Molten Core | Yes | 0 | 0 | Empty profile |
| 1278059 | Manastorm Cache: Mythic 1-10 | No (endgame) | 0 | 0 | Empty profile |
| 1278060 | Manastorm Cache: Mythic Molten Core | Yes | 0 | 0 | Empty profile |
| 1278061 | Manastorm Cache: Onyxia & Molten Core | No (endgame) | 0 | 0 | Empty profile |
| 1278062 | Manastorm Cache: Ascended Molten Core | No (endgame) | 0 | 0 | Empty profile |
| 1278063 | Manastorm Cache: Heroic Onyxia & Molten Core | No (endgame) | 0 | 0 | Empty profile |
| 1278064 | Manastorm Cache: Mythic 11-20 | No (endgame) | 0 | 0 | Empty profile |
| 1278065 | Manastorm Cache: Mythic Onyxia & Molten Core | No (endgame) | 0 | 0 | Empty profile |
| 1278066 | Manastorm Cache: Blackwing Lair | Yes | 0 | 0 | Empty profile |
| 1278067 | Manastorm Cache: Ascended Onyxia & Molten Core | No (endgame) | 0 | 0 | Empty profile |
| 1278068 | Manastorm Cache: Heroic Blackwing Lair | Yes | 0 | 0 | Empty profile |
| 1278069 | Manastorm Cache: Mythic Blackwing Lair | Yes | 0 | 0 | Empty profile |
| 1278070 | Manastorm Cache: Ruins of Ahn'Qiraj | Yes | 0 | 0 | Empty profile |
| 1278071 | Manastorm Cache: Ascended Blackwing Lair | No (endgame) | 0 | 0 | Empty profile |
| 1278072 | Manastorm Cache: Heroic Ruins of Ahn'Qiraj | Yes | 0 | 0 | Empty profile |
| 1278073 | Manastorm Cache: Mythic 21-30 | No (endgame) | 0 | 0 | Empty profile |
| 1278074 | Manastorm Cache: Mythic Ruins of Ahn'Qiraj | Yes | 0 | 0 | Empty profile |
| 1278075 | Manastorm Cache: Temple of Ahn'Qiraj | Yes | 0 | 0 | Empty profile |
| 1278076 | Manastorm Cache: Ascended Ruins of Ahn'Qiraj | No (endgame) | 0 | 0 | Empty profile |
| 1278077 | Manastorm Cache: Heroic Temple of Ahn'Qiraj | Yes | 0 | 0 | Empty profile |
| 1278078 | Manastorm Cache: Mythic Temple of Ahn'Qiraj | Yes | 0 | 0 | Empty profile |
| 1278079 | Manastorm Cache: Naxxramas | Yes | 0 | 0 | Empty profile |
| 1278080 | Manastorm Cache: Ascended Temple of Ahn'Qiraj | No (endgame) | 0 | 0 | Empty profile |
| 1278081 | Manastorm Cache: Heroic Naxxramas | Yes | 0 | 0 | Empty profile |
| 1278082 | Manastorm Cache: Mythic 31-40 | No (endgame) | 0 | 0 | Empty profile |
| 1278083 | Manastorm Cache: Mythic Naxxramas | Yes | 0 | 0 | Empty profile |
| 1278084 | Manastorm Cache: Ascended Naxxramas | No (endgame) | 0 | 0 | Empty profile |
| 97877 | Manastorm Cache (11-24) | Not applicable | 765 | 0 | Populated; no above-60 candidates |
| 97878 | Manastorm Cache (25-30) | Not applicable | 376 | 0 | Populated; no above-60 candidates |
| 97879 | Manastorm Cache (31-35) | Not applicable | 309 | 0 | Populated; no above-60 candidates |
| 97880 | Manastorm Cache (36-45) | Not applicable | 724 | 0 | Populated; no above-60 candidates |
| 97881 | Manastorm Cache (46-50) | Not applicable | 378 | 0 | Populated; no above-60 candidates |
| 97882 | Manastorm Cache (51-59) | Not applicable | 944 | 0 | Populated; no above-60 candidates |
| 97883 | Manastorm Cache (60) | Not applicable | 2592 | 1725 | Populated; above-60 contamination |
| 97884 | Manastorm Cache | Not applicable | 0 | 0 | Empty profile |

## Concrete wrong-pool evidence

Both dungeon caches include item 37181 Dagger of Betrayal, 37182 Helmet of the Constructor, and 37183 Bindings of the Tunneler; each requires level 80 and carries the description @Heroic Dungeon: Utgarde Keep@. All 207 candidates in 1278050 and all 1480 in 1278051 require level 80. The Heroic cache additionally includes explicit Naxxramas 10/25-player, Eye of Eternity, and Obsidian Sanctum markers.

## Existing reconstruction and restoration priority

SQL 26 already supplies reconstruction for 1278056, 1278058, 1278060, 1278061, 1278062, 1278063, 1278065, 1278067. Expected direct row counts: 3, 3, 5, 1, 1, 1, 1, 1. All eight have zero rows in this export, so its expected installed result is absent. This does not establish whether the migration was never applied, failed, or was later overwritten. Reuse the migration and its dataset/collision checks before considering a new reconstruction; do not blindly run it. Its optional odds and five later profiles are reconstructed policy.

Priority for the active Classic catalogue:

1. Correct 1278050/1278051 and 97883 for the Vanilla-only policy.
2. Validate/reuse SQL 26 for the active MC trio 1278056/1278058/1278060.
3. Restore remaining active empty profiles: 1278052, 1278053, 1278055, 1278066, 1278068, 1278069, 1278070, 1278072, 1278074, 1278075, 1278077, 1278078, 1278079, 1278081, 1278083.
4. Restore unused variants only when their availability policy calls for them.

Current item bindings: 97877-97883 and 1278050-1278051 use item_manastorm_cache, confirming the SQL 20 ownership result in this snapshot. Other audited entries have no per-item ScriptName. Their lack of loot rows is not repaired by the description or HAS_LOOT flag.

Exact advertised depth ranges and gear families are preserved in [CLASSIC_CACHE_ITEM_CATALOGUE.md](CLASSIC_CACHE_ITEM_CATALOGUE.md). Use those as intent evidence, not proof of installed contents or recovered probabilities. No source/database changes or restoration were performed.

## Source fingerprints

| Export | SHA-256 |
|---|---|
| LootTemplates.sql | a34a3662566efbff5298eabf7ef5cc05362e29e0f267e57ecd6b675359b09ace |
| conditions.sql | cbddcc699c3a25737bb7c7c47f51783f14d3c7c4ef859b74648aae1bc49fdedd |
| item_template.sql | 3e36f8748b12b89605ec278953ad4c9c3db505757d4bc9a7294ea19c052e243e |
