# Level-60 physical cache review and generic UI identity

SQL 64 corrects 97883 Manastorm Cache (60) using the existing exported candidate pool.
The user selected a full Classic world/quest catalogue review instead of the narrow 347-item
Ascension encounter-catalogue intersection. No new candidate item is invented or added.

## Findings and selected pool

| Exported pool partition | Count | Action |
| --- | --- | --- |
| RequiredLevel above 60 | 1725 | Exclude |
| At most 60; verified Classic/Ascension identity | 612 | Retain |
| At most 60; outside verified Classic/Ascension catalogue | 255 | Exclude |
| Total original candidates | 2592 | 612 restored rows |

The retained pool has 250 green and 362 blue items, RequiredLevel 55-60, ItemLevel 57-65.
Removing only above-60 gear would leave 867 items and retain known Outland/later gear. Examples of the
excluded low-level entries are 24044 Hellreaver, 24045 Band of Renewal, 25032 Hellfire Cloak and
many Outlander/Fireheart/Laughing Skull equipment rows. A level check or arbitrary item-ID cutoff is
not used as expansion provenance. Absence from the verified catalogues is not a claim that every
excluded item is conclusively invalid in all Ascension versions; exclusions follow the Vanilla policy.

The broad Classic check retains 265 additional items compared with the narrow 347-item approach,
including ordinary Classic green world equipment. Classic quest rewards and vendors were checked too;
no selected existing candidate appeared in the full database's quest-reward or vendor rows.
This preserves the existing 55-60-required-level equipment scope rather than adding level-zero quest
rewards or assembling a new all-source item pool. The candidate list is a reviewed subset of the
user's original cache pool, not the recovered complete original Ascension cache loot table.

## Source-grounded certification

The full official CMaNGOS Classic 1.12 content database provides 17718 item templates across Classic
world, quest, dungeon, raid, crafted and vendor content. It is used only as identity/provenance evidence;
no CMaNGOS schema, stats, loot chances or server behavior is imported into AzerothCore.
601 retained candidates match Classic entry ID, exact name, weapon/armor class, subclass and equipment
slot. Their current Ascension metadata and stats remain authoritative and unchanged.

Source:

