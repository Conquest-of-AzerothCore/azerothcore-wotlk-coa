# Hellfire Peninsula dungeon example

Read this only when applying the skill to Hellfire. The conversion was installed on 2026-11-21. The realm
owner confirmed successful live dungeon testing and accepted the item icon and fixed-stat tooltip corrections.
The outdoor zone conversion does not include these instance maps.

## Instance scope

| Dungeon | Map |
|---|---:|
| Hellfire Ramparts | 543 |
| The Blood Furnace | 542 |
| The Shattered Halls | 540 |

Magtheridon's Lair is a raid and stays outside the dungeon skill even though it belongs to Hellfire Citadel.
The Ramparts final encounter pays through Reinforced Fel Iron Chests: gameobjects 185168/185169, loot IDs
21762/21764. Inventory both chests alongside boss corpses; scripted summons do not necessarily have DB spawns.
Blood Guard Porung is Heroic-only in the native layout; do not invent a Normal loot source by ignoring spawnMask.

## Example inputs

```text
zone: Hellfire Peninsula
normal_item_level: 65
normal_health_baseline_multiplier: 4
normal_damage_baseline_multiplier: 1
```

The owner approved these inputs and authorized installation on 2026-11-21.
The owner chose original Normal creature stats recalculated at 60/63 as the combat baseline and requested
optional baseline multipliers. Do not inherit the outdoor zone's 10x HP multiplier automatically.

| Mode | Equipment ilvl | HP / converted Normal | Damage / converted Normal |
|---|---:|---:|---:|
| Normal | 65 | 1 | 1 |
| Heroic | 68 | 1.44 | 1.5 |
| Mythic | 71 | 1.88 | 2 |

Every equipment drop in a selected mode gets that mode's target; preserve quality-based stat budgets.
Standard dungeon quest gear uses 65 in this example, Heroic-only quest gear 68. Equipment remains usable at 60.

## Pre-conversion findings to recheck

The 2026-11-21 live audit of rare/epic boss and chest gear found:

| Dungeon | Normal ilvl / required level | Heroic ilvl / required level |
|---|---|---|
| Ramparts | 85 / 60 | 110–115 / 68–70 |
| Blood Furnace | 88 / 61 | 110–115 / 68–70 |
| Shattered Halls | 112–115 / 68–70 | 110–115 / 68–70 |

Examples: Hellreaver 24044 is 85/60; Ironblade Gauntlets 24387 is 88/61;
The Willbreaker 27512 and Figurine of the Colossus 27529 are 115/70.
These are authored templates, not proof of per-instance scaling at loot delivery. Reinspect effective data.

## Existing paths to inspect

- `src/server/coa/DungeonLoot.h`: Classic Heroic/Mythic loot map whitelist; the audit found these three maps
  absent. Extend the correct scoped integration rather than assuming variant-table rows are sufficient.
- `src/server/coa/CoADungeonLoot.cpp`: post-processing and guaranteed boss gear; scope and source detection
  affect whether corpses and chests receive mode variants.
- `src/server/coa/AscensionNativeItemScaling.cpp` and
  `src/server/game/Miscellaneous/LocalLevelScaling.h`: stored per-item scaling, player choices and loot arrivals.
- `modules/mod-destiny-weaver/src/destiny_weaver_scaling.cpp`: Dungeon Finder versus manual-entry behavior.
- `src/server/scripts/Outland/HellfireCitadel/`: dungeon scripts, events, summons and mode-dependent spells.
- `modules/mod-coa-mythic-plus/`: distinguish fixed Mythic from keystone scaling and separately budgeted rewards.

The current outdoor skill has a deliberately narrow 196-item Hellfire manifest. Do not reuse its item list or
reset its creature budgets to implement the dungeon conversion. Shared dungeon loot may require scoped item
variants; generic world drops elsewhere must not change.

## Owner policies

All three dungeons must be accessible at level 60 in Normal, Heroic and Mythic through direct entry and
Dungeon Finder. Lower blocking character-level gates while preserving physical keys, Heroic reputation/key
conditions and access-quest objectives/rewards. Unrelated attunements remain untouched. Before applying changes, show
expected melee hits and major boss abilities against a representative level-60 party, with the benchmark
and mitigation assumptions stated. Preserve loot probabilities, quantities, conditions and quest-item drops.
Previously obtained dungeon-specific gear changes too; shared items of unknown origin remain untouched.
Include dungeon quest turn-ins, end-of-run chests and completion rewards in the budget and verification.

## Installed conversion

