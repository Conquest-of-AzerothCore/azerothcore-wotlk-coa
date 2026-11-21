---
name: coa-dungeon-rescale
description: >-
  Plan or implement level-60 conversions of every five-player dungeon in a named zone, with a target Normal
  item level, three difficulty budgets, encounter scaling, and dungeon quests and rewards. Excludes outdoor
  zone and raid conversions.
---

# CoA dungeon rescale

Follow the checkout's AGENTS.md and coa-development skill for repository procedures. Creating or editing this
skill does not convert content or authorize live changes. For Hellfire's dungeon boundaries and existing scaling
paths, read [the Hellfire reference](references/hellfire-peninsula.md) when converting that zone.

## Inputs and settled defaults

Required invocation inputs are **zone** and **target Normal item level**. Resolve the zone and all its five-player
instance maps from effective data, rather than requiring IDs from the owner. Discover entrances, satellite
wings and dungeon quest chains. Exclude raids even when they share the same entrance complex.

Optional Normal **health baseline multiplier** and **damage baseline multiplier** default independently to 1.
A common baseline multiplier may set both; explicit individual values override it. Preserve already supplied
values. Require finite positive multipliers and a positive integral item level supported by the installed
budget data; do not silently clamp unsupported inputs.

- Target players: level 60. Non-boss combat creatures, including elite trash and ordinary encounter adds: 60.
  Bosses: 63. Classify actual encounter roles from scripts/data rather than treating every named elite as a boss.
- Preserve original Normal per-template health and damage modifiers, recalculating class/expansion base stats
  at the target creature level before applying the baseline multipliers. Keep original differences between
  creatures; do not assign a single common HP pool or round results to thousands.
- Keep five-player group size and global playerbot rules. Do not introduce raid flex or bot health weighting.
- Retain item quality, role, slot and weapon speed. All in-scope equipment in one difficulty receives the exact
  target item level, rather than an outdoor-style quality or boss-position item-level range.
- Cap over-60 character equip and ordinary dungeon quest requirements at 60. Preserve valid lower
  requirements and separate reputation, profession, class and faction requirements.
- Every converted dungeon must admit level-60 characters in Normal, Heroic and Mythic, through both direct
  entry and Dungeon Finder. Lower character-level gates above 60 and ensure upper bounds include 60; preserve
  valid lower minimum levels. Audit both access tables and effective LFG DBC/SQL overrides, including the
  configured source of level requirements. Scope changes to converted maps, without global access overrides.
- Preserve physical locks, key items, Heroic reputation/key requirements and non-level attunement conditions.
  If a required key or its acquisition chain blocks level-60 access, lower only its character-level gates;
  preserve quest objectives, rewards and other requirements. Unrelated raid attunements remain outside scope.
- For ordinary prerequisite quests outside the zone, lower level gates to 60 while preserving their rewards
  and objectives. Preserve disabled MinLevel 255 records. Required dungeon access/key chains follow the
  level-gate exception above; unrelated attunements remain exempt.
- Include dungeon gear rewards from quests offered outside the instance. Standard one-time quests use the
  Normal item level; explicitly Heroic-only quests use Heroic. Preserve completion history and objectives.
- Update previously obtained dungeon-specific gear, including equipped, bag, bank and mail copies. Preserve
  shared items whose origins are unknown; use reliable provenance for conversion of existing shared copies.
- Preserve drop chances, quantities, conditions, loot groups and quest-item drops. Rebudget equipment without
  changing reward probability or introducing extra guaranteed drops.
- Leave gold, XP, currencies, consumables, recipes and profession/material rewards unchanged by default.
  Inventory these alongside gear and flag a level gate that prevents intended level-60 quest completion.
- Do not add Ascended tiers, Mythic+ affixes/reward rules, release phases or new attunements implicitly.

## Difficulty contract

Let `I` be the input Normal item level. The factors below are ratios of the same converted Normal baseline,
not repeated multiplication of the preceding mode or additional factors over native Heroic template stats.

