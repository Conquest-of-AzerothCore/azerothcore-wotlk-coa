---
name: coa-zone-rescaling
description: >-
  Plan or implement repeatable level-60 outdoor zone conversions for CoA, covering ordered health and damage
  scaling, creatures, quests, equipment, and rewards. Excludes dungeon and raid instance conversions.
---

# CoA zone rescaling

Follow the target checkout's AGENTS.md and coa-development skill. For the initial definition and unresolved
inputs, read [Hellfire Peninsula](references/hellfire-peninsula.md). Use it as a worked design, not installed data
or permission to convert the zone. Drafting or auditing the skill does not authorize gameplay changes.

## Define the zone

Collect only unresolved owner decisions; preserve choices already made. Derive IDs, affected records and current
values from effective source, DBC and database data rather than asking the owner to supply them.

- Zone identity, included subzones and explicit exclusions; order index and any prerequisite or access policy.
- Character entry/quest level range, target ordinary creature levels, and elite, rare and outdoor boss levels.
  A maximum character requirement of 60 does not by itself settle whether bosses may be level 63.
- Baseline character build and equipment, solo/bot/group assumptions, desired ordinary kill time and incoming
  damage, and group expectations for elites and outdoor bosses. Select concrete installed baseline comparables.
- Health and damage increments per index, linear versus compound growth, and exceptions for creature roles.
- Owner-supplied reward level and allowed item-level range for each zone; allocate budgets by quality/source
  and compare to existing dungeons and raids. Do not extrapolate reward levels or ranges from zone order or
  combat scaling. Set requirements
  at most 60; do not confuse character requirement with item level or derive gear budgets from the combat scaler.
- Quest entry gates and rewards, XP-at-cap and gold policy, dungeon-linked chains, reputation and profession
  coverage, travel/flying dependencies, faction access, and whether random bots should use the converted zone.
- Whether shared items may change in place, including existing copies, or require zone-specific variants.

Present the input list and provisional choices when asked for a design. Unknown values remain unresolved;
a worked example is not an approved numerical budget. Do not demand implementation inputs to finish a draft.

## Keep progression separate from levels

Store a stable zone identity and an explicit nonnegative order index. Hellfire Peninsula is index 0;
Zangarmarsh is index 1; Terokkar Forest is index 2. Later indices are owner inputs. An index is not a raw
multiplier: index 0 must never produce zero health or damage. Do not introduce entry locks from order alone.

Proposed linear model, pending the owner's choice:

```text
health(n) = converted_baseline_health * (1 + n * health_step)
damage(n) = converted_baseline_damage * (1 + n * damage_step)
```

Here steps are fractional increments, not percentages entered as whole numbers. If compound growth is chosen,
use `(1 + step) ** n` instead. Show the resulting multipliers for the entire chosen sequence before implementation.
The converted baseline is each creature's appropriate level/role budget, not one identical HP or damage value
for every creature. Prefer original per-template health recalculated at the target level, followed by the
owner-approved common zone multiplier. Preserve original health modifiers, class/expansion base-stat choices
and meaningful differences. Include world/rank rates once and retain precise integer results rather than
rounding every creature to common thousands. Hellfire's approved ordinary-enemy baseline multiplier is 10;
its elites, bosses and documented special-purpose exceptions keep separate budgets. This is variation between
templates, not random per-spawn rolls; obtain a separate policy before introducing random health. Derive it from level-60 stat tables and actual comparables. Preserve meaningful elite/boss
roles, armor/resistance, attack speed and mechanics; evaluate mana and resource pools as levels change.

Keep zone order data, shared step settings and intentional exceptions separate. Define supported bounds and
rounding before implementation. Derive effective results from a pinned unscaled baseline, never multiply already
scaled live rows. Reload, restart, respawn and migration reapplication must not compound the result.

## Audit the outdoor boundary

Resolve the parent zone and its child areas on the continent map. Do not select all of Outland by map ID, rely
only on a quest's category, or assume the quest giver's location describes every objective. Include patrols,
rares, outdoor bosses, quest summons, scripted waves, escorts, gameobjects and cross-border chains in the audit.
Exclude dungeon and raid maps, their enemies, difficulty variants and their reward pools from modification.
Identify instanced scenarios separately before deciding whether they belong to this outdoor conversion.

