# Review of three Molten Core caches and SQL 26

SQL 26 already restores the described gear families. SQL 55 is a small roll-processing follow-up for
1278056, 1278058 and 1278060; it does not rebuild or rewrite any item pool.

## Descriptions and preserved default behavior

| Cache | Depth range | Guaranteed rewards | Optional rewards under SQL 26 defaults |
| --- | --- | --- | --- |
| 1278056 Molten Core | 221-280 | One Mythic ZG and one Normal MC | 10% plain Mythic Dungeon |
| 1278058 Heroic Molten Core | 281-340 | One Normal MC | 10% Heroic MC; 10% plain Mythic Dungeon |
| 1278060 Mythic Molten Core | 341-425 | One Heroic MC | 50% second Heroic MC; 10% each other family |

1278060's other optional families are Mythic MC, Normal Onyxia and Mythic 1-10 Dungeon gear.
All optional rolls are independent. SQL 26 sets optional-family chances to 10% and the second Heroic MC
chance to 50%; these are prior CoA policy choices, not recovered original Ascension odds.
SQL 55 preserves installed Chance values, including any valid customization of optional odds.
It does not change them to the 25% chosen later for the Zul'Gurub caches.

Exact exported descriptions:

    1278056
    Obtained from Manastorm Levels: 221 to 280
    Contains:
    + Mythic Zul'Gurub Gear
    + Normal Molten Core Gear
    Chance to contain:
    + Mythic Dungeon Gear

    1278058
    Obtained from Manastorm Levels: 281 to 340
    Contains:
    + Normal Molten Core Gear
    Chance to contain:
    + Heroic Molten Core Gear
    + Mythic Dungeon Gear

    1278060
    Obtained from Manastorm Levels: 341 to 425
    Contains:
    + Heroic Molten Core Gear (1-2)
    Chance to contain:
    + Mythic Molten Core Gear
    + Normal Onyxia Gear
    + Mythic 1-10 Dungeon Gear

## Pool review

Reused SQL 26 base IDs and previously saved dungeon/ZG mappings were checked against the supplied item
export. The matching rules reproduce all seven referenced pool counts; no membership reconstruction was
restarted and no new items were substituted.

| Reference | Family | Reproduced count |
| --- | --- | --- |
| 9002001 | Normal MC | 106 |
| 9002002 | Heroic MC | 86 |
| 9002003 | Mythic MC | 106 |
| 9002010 | Normal Onyxia | 14 |
| 9002022 | Mythic ZG | 122 |
| 9002030 | Plain Mythic Dungeon | 611 |
| 9002031 | Mythic 1-10 Dungeon | 6109 |

All reviewed candidates are epic equippable weapons/armor, RequiredLevel at most 60. The two plain dungeon
rolls use unranked @Mythic Dungeon@ items only. Ranked Mythic+ gear is intentional exclusively in 1278060's
separate 1-10 Dungeon family, as its description explicitly advertises it.
The Mythic 3 Tome of the Lost mapping remains ambiguous between 8263152 and 8263154; SQL 26 omits that
rank alone and retains its other nine unambiguous ranks. The 6109 count matches this existing omission.

Twenty base MC items have no recovered matching Heroic variant. Their absence explains the 86-item Heroic
pool versus 106 Normal/Mythic candidates. SQL 55 leaves those gaps intact:

| Base item | Name |
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

## Concrete runtime gap and fix

SQL 26's roots use GroupId 0. Core LootStoreItem::Roll multiplies sub-100 reference chances by the global
reference drop-chance rate, and reference processing multiplies counts by the global reference amount
rate. This can change advertised counts and configured odds despite MinCount/MaxCount both being one.

SQL 55 changes only GroupId on the eleven roots of these three caches to the row's Item key (groups 1-5).
Each roll therefore has its own explicit-chance group, whose core roll uses its installed Chance directly.
ManastormCacheLoot.cpp extends the existing scoped OnAfterRefCount guard to exactly these cache/reference
pairs, forcing one reference iteration per successful roll while the module is enabled. Existing stat
preference still chooses a gear item within the selected pure leaf pool.

Five other SQL 26 cache roots, every reference row, item templates, conditions, Mode 1/2 transport and
progression are unchanged. The older five caches are outside this follow-up's rate-guard scope.
SQL 62 subsequently reviews and guards those five caches separately; see
[ONYXIA_MOLTEN_CORE_CACHE_REVIEW.md](ONYXIA_MOLTEN_CORE_CACHE_REVIEW.md) for its prerequisite and pool evidence.

## Applying and validating

SQL 26 must already be applied. If it is absent, apply SQL 26 first, then SQL 55. Running SQL 26 again after
SQL 55 resets the roots to GroupId 0; reapply SQL 55 afterward. Rebuild the changed module and restart
worldserver after the database update. No live database query or write was performed for this review.

SQL 55 preflight checks three scriptless HAS_LOOT containers, eleven exact root references and counts,
valid guaranteed/optional chances, seven installed pool counts, pure epic level-at-most-60 gear leaves,
tier markers and absence of attached loot conditions. Missing or incompatible SQL 26 data raises an
error instead of silently building partial pools. Only item_loot_template is written, transactionally.

SQLite checks exercised the actual new predicates and UPDATE against all 7154 reviewed pool memberships
and all sixteen SQL 26 root rows. Eleven roots gained distinct groups; the other five and every reference
row were unchanged. Reapplication was idempotent, and a customized 17.5% optional chance was preserved.
Wrong references, weakened guaranteed chances, missing leaves, wrong difficulty markers and level-80
items were rejected. Each MySQL temporary table appears once per statement, avoiding error 1137.

C++ lint passed. SQL formatting, INSERT/DELETE safety, quoting and engine checks passed; its directory
check flags the intentional module base migration. MySQL procedure execution, C++ compilation and
in-game openings remain untested.

Source item dump SHA-256: 3e36f8748b12b89605ec278953ad4c9c3db505757d4bc9a7294ea19c052e243e.

## SQL 26 MySQL temporary-table compatibility correction

The original combined-pool UNION reads tmp_ms_mc_pool twice in one statement, causing MySQL error 1137
before persistent writes. SQL 26 now uses one SELECT DISTINCT with CASE to map MC and Onyxia source IDs
to the same combined pool IDs. DISTINCT preserves UNION's duplicate removal.

A later namespace collision IF also reads tmp_ms_mc_family three times. Its three predicates now execute
as separate IF statements with the same fatal collision error. All SQL 26 statements were checked for
repeated temporary-table references. SQLite checks confirmed identical combined candidates, overlap
deduplication and unchanged detection by each collision guard. Full MySQL execution remains untested.

After the reported error, download the corrected SQL 26 and rerun the complete file, then run SQL 55.
