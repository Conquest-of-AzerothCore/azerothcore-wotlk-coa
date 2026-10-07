# Review of SQL 26's five later MC/Onyxia caches

SQL 26 already reconstructs these five caches. SQL 62 is a focused follow-up, preserving its one-item
policy and installed pools while stabilizing reward counts against global reference amount rates.
The five caches are outside SQL 47's active award catalogue. This change does not activate them.

| Cache | Reused reference | Preserved selection | Candidates |
| --- | --- | --- | --- |
| 1278061 | 9002040 | One Normal MC + Onyxia item | 120 |
| 1278062 | 9002004 | One Ascended MC item | 105 |
| 1278063 | 9002041 | One Heroic MC + Onyxia item | 100 |
| 1278065 | 9002042 | One Mythic MC + Onyxia item | 120 |
| 1278067 | 9002043 | One Ascended MC + Onyxia item | 119 |

Combined caches choose one item from the combined same-tier MC/Onyxia pool, not one from each raid.
The 'gear up to' descriptions and Ascended depth placeholders do not disclose original item counts,
additive families, lower-tier mixes or odds. This remains SQL 26's conservative CoA reconstruction
policy, not a recovered original Ascension loot table. No extra family or bonus roll is invented.

Exact exported descriptions:

    1278061
    Manastorm 601 to 700
    Contains gear up to Normal Onyxia's Lair!

    1278062
    @651 - 700@

    1278063
    Manastorm 701 to 750
    Contains gear up to Heroic Onyxia's Lair!

    1278065
    Manastorm 801 to 900
    Contains gear up to Mythic Onyxia's Lair!

    1278067
    @951 - 1000@

## Reused catalogue and review

SQL 26's MC base catalogue has 106 equipment identities; Normal Onyxia has 14. The reviewed Normal,
Heroic and Mythic MC mappings reproduce 106/86/106 items. Heroic MC's twenty missing variants remain
omitted, as documented in MOLTEN_CORE_CACHE_ROLL_REVIEW.md.

Ascended MC was checked against the supplied item export using SQL 26's exact name/class/subclass/slot/
quality and level-at-most-60 rule. Specific Ascended Molten Core prefixes take precedence over generic
Ascended Raid prefixes. Unique preferred matches also have the same display model as the base.
It yields 105 items and one ambiguity: base 14552 Stockade Pauldrons maps equally to 214552 and 314552.
Both conflicting variants are omitted; no tier substitute is made.

Heroic Onyxia yields 14 unique matches with specific Onyxia prefixes preferred over generic Raid prefixes.
Mythic and Ascended Onyxia reuse the previously reviewed 14-item mappings from BWL. No gaps or ambiguous
preferred matches were found in those Onyxia families. The same-tier unions therefore reproduce
120 Normal, 100 Heroic, 120 Mythic and 119 Ascended candidates, without duplicate item IDs.

[ONYXIA_MOLTEN_CORE_CACHE_CANDIDATES.csv](ONYXIA_MOLTEN_CORE_CACHE_CANDIDATES.csv) stores all 564 reviewed
pool assignments, exact item metadata/descriptions and source export line numbers for future reuse.
It records installed reference membership; it does not invent original cache probabilities.

Underlying source catalogue is the existing SQL 26 dataset from Szyler/AtlasLootAscension:

- [Items](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/Databases/Items/Classic/Instances.lua)
- [Menu](https://github.com/Szyler/AtlasLootAscension/blob/master/AtlasLoot/UI/Menus/ClassicInstances.lua)

Verified item-file blob: dd69a91b91e79c7056c78669ee1e2b8e7471d407.
Verified menu-file blob: 0be89e11d314385cc5c3a6fc0a56fdcd4f3bf5ff.

## Concrete runtime fix and migration

SQL 26 gives each of these five roots Chance 100, GroupId 0 and MinCount/MaxCount 1. Reference amount
rates can still change the number of reference iterations. SQL 62 changes only these five GroupId values
to Item (1), and the scoped OnAfterRefCount guard forces one iteration for the exact five cache/reference
pairs while the module is enabled. Existing stat preference chooses within the preserved pool.
All five IDs were already recognized for personalized opening outside active brackets.

SQL 62 checks InnoDB item loot, five scriptless HAS_LOOT containers, five exact guaranteed roots,
five installed pool counts and every captured candidate identity/metadata, pure level-at-most-60 epic
gear leaf fields and absence of attached loot conditions. Missing/incompatible SQL 26 data raises an
error rather than rebuilding partial pools. Only item_loot_template.GroupId is written, transactionally.
Reference pools, item templates, conditions, other cache roots, progression and Mode 1/2 remain unchanged.
Each temporary table appears once per statement to avoid MySQL 1137.

If SQL 26 is already installed, rebuild the module, run SQL 62, then restart worldserver.
If absent, apply SQL 26, then SQL 55 and SQL 62. SQL 55 preserves the three previously fixed active MC
caches. Rerunning SQL 26 resets all eight roots to GroupId 0, so reapply both SQL 55 and SQL 62 afterward.
CREATE ROUTINE permission is required. No live database write was performed.

## Validation

SQLite checks passed for all 564 SQL/CSV assignments and exact metadata, five pool counts, installed-root
and pool preflights, wrong references/chances/modes/counts and same-count identity swaps, and metadata
mismatch rejection. Repeat application changed only the five GroupId fields; the prior SQL 55 sentinel,
item templates and every reference row were preserved. The Ascended Stockade ambiguity exclusion,
formatting and single temporary-table references were checked.
C++ codestyle passed. SQL formatting, quoting, insert/delete safety and engine checks passed; only the
intentional module base-directory location was flagged by the SQL linter.
MySQL procedure execution, C++ compilation and in-game openings remain untested.

Source item dump SHA-256: 3e36f8748b12b89605ec278953ad4c9c3db505757d4bc9a7294ea19c052e243e.