| Difficulty | Equipment ilvl | Health factor | Damage factor |
|---|---:|---:|---:|
| Normal | I | 1.00 | 1.00 |
| Heroic | I + 3 | 1.44 | 1.50 |
| Mythic | I + 6 | 1.88 | 2.00 |

For each creature and damage path:

```text
Normal health = original Normal health recalculated at level 60/63 * health baseline multiplier
Normal damage = original Normal damage recalculated at level 60/63 * damage baseline multiplier
Mode health = Normal health * mode health factor
Mode damage = Normal damage * mode damage factor
```

Specify integer rounding and include rank, world/map and configured rates exactly once. Recalculate melee and
ranged damage from the new level's stats while retaining attack speed. Audit original spell damage, level
coefficients, scripted values and periodic effects independently; lowering a creature's level alone does not
reduce fixed spell damage. Establish each spell's level-60 Normal budget before applying mode damage ratios.
Account for native Heroic spell substitutions without stacking their authored damage increase a second time.
Preserve mechanics, timing, percentage-health effects, control durations and avoid-or-die abilities unless a
specific exception is needed; disclose exceptions rather than silently multiplying every numeric spell field.

## Audit the conversion boundary

1. Identify all selected instance maps, encounter layouts, native difficulty templates and spawn masks,
   scripted summons, dynamic chests, doors, events, access requirements and difficulty-specific spell ranks.
   Verify whether Mythic exists and how the core selects it; do not assume a raid difficulty ID or that adding
   spawn bits alone creates a working mode.
2. Trace boss, trash, chest and scripted equipment loot through nested references, conditions and loot groups.
   A stored zero chance can mean an equal-chance group member. Include guaranteed rewards, end-of-run chests,
   dungeon completion spoils, dungeon-specific completion caches and quest turn-ins. These paths must issue
   the same intended equipment budgets, without bypasses. Preserve unrelated cache/module reward policies.
3. Include all equipment produced by those dungeon loot paths, regardless of quality or starting level.
   Do not convert unrelated items globally because they occur in a shared world-drop reference. Use
   instance/difficulty-scoped variants or routing for shared items; outside sources keep their existing budgets.
   Convert previously obtained dungeon-specific items as well as new drops. Use reliable provenance for old
   shared items; shared copies with unknown origins remain untouched. Do not infer origin from the owner's
   current location, quest completion or inventory companions.
4. Trace dungeon quests by objectives, starters/enders, scripts, instance flags and prerequisites, not zone
   category alone. Include required items, keys, quest-item spells and reward previews. Keep unrelated outdoor
   quests out of the conversion. Identify shared reward IDs and prerequisites blocked above level 60.
   Trace required access/key chains through level-60 entry; lower blocking character-level gates only, retaining
   their objectives, rewards, reputation and other conditions. Leave unrelated attunements unchanged.
5. Trace existing dungeon, native per-item, Destiny Weaver and Mythic+ scaling. Decide which mechanism owns the
   final creature and item values for manual entry, Dungeon Finder, loot rolls and quest rewards. A raw SQL
   ItemLevel or HP value is not proof of the final runtime budget. Do not change global scaling to fix one zone.

Before applying changes, show the dungeon list, representative before/after health and gear, and expected
melee hits and major boss abilities against a representative level-60 five-player party. Identify the party's
gear/build benchmark, tank health/armor, relevant resistances and defensive assumptions from actual data.
Show raw and mitigated noncritical damage, swing intervals, tick intervals/target counts for major abilities,
and relevant burst combinations across all three modes. Separate calculated expectations from measured
combat results. Difficulty ratios alone do not establish that Normal is balanced. Resolve only material
missing choices; routine effect mappings do not require per-item owner review. Creating the skill does not
run a conversion.

## Rebudget gear, effects and quests

Use pinned original templates, effective DBC/SQL spells and original class-level data. Retuning must regenerate
from that baseline, not multiply already converted live values. Retain stable original-to-variant mappings and
apply follow-up migrations instead of rewriting already applied migration files.

