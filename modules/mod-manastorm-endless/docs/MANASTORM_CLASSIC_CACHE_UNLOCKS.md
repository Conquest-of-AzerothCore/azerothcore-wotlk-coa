# Classic cache progression

The current selected policy uses the documented Season 9 Classic reward ladder as a Season 10 reconstruction
baseline. It is not a recovered original S10 table. The historical SQL 47 Chapter-2 seed remains immutable.
Apply `zzzz_rev_20261025_100_manastorm_s9_classic_cache_progression.sql` through the normal world updater.
Its filename sorts after historical module seeds and snapshots, including fresh installs; do not replay SQL 47
alone as the final state. Reinitializing seed data must finish with the new correction.

Source: https://kami-labs.fr/en/ascension/guides-ascension/guide-du-debutant-pour-le-manastorm-en/
Adjacent boundaries in the community guide overlap; the selected disjoint ranges give each shared endpoint to
the earlier tier. The Heroic/Normal boundaries and all other ranges below are a selected reconstruction policy.

| Inclusive depth | Cache item | Tier |
| --- | --- | --- |
| 1–50 | 1278050 | Normal Dungeons |
| 51–100 | 1278051 | Heroic Dungeons |
| 101–150 | 1278052 | Zul'Gurub |
| 151–200 | 1278053 | Heroic Zul'Gurub |
| 201–300 | 1278054 | Mythic Dungeons |
| 301–350 | 1278055 | Mythic Zul'Gurub |
| 351–450 | 1278056 | Molten Core |
| 451–500 | 1278058 | Heroic Molten Core |
| 501–550 | 1278059 | Mythic+ 1–10 |
| 551–600 | 1278060 | Mythic Molten Core |
| 601–700 | 1278061 | Onyxia & Molten Core |
| 701–750 | 1278063 | Heroic Onyxia & Molten Core |
| 751–800 | 1278064 | Mythic+ 11–20 |
| 801–900 | 1278065 | Mythic Onyxia & Molten Core |
| 901–1000 | 1278066 | Blackwing Lair |
| 1001–1050 | 1278068 | Heroic Blackwing Lair |
| 1051–1150 | 1278069 | Mythic Blackwing Lair |
| 1151–1250 | 1278070 | Ruins of Ahn'Qiraj (AQ20) |
| 1251–1300 | 1278072 | Heroic Ruins of Ahn'Qiraj |
| 1301–1350 | 1278073 | Mythic+ 21–30 |
| 1351–1450 | 1278074 | Mythic Ruins of Ahn'Qiraj |
| 1451–1550 | 1278075 | Temple of Ahn'Qiraj (AQ40) |
| 1551–1600 | 1278077 | Heroic Temple of Ahn'Qiraj |
| 1601–1700 | 1278078 | Mythic Temple of Ahn'Qiraj |
| 1701–1800 | 1278079 | Naxxramas |
| 1801–1850 | 1278081 | Heroic Naxxramas |
| 1851–1900 | 1278082 | Mythic+ 31–40 |
| 1901–maximum depth | 1278083 | Mythic Naxxramas |

`manastorm_cache_bracket` selects the physical reward; `manastorm_cache_unlock_requirement` requires the
preceding completed depth (start minus one), separately per character, mode and track. This preserves the
existing anti-skip policy, not a claim about the proprietary unlock rules. Failed history reads never unlock a
protected tier. Completion uses the floor actually completed, prospectively within the existing transaction;
active native previews use committed history and the same resolver. Normal leveling routing, first-clear Bonus
Caches, weekly allowance, cache contents and already-owned items remain unchanged. TBC rows remain disabled.
The regular-cache trigger is unchanged: crossing a bracket boundary alone does not grant a cache.

With `Manastorm.FollowReleaseStage = 1`, Heroic Dungeons require stage 1, all five mapped Mythic dungeon tiers
require stage 2, and each mapped raid family requires its raid release. Combined Onyxia/MC requires Onyxia
(stage 5), so both raids are open. Closed tiers fall back to the highest eligible lower DB bracket, including
existing depth requirements. Greedy Demon uses the item-level ceiling derived from released enabled cache
brackets; it does not check every item's original raid. Segment selection is unchanged.

The native pre-run Potential Rewards UI retains generic identity 97884; it has no server-side selected-depth
request for an exact physical cache preview. Active native state carries the resolved physical cache ID.
In-game queue/tooltip display remains a manual acceptance check. The migration does not alter native identity
97884 or install a second reward catalogue in client Lua.

Historical conflicts remain explicit: item 1278054 describes 201–250, while the selected community baseline
uses 201–300. Other old tooltips reflect Chapter-2 ranges. Item descriptions, toast depths and loot pools are
preserved as evidence and are not silently rewritten. Existing Ascended variants are not assigned guessed
award depths. The default five regular endgame caches per week, shared across tiers, remains independent of
this table; no counter reset or cadence change is introduced.
