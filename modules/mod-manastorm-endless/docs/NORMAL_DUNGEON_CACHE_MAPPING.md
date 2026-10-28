# Normal Dungeon Manastorm cache - candidate mapping

## Target and status

Item 1278050, Manastorm Cache: Normal Dungeons. Exact advertised description:

    Obtained from Manastorm Levels: 1 to 24
    Contains:
    + Normal Dungeon Gear

The user approved using the mapped 611 base items to restore cache 1278050. SQL 49 now implements that targeted CoA reconstruction. Original exact cache membership/odds remain unrecovered; no live database write has been performed.

## Findings

- Reused the 611 explicitly enumerated ClassicDungeonCatalog base IDs already preserved in SQL 26.
- All 611 IDs exist in the refreshed item dump and are equippable weapons/armor.
- Every base item has ItemLevel=57; RequiredLevel ranges from 46 through 60.
- 600 are rare (Quality=3); 11 are epic (Quality=4).
- No @Normal Dungeon@ tagged alternative was found among matching names, or globally in the scanned item rows.
- The base items are therefore the candidate Normal-tier IDs. This is a strong reconstruction from the historical catalogue, item-level pattern and separate ranked variants, not an original per-cache loot capture.
- 586 IDs also appear in AtlasLoot Classic Instances.lua records whose reference is represented by the ClassicInstances.lua menu. The other 25 lack that corroboration in this inspected AtlasLoot snapshot.
- Some names have multiple unranked rows. Exact catalogue base IDs resolve identity without picking arbitrary same-name duplicates. In particular, use catalogue ID 22301 for Ironweave Robe; do not add same-name 2230111 merely because it exists.
- A level-60 realm's gear need not require exactly character level 60. RequiredLevel and ItemLevel are different fields. These candidates have endgame Normal item level 57, while their required levels remain 46-60.

## Evidence and limitations

[Existing SQL 26](../data/sql/db-world/base/26_manastorm_cache_molten_core_full_reconstruction.sql) preserves the explicit base IDs and documents their origin in a historical Mythic+ reward-name catalogue, including UBRS. That original catalogue establishes dungeon reward candidates; extending its base IDs to this Normal cache remains reconstruction.

[Ascension AtlasLoot Classic item data](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/Databases/Items/Classic/Instances.lua), blob dd69a91b91e79c7056c78669ee1e2b8e7471d407, says it was auto-generated from Ascension DB. Its [menu](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/UI/Menus/ClassicInstances.lua), blob 0be89e11d314385cc5c3a6fc0a56fdcd4f3bf5ff, supplies source-reference labels. Dungeon membership and Mythic reward membership do not individually prove Normal cache inclusion.

The [official Chapter 2 reward table](https://ascension.gg/de/news/chapter-2-pre-patch-updates/461) confirms the Normal cache starts at depth 1 and Heroic at depth 25. It does not provide a complete per-item loot list or roll odds.

The current export's 207 level-80 items in 1278050 are unsuitable for the Classic policy. Do not append the candidate list to that wrong pool. Any restoration must replace only the targeted cache rows and preserve other containers.

## Concrete mapping examples

| Base Item ID | Name | Item level | Required level |
|---|---|---:|---:|
| 11920 | Wraith Scythe | 57 | 51 |
| 11921 | Impervious Giant | 57 | 52 |
| 12557 | Ebonsteel Spaulders | 57 | 54 |
| 22301 | Ironweave Robe | 57 | 58 |
| 11623 | Spritecaster Cape | 57 | 47 |

## Items with historical-catalogue evidence only in this cross-check

These 25 entries are present in the dump but were not matched to a menu-linked AtlasLoot record. They are candidate entries pending that additional source corroboration, not missing database items.

| Item ID | Name |
|---|---|
| 12553 | Swiftwalker Boots |
| 12554 | Hands of the Exalted Herald |
| 12556 | High Priestess Boots |
| 12557 | Ebonsteel Spaulders |
| 13524 | Skull of Burning Shadows |
| 13950 | Detention Strap |
| 14536 | Bonebrace Hauberk |
| 14543 | Darkshade Gloves |
| 14576 | Ebon Hilt of Marduk |
| 18425 | Kreeg's Mug |
| 18476 | Mud Stained Boots |
| 18478 | Hyena Hide Jerkin |
| 18480 | Scarab Plate Helm |
| 18481 | Skullcracking Mace |
| 18482 | Ogre Toothpick Shooter |
| 18538 | Treant's Bane |
| 18692 | Death Knight Sabatons |
| 18701 | Innervating Band |
| 18702 | Belt of the Ordained |
| 18757 | Diabolic Mantle |
| 22301 | Ironweave Robe |
| 22327 | Amulet of the Redeemed |
| 22328 | Legplates of Vigilance |
| 22329 | Scepter of Interminable Focus |
| 22334 | Band of Mending |

## Complete machine-readable inventory

[NORMAL_DUNGEON_CACHE_CANDIDATES.csv](NORMAL_DUNGEON_CACHE_CANDIDATES.csv) contains every candidate ID, exact name, item metadata, evidence classification and item-dump line. Its 611 rows are an inventory of candidates, not claimed recovered original cache membership.

## Restoration migration

[49_manastorm_classic_normal_dungeon_cache.sql](../data/sql/db-world/base/49_manastorm_classic_normal_dungeon_cache.sql) replaces only item_loot_template rows for cache 1278050 with the 611 explicit base IDs above. The 25 historical-catalogue-only entries are included in the approved reconstruction. The prior 207 level-80 candidates are removed from this cache.

It retains one equal-choice group (Chance=0, GroupId=1, MinCount=MaxCount=1) and the existing primary-stat preference hook. This is a CoA policy choice, not recovered original probabilities. Heroic cache 1278051, other caches, item templates, reference pools, conditions, brackets and player progression are not written.

Preflight requires the existing item_manastorm_cache binding, HAS_LOOT, an InnoDB item loot table, all 611 exact candidate identities/metadata, item level 57, required levels at most 60, and no existing loot conditions on this cache. Failure raises an error and rolls back before replacing loot. The migration uses a temporary procedure and requires CREATE ROUTINE permission, matching the SQL 26 pattern.

Apply SQL 49 to acore_world and restart worldserver to load the new item loot. No C++ rebuild or character SQL is needed for this data-only change. Expected post-write query: 611 distinct candidates, item level 57, required levels 46-60. Migration is prepared, not applied to the live database.

Validation: generated candidate rows and mutation/predicate SQL exercised in a SQLite data model; exact IDs, targeted replacement, unchanged unrelated cache rows and repeat application passed. Missing candidates, changed metadata/levels and existing conditions are rejected by the predicate model. MySQL stored-procedure execution and in-game opening were not tested. Formatting/safety checks passed except the existing backtick checker falsely flags COUNT, BINARY and SIGNAL's MESSAGE_TEXT keywords; SQL identifiers are quoted.

Source item dump SHA-256: 3e36f8748b12b89605ec278953ad4c9c3db505757d4bc9a7294ea19c052e243e.