Trace creature templates, spells, loot/reference loot, items and scripts shared with other zones or instances.
Do not change a shared record globally to solve one zone without explicit owner authorization. Record an approved in-place shared-item policy and its out-of-zone effects; Hellfire now excludes generic/shared world drops after its owner narrowed the initial beta scope. Choose a scoped runtime path or isolated data variant
where necessary. Moving creatures, summons and projectiles need a defined rule for zone ownership; specify when
an originating zone's budget is retained or refreshed. Do not rescale a creature's HP repeatedly as it crosses
an area boundary. Preserve player pets/guardians, charmed units and unrelated neutral/town NPCs unless in scope.
Audit hostile quest actors and friendly escorts separately rather than scaling every NPC indiscriminately.

## Build the conversion proposal

1. Inventory affected spawns/templates, quests, drops, vendors, reputation rewards, recipes and crafted outputs.
   Include existing custom scaling, world rates, expansion base-stat selection, scripted health and bot rules.
   Identify shared records and every path that could change excluded instances.
2. Convert creature levels and base combat budgets first. Then apply the zone health and damage factors once.
   Trace melee, ranged attacks, direct spells, periodic damage, scripted casts and environmental effects.
   Avoid double-scaling spell damage through both caster stats and a final damage modifier. Review percentage
   damage, shared HP, damage reflection, healing and lethal mechanics separately; retain explicit exceptions.
3. Show representative before/after effective stats for a common melee mob, caster, rare, elite, outdoor boss,
   quest wave and escort. Compare kill time and player survival using the selected gear and roster, not HP alone.
4. Audit quest minimum/display/maximum levels, prerequisites, objective actors, starter items and completion
   scripts. Remove over-60 character requirements only within the agreed range; preserve valid lower gates,
   faction, reputation and class intent. Check offered, accepted, completed and rewarded states, not just UI.
   Adjust scripted encounters and quest-item spells alongside enemy stats. Report dungeon-dependent chains
   as blocked or deferred and obtain a policy before bypassing their objectives or prerequisite rewards.
5. Rebudget all in-scope equippable rewards and drops by slot, quality and role: stats, weapon DPS/speed, armor,
   block, resistances, sockets/bonuses, procs, on-use effects, enchants and set bonuses. Audit level requirements
   enforced by spells, quests and vendors as well as item templates. Preserve or replace class-specific effects
   with supported CoA mechanics within the agreed gear budget. Record each replacement and affected versions. When the owner delegates numeric proc/on-use tuning, scale the preserved original magnitude by target/original item level, retaining cooldowns, durations and activation chances; classify utility and percentage effects separately. A drop appearing in a zone loot reference is not sufficient evidence of zone ownership. Prefer explicit zone quest, named-loot, faction and PvP reward manifests over generic world/chest pools.
6. Separate equipment from currencies, quest objects, consumables, recipes and materials. Lower a profession,
   skill or flight requirement only when authorized by its policy; a level-60 equip cap does not authorize this.
   Trace gold, XP, reputation, repeatables and alternate reward paths for progression bypasses. Audit shared
   rewards, Bloodforged variants and owned copies before choosing in-place edits versus new item IDs.
7. Audit zone discovery/travel, portals, flight masters, flying-only objectives, bot zone restrictions and bot
   quest/gear eligibility. List the minimal integrations required by the approved access policy. Order does not
   automatically imply raid-phase, Callboard or Manastorm integration.

Present affected counts, benchmark-backed budgets, the scaling formula, shared-data isolation, exceptions,
blocked content, before/after examples and remaining decisions. Keep the per-zone definition in the repository
alongside any eventual shared implementation. Do not add a generator or runtime system merely to author a skill.

## Implement and verify when authorized

Reuse effective scaling and data mechanisms where suitable; verify that their scope can exclude instances.
Use repeatable pending migrations and stable ownership records for any generated variants. Record the baseline
revision and transformation inputs so future adjustments can be regenerated without reading scaled results as
originals. Preserve completed quests and character progress; do not reset inventories or quest state implicitly.

Use verify_all selections appropriate to the implemented changes and repository SQL/C++ checks. In an isolated,
resource-bounded environment, verify baseline index 0, successive indices, approved boundary behavior, summons,
respawn/reload/restart, damage paths and reapplication. Confirm health/damage factors apply exactly once.
Verify quests and rewards through normal interactions at the target levels, including both factions where
relevant, and verify equipment stats/effects. Check shared creatures/items in an unrelated outdoor zone and an
excluded dungeon remain correct. Check representative bots only if bot use is in scope.

List manual acceptance for solo pacing, elite/boss group difficulty, quest-chain travel and client tooltip/UI
updates. Report actual coverage and pending checks. Skill validation is not proof of a working conversion.
Implementation, live database updates, installation and deployment retain their separate authorization scope.