- [Classic database project](https://github.com/cmangos/classic-db)
- [Full Classic database](https://github.com/cmangos/classic-db/blob/master/Full_DB/ClassicDB_1_12_1_z2815.sql.gz)

Verified source file: ClassicDB_1_12_1_z2815.sql.gz, fetched 2026-10-07.
Git blob: 0a77f5230a3d5d6db968678203dfe3b30c34b8a9.
SHA-256: 4f92db520868ab4e566726f68b5b2e380ae781209beaf22237b4f7f04600d0c0.

Eleven further candidates are established by Ascension's Classic encounter catalogue. Ten have Classic
base IDs but Ascension changes weapon slots/types; the remaining Flightblade Throwing Axe is explicitly
listed in that Classic catalogue. Exact current name/class/subclass/slot/model metadata is captured
in the CSV and SQL preflight, rather than substituting the Classic database version.

| Retained item ID | Name | Evidence |
| --- | --- | --- |
| 6622 | Sword of Zeal | Ascension Classic catalogue |
| 12709 | Finkle's Skinner | Ascension Classic catalogue |
| 13006 | Mass of McGowan | Ascension Classic catalogue |
| 13028 | Bludstone Hammer | Ascension Classic catalogue |
| 13349 | Scepter of the Unholy | Ascension Classic catalogue |
| 13360 | Gift of the Elven Magi | Ascension Classic catalogue |
| 13952 | Iceblade Hacker | Ascension Classic catalogue |
| 13953 | Silent Fang | Ascension Classic catalogue |
| 13964 | Witchblade | Ascension Classic catalogue |
| 18462 | Jagged Bone Fist | Ascension Classic catalogue |
| 28972 | Flightblade Throwing Axe | Ascension Classic catalogue |

An additional acquisition cross-check finds 604 selected IDs in Classic creature/reference/gameobject/
item loot tables. Three further Classic IDs and the Ascension throwing-axe replacement have the reviewed
Ascension encounter-catalogue evidence. Four remaining IDs (13175, 13950, 19105 and 19110) have exact
Classic template identity evidence but no matching acquisition row was found in the tables checked.
Their presence in the user's existing pool is preserved; current world availability is not inferred from
template existence. Source existence does not establish original cache probabilities. The source
versions and all current candidate metadata are kept separate.

Ascension catalogue:

- [Items](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/Databases/Items/Classic/Instances.lua)
- [Menu](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/UI/Menus/ClassicInstances.lua)

Item-file Git blob: dd69a91b91e79c7056c78669ee1e2b8e7471d407.
Menu-file Git blob: 0be89e11d314385cc5c3a6fc0a56fdcd4f3bf5ff.
Only IDs from numeric Classic menu encounter/trash references certify current candidates.

[LEVEL60_CACHE_CANDIDATES.csv](LEVEL60_CACHE_CANDIDATES.csv) records all 2592 original candidates,
retain/exclude decisions, provenance or exclusion reasons, exact current metadata/descriptions,
export line numbers, Classic identity comparison fields and observed Classic acquisition tables.
This is the compact reusable audit; the downloaded full database is not committed to the module.

## Runtime ownership and SQL 64

97883 has Flags 67588 with HAS_LOOT and ScriptName item_manastorm_cache in the supplied export.
SQL 20 already owns this physical cache's script. SQL 15 selects it for character level 60.
Its description is empty. Neither script ownership nor award selection needs changing.
The existing equal-chance group uses stat-personalized gear selection at opening. SQL 64 preserves
Reference 0, Chance 0, GroupId 1, LootMode 1, QuestRequired 0 and MinCount/MaxCount 1 for every row.
It retains green/blue quality, current item identities and stats; it adds no epic/raid tier or bonus roll.

SQL 64 writes only item_loot_template rows for Entry 97883. Preflight checks InnoDB item loot, the
HAS_LOOT cache and expected module script ownership, all 612 captured item identities/metadata,
weapon/armor slots, quality 2/3, RequiredLevel 55-60 and absence of item-loot conditions.
Writes are transactional and idempotent. Each temporary table occurs once per statement.
No C++ changes, reference pools, item-template updates, conditions, brackets or Mode 1/2 changes are needed.

Apply SQL 64 to acore_world and restart worldserver. No rebuild is needed for this SQL-only change.
CREATE ROUTINE permission is required. No live database write was performed.

## 97884 is intentionally not a physical loot cache

97884 is the generic Potential Rewards UI identity, with exported description @1-59@.
SQL 15 explicitly excludes it as a physical-cache fallback and fails unresolved ranges rather than
awarding it. LoadPotentialRewards expects it as the first of seven native UI reward definitions.
Its empty item_loot_template is therefore intentional for this module, not a restoration gap.
It is left untouched; level-banded physical caches 97877-97883 supply the actual equipment rewards.

## Validation

SQLite checks passed for all 2592 retain/exclude decisions and the 612 generated SQL/CSV tuples,
catalogue provenance, 1980 exclusions, 604 acquisition matches and four template-only caveats,
quality/level counts and preservation as a subset of the original pool. Actual persistent writes
were applied twice, preserving 42 other cache sentinels, and retained the original pure leaf fields.
The metadata predicate rejected wrong descriptions, levels above 60 or below 55, changed displays
and epic quality. Container script ownership rejection, formatting and single temporary-table
references were checked. SQL formatting, quoting, insert/delete safety and engine checks passed;
only the intentional module base-directory location was flagged by the SQL linter.
MySQL procedure execution and in-game openings remain untested.

Source item dump SHA-256: 3e36f8748b12b89605ec278953ad4c9c3db505757d4bc9a7294ea19c052e243e.
