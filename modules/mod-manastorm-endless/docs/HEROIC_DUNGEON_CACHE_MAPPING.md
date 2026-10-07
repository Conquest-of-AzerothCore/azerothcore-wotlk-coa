# Heroic Dungeon Manastorm cache restoration

## Target and advertised intent

Item 1278051, Manastorm Cache: Heroic Dungeons. The exported description is:

    Obtained from Manastorm Levels: 25 to 105
    Contains:
    + Normal Dungeon Gear
    + Heroic Dungeon Gear

The exported pool contains 1480 candidates requiring level 80. [SQL 50](../data/sql/db-world/base/50_manastorm_classic_heroic_dungeon_cache.sql) replaces this cache's loot rows and creates two dedicated tier pools with the mapped Classic Normal and Heroic tiers.

## Mapping

The same 611 base IDs used in SQL 49 provide the Normal tier: item level 57, RequiredLevel 46-60, 600 rare and 11 epic items. Their original membership evidence and caveats remain documented in [NORMAL_DUNGEON_CACHE_MAPPING.md](NORMAL_DUNGEON_CACHE_MAPPING.md).

Each has exactly one selected Heroic counterpart with matching exact name, class, subclass, equipment slot and display model. All 611 Heroic items have item level 61, RequiredLevel 60 and epic quality (4). 610 have an explicit @Heroic Dungeon@ description prefix.

One explicit exception: base 23198 Idol of Brutality maps to Heroic 323198, described @Heroic@. Its name, class 4/subclass 8, slot 28, display 28174, required level 60, quality 4 and item level 61 all match the Heroic tier. Its separately named Mythic/raid/ranked variants were not substituted. This legacy marker mapping is a documented reconstruction rather than a guessed ID.

The combined pool has 1222 unique existing item IDs. [HEROIC_DUNGEON_CACHE_CANDIDATES.csv](HEROIC_DUNGEON_CACHE_CANDIDATES.csv) records each ID, tier, base relationship, exact description, metadata and dump line.

## Selection policy

The source description establishes both gear families, but does not establish original quantities or probabilities. User-approved CoA policy is one guaranteed item: 75% Heroic and 25% Normal. These are reconstruction odds, not recovered Ascension odds.

Two explicit-chance reference rows share GroupId=1: Heroic reference 9003002 has Chance=75, Normal reference 9003001 has Chance=25. Each reference contains 611 pure gear candidates in an equal-choice group. The core selects the tier before invoking existing primary-stat personalization on that tier's leaf pool; stat weights do not change the tier split.

The scoped OnAfterRefCount guard in ManastormCacheLoot.cpp forces one reference iteration for cache 1278051 and these two references while the module is enabled. This prevents global Rate.Drop.Item.ReferencedAmount from changing the reward count. Other caches and reference pools retain their existing behavior.

## Migration safeguards and scope

Preflight requires item_manastorm_cache ownership, HAS_LOOT, InnoDB item and reference loot, all 1222 exact candidate identities and captured tier metadata/descriptions, RequiredLevel at most 60, and no item-loot conditions attached to 1278051. A mismatch raises an error and rolls back rather than installing a partial pool.

Normal cache 1278050, other containers, item templates, conditions, brackets and player progression are not written. Reserved references 9003001/9003002 are checked for ownership, external consumers across all loot stores, and reference conditions before transactional writes. Both loot tables must use InnoDB. Reapplication preserves the same two owned pools.

SQL 50 embeds both tiers and does not require SQL 49. SQL 20 ownership must already be present. CREATE ROUTINE permission is required. Rebuild the changed module, apply SQL 50 to acore_world, and restart worldserver. Expected query output: two root rows with 75/25 chances, 611 candidates in each reference pool. No live SQL was executed.

## Validation

Checked all 1222 generated candidate tuples against the saved candidate CSV, with 611 unique items per tier and no overlap. Deterministic enumeration of 10,000 tier rolls selects Heroic 7500 times and Normal 2500 times. Varying within-tier stat weights leaves those tier totals unchanged. Each leaf item has MinCount=MaxCount=1 and the scoped guard forces one iteration for zero, fractional and increased global reference amount rates.

Verified grouped-reference processing, shared Loot/container GUID propagation, equal-choice hook behavior, and the exact OnAfterRefCount signature and enabled-hook enum against this branch's core source. Existing identity/metadata/condition preflight checks are retained. Reserved namespace searches found no existing 9003001/9003002 pools in the supplied loot export or local module evidence.

The earlier direct-pool predicate model checks established rejection of missing items, changed tier metadata and existing cache conditions. The new tier mutation was exercised in a SQLite data model: 611 leaves per pool, exclusive 75/25 root group, unchanged Normal cache, and idempotent reapplication passed. The guard was checked separately. MySQL stored-procedure execution, C++ compilation and in-game opening were not tested.

Source item dump SHA-256: 3e36f8748b12b89605ec278953ad4c9c3db505757d4bc9a7294ea19c052e243e.

## SQL 50 temporary-table compatibility fix

The initial SQL 50 tier-count IF referenced tmp_ms_heroic_candidate twice in one statement, causing MySQL error 1137 before persistent loot writes. Both counts now come from one conditional-aggregate SELECT into procedure-local variables. All candidate-table statements use a single reference. The failed invocation reaches neither persistent DELETE nor INSERT; rerun the complete corrected SQL 50, which recreates its temporary table and procedure.

Conditional counts were checked against the 1222 candidate tuples and missing-tier/empty fixtures in SQLite. Full MySQL procedure execution remains untested. See [MySQL temporary-table restrictions](https://dev.mysql.com/doc/refman/8.4/en/temporary-table-problems.html).
