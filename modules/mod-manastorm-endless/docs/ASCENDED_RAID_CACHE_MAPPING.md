# Remaining Classic Ascended raid cache restoration

SQL 63 restores five scriptless HAS_LOOT containers, all empty in the supplied loot export.
It embeds five raid-specific Ascended equipment pools and is self-contained.
These caches are outside SQL 47's active award catalogue; this restoration does not activate them,
change depth brackets or replace current progression rewards. Existing/manual copies can use their loot.

## Exported descriptions and reconstruction policy

The tooltips contain depth placeholders only. They do not establish original loot counts, additive raid
families, dungeon bonuses or exact item membership. The selected CoA policy follows SQL 26's Ascended MC
cache: one item from the named raid's Ascended equipment pool, personalized by existing stat preference.
No cross-tier or ranked Ascended +1-10 Dungeon pool is added. This is a reconstruction, not a recovered
original Ascension cache drop table. Exported depth placeholders remain historical evidence.

| Cache | Exact exported description | Selected pool | Candidates |
| --- | --- | --- | --- |
| 1278057 | @401 - 450@ | Ascended ZG | 122 |
| 1278071 | @1201 - 1250@ | Ascended BWL | 82 |
| 1278076 | @1501 - 1550@ | Ascended AQ20 | 143 |
| 1278080 | @1751 - 1800@ | Ascended AQ40 | 138 |
| 1278084 | @1951 - 2000+@ | Ascended Naxx | 128 |

## Reused source catalogue and mapping evidence

The reviewed ZG, BWL, AQ20, AQ40 and Classic Naxx catalogues supply epic equippable base items from their
Ascension-specific encounter/trash tables. Custom Ascension equipment, listed equipment rewards and
catalogued epic trash drops are retained. Non-equipment, recipes, sigils, currencies, components and
non-epic items are excluded. WotLK level-80 Naxx gear is not included.

Mappings match base name, class, subclass, equipment slot, epic quality and display model, with
RequiredLevel at most 60. Specific Ascended raid prefixes take precedence over generic Ascended Raid
prefixes. Plain Ascended raid items are distinct from @Ascended 1@ through @Ascended 10@ dungeon items;
those ranked variants are excluded. No Heroic or Mythic substitute is used.

| Family | Normal base identities | Specific Ascended matches | Generic Raid matches | Selected |
| --- | --- | --- | --- | --- |
| ZG | 122 | 116 | 6 | 122 |
| BWL | 82 | 73 | 9 | 82 |
| AQ20 | 144 | 117 | 26 | 143 |
| AQ40 | 139 | 117 | 21 | 138 |
| Naxx | 129 | 102 | 26 | 128 |

Generic Raid mappings rely on identity and base catalogue membership; a generic marker alone does not
establish raid membership. ZG and BWL have no missing/ambiguous preferred matches in this export.
AQ20, AQ40 and Naxx each omit the same ambiguity: base 14552 Stockade Pauldrons maps equally to Ascended
items 214552 and 314552. Both conflicting variants are omitted, matching the SQL 26 MC decision.
There are no other gaps or ambiguities in the selected mappings.

[ASCENDED_RAID_CACHE_CANDIDATES.csv](ASCENDED_RAID_CACHE_CANDIDATES.csv) records all 613 assignments,
base relationships, item IDs, exact item descriptions/metadata and source export line numbers.
Read the corresponding ZG/BWL/AQ/Naxx mapping reports for the encounter tables and base filtering.

Underlying catalogue: Szyler/AtlasLootAscension, verified 2026-10-07:

- [Items](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/Databases/Items/Classic/Instances.lua)
- [Menu](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/UI/Menus/ClassicInstances.lua)

Item-file Git blob: dd69a91b91e79c7056c78669ee1e2b8e7471d407.
Menu-file Git blob: 0be89e11d314385cc5c3a6fc0a56fdcd4f3bf5ff.
Original cache membership and odds have not been fully recovered.

| Owned reference | Family | Candidates |
| --- | --- | --- |
| 9003901 | Ascended ZG | 122 |
| 9003902 | Ascended BWL | 82 |
| 9003903 | Ascended AQ20 | 143 |
| 9003904 | Ascended AQ40 | 138 |
| 9003905 | Ascended Naxx | 128 |

## Runtime and migration

Each cache has one explicit 100% root group pointing to its pure Ascended raid pool. The scoped
OnAfterRefCount guard preserves one reward regardless of reference amount rates while the module is
enabled. Existing stat preference selects within that pool. All five cache IDs are recognized outside
active brackets for already-owned/manual copies.

SQL 63 owns only roots 1278057/1278071/1278076/1278080/1278084 and references 9003901-9003905. It does not
update items, scripts, names/descriptions, depth brackets, progression, other loot pools or Mode 1/2.
Preflight checks InnoDB loot tables, five scriptless HAS_LOOT containers, all 613 captured assignments
and exact metadata, five pool counts, namespace ownership, external consumers across all loot stores
and existing loot conditions. Writes are transactional and idempotent. Each temporary table appears
once per statement, avoiding MySQL 1137.

Rebuild the module, apply SQL 63 to acore_world, then restart worldserver. CREATE ROUTINE permission is
required. No live database write was performed. Previous migrations do not need rerunning.

## Validation

SQLite checks passed for all 613 generated SQL/CSV tuples and exact metadata, five pure Ascended pool
counts and base identities, ranked Ascended exclusions, Stockade ambiguity omissions, five guaranteed
one-item roots, repeat application and preservation of unrelated SQL 62 rows. The actual metadata
predicate rejected ranked descriptions, level-80 gear, changed display models and wrong quality.
The five-container preflight and recognition of all 35 endgame cache IDs were checked. Formatting and
single temporary-table references were checked.
SQL formatting, quoting, insert/delete safety and engine checks passed; the directory check flags the
intentional module base migration. C++ checks passed except for pre-existing blank-line warnings in
ManastormRewards.cpp, confirmed unchanged against HEAD.
MySQL procedure execution, C++ compilation and in-game openings remain untested.

Source item dump SHA-256: 3e36f8748b12b89605ec278953ad4c9c3db505757d4bc9a7294ea19c052e243e.