- Rebudget primary stats, ratings, resistances and Power by installed quality/slot budgets at I/I+3/I+6.
  Derive armor, shield block and weapon DPS from matching slot/subclass and caster/physical comparables.
  Include wand damage and preserve weapon speed and damage spread.
- Scale random properties and suffix factors, socket bonuses and appropriate enchant effects. Distinguish
  enchantment-pool IDs from direct DBC property IDs; converted nonzero pools must contain valid choices.
  Check startup validation as well as SQL relationships so invalid affixes are not cleared in memory. Use existing
  client-known affixes of the same name/stat family where possible. Preserve legacy canonical affixes as
  aliases across retunes; repeated inventory load, acquisition or relog must not scale them again. If a
  prior conversion affected out-of-scope items, restore them explicitly and keep cleanup mappings until
  older copies can normalize without retaining those items in fixed dungeon scaling.
- The owner delegates numeric proc/on-use tuning: use original magnitude times target item level divided by
  original item level for flat damage, healing, absorbs, resource restoration and stat grants. Trace triggered
  children and level-based formulas. Preserve proc chances, cooldowns, durations and stack limits. Treat
  percentage and utility effects by their actual mechanics; do not scale cooldowns or double-scale weapon
  damage through both a weapon-percent effect and rebudgeted weapon DPS.
- New item identities need valid Item DBC rows and client delivery both on acquisition and on relog with
  existing copies. SQL rows alone do not prove delivery: check stream eligibility, including registries loaded
  after the initial client patch list is prepared. Verify icons and equipped appearances in the client.
- Fixed items must bypass native/captured stat ladders in the client query handler as well as acquisition.
  Test original boss IDs and new shared-loot variants at preview key 2 and each mode budget: preserve the
  requested cache key while returning fixed stats and actual item level. Existing copies must advertise their
  fixed level on login, ignoring stale stored scaling keys.
- Isolate effects shared with unrelated content, preserving applicable script/proc bindings and client text.
  Resolve obsolete original-class effects to supported CoA abilities or class-neutral role benefits at the
  target budget. Record the mappings; do not ask the owner to review each effect.
- Quest gear uses the quest's defined difficulty, not the player's map or mode at turn-in. Do not introduce
  repeatable quest tiers merely to make one-time rewards vary by mode. Verify offer, accept, objective credit,
  completion, turn-in, reward selection and delivery at level 60, including both factions where applicable.

## Implement and verify within authorization

Use repository SQL/C++ procedures and focused verify_all stages. In isolated, resource-bounded verification,
check the complete migration sequence and identical results on replay; all three mode entries and spawn paths;
representative trash, caster, boss and summon levels/health/damage; boss/chest/trash loot and mode routing;
quest turn-ins, end-of-run chests and completion rewards; equipment effects and existing-copy normalization;
and unchanged outside sources. Verify both previously owned dungeon-specific gear and untouched shared
copies with unknown origins. Compare mapped loot entries before/after to prove chances, quantities,
conditions, groups and quest-item drops are preserved. Verify level-60 direct entry and Dungeon Finder
eligibility for every converted mode, including effective DBC level gates. Confirm key/reputation conditions
and access-quest objectives/rewards are preserved, and outside access records are unchanged. Check ratios
after all runtime scaling, not only database rows.

Compare the same encounter across modes to prove 1/1.44/1.88 health and 1/1.5/2 damage without compounding.
Include death/respawn, encounter reset and restart persistence. Separate gameplay proof from schema/build
checks and client tooltip acceptance. On this realm, a second real worldserver previously exhausted host
resources; use another machine or stop the live process during an authorized test window.

Report dungeon coverage, final budgets, preserved mechanics, scoped/shared-item treatment, effect replacements,
verification evidence and pending manual acceptance. Installation, live SQL application, restart, commits and
publication remain governed by the current task's authorization; do not deploy merely because a skill exists.