Approved Normal/Heroic/Mythic item levels are 65/68/71. Original Normal health recalculated at 60/63 is
multiplied by 4 before mode factors: final multipliers are 4/5.76/7.52. Normal damage retains the realm's
existing dungeon rate, then uses 1/1.5/2 mode factors. Original Normal attack intervals are retained across
modes so native Heroic template timing differences do not distort those ratios. Native Heroic spell-rank
magnitudes are normalized to their Normal family before the mode factor. Existing generic Normal hit caps,
Heroic/Mythic trash caps and per-player Dungeon Finder scaling defer to these fixed budgets for selected NPCs.

Eight `.sql` migrations numbered 20–27 cover combat, quests, equipment, affixes, effects,
routing and level-60 access. The normal startup updater applied them to the live realm on 2026-11-21.
There are 198 mode-specific combat rows for 66 map/template pairs,
including spell-triggered summons and the timed-event Executioner. Critters, triggers, prisoners, dialogue
heads, the training dummy and the decorative Blood Furnace Magtheridon/channeler are excluded from combat budgets.

The inventory includes 854 equipment sources, including 119 additional appearance-matched candidates for
the enabled 5% equipped-gear bonus. It produces 2,562 budgets: 153 existing dungeon-specific IDs updated in
place and 2,409 scoped variants for other modes/shared sources. The bonus chance is unchanged; new copies
are tagged to prevent them entering the global appearance-matched world-drop candidate index. Dungeon loot
routing changes only item identity and its affix/suffix budget, preserving quantities, conditions and rolls.
The original loot templates and unrelated sources remain unchanged. Fixed-affix mappings retain client-known
families and are idempotent; suffix factors follow the converted item level. Migration 27 corrects 99
variants from 33 direct-DBC-affix source items: these require a valid single-choice pool rather than an
empty pool generated by assuming every original property ID was already a pool. Numeric item effects use 84
isolated spell copies. Ability filters, cooldowns, durations and percentage/utility mechanics are retained.

The 20 ordinary dungeon quests have level-60 quest budgets; ordinary predecessor level gates outside the
zone also cap at 60, without reward/objective edits. The owner explicitly approved that prerequisite policy.
Kalynna's Request and Trial of the Naaru: Mercy remain unchanged as attunement exceptions. Dungeon gear
reward selection is mapped to the Normal budget independently of turn-in location. Rune, badge, currency
and key rewards are unchanged. Existing completion-spoils/mark issuance only covers the Classic map list;
this conversion does not expand those global reward systems. The Ramparts end chest is included in routing.

The access migration lowers Heroic Ramparts and Blood Furnace entrance minima from 70 to 60; Heroic Shattered
Halls already permits 60. Nine scoped LFG DBC overrides make Normal/Heroic/Mythic selection eligible at 60,
with target levels set to 60 and all non-level fields retained. Valid lower Normal minima remain unchanged.
The realm uses DBC level checks for Dungeon Finder, so entrance-table changes alone are insufficient.
All three retain their faction Flamewrought Key requirements and reputation gates. The Shattered Halls key
quests already permit 60 and its key has no character-level requirement; these records need no changes.
Mythic map definitions already exist in the installed MapDifficulty data. Spawn masks mirror existing Heroic
coverage into Mythic while preserving Normal-only and Heroic-only encounter distinctions.

Use `apps/coa-tests/hellfire_dungeon_rescale/fixture.json` as the preserved public pre-conversion baseline.
It contains original equipment, quest/access records, spawns, template/class stats, effective item spells and
loot references; regenerate from it rather than reading converted live values on a later retune. The private
MySQL regression applies all eight migrations twice and checks identical replay, complete mode routing, effect
values, unchanged shared originals/materials, level-60 entrance/LFG gates and unchanged key requirements.
It checks all non-level LFG fields and an unrelated dungeon record remain unchanged. Nine authored real-map
scenarios cover representative boss HP and corpse loot across all three maps/modes. They have not been run
through the automated native gameplay stage; authoring validation is not a runtime pass. The owner reported
successful live dungeon testing and confirmed that item icons and boss-item stats now display correctly.
That acceptance is manual and does not establish individual automated passes for every scenario or inventory
location. Avoid starting a second real worldserver alongside the live realm on this host.

Client-item regressions cover on-demand display rows for scoped variants and fixed stat replies for original
boss IDs. Fixed replies preserve the requested preview cache key while returning the actual 65/68/71 item
level, rebudgeted stats and armor. Existing owned copies advertise their fixed level on login despite stale
native scaling keys. These corrections are C++ changes and require the matching worldserver build; no
character-data repair or replacement loot is required.
