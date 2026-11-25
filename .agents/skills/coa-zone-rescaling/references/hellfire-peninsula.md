# Hellfire Peninsula: initial zone design

This definition began as a design example and now has an implementation candidate. The initial conversion is installed live as a beta. Historical proposals below are retained as context. Resolve zone/map identifiers against effective data when an audit is authorized.

## Owner inputs

These decisions define the conversion in progress. Live activation and deployment remain separate scope.

| Input | Settled decision |
|---|---|
| Zone | Hellfire Peninsula, order index 0, converted combat baseline. |
| Player level | Exclusively level-60 content. |
| Creature levels | Ordinary enemies cap at 60; elites and bosses cap at 63. |
| Combat benchmark | Reference solo DPS character in Normal Naxxramas gear, approximately 10,000 DPS. Common enemies should take about ten seconds to kill. Karazhan gear may also be present. |
| Incoming damage | Comfortable solo combat; several simultaneous enemies should become threatening. Derive exact budgets from representative player defenses and playtest evidence. |
| Group content | Retain group requirements; target five players. Audit existing outdoor raid bosses as possible exceptions before treating them as five-player content. |
| Reward budget | Baseline item level 63, with an allowed range of 59–66. Slot, role, quality and source determine actual budgets within that range. |
| Item identity | Change existing Hellfire-specific item IDs, including owned copies. Exclude generic world drops and broadly shared gear; restore earlier out-of-scope changes. |
| Zone growth | Default scaler 1.2, interpreted as a fixed 20% baseline increment per zone index for both health and damage. The owner supplies each zone's reward level and allowed item-level range independently. |
| Gold and XP | Preserve gold. Use Classic level-60-zone XP comparables; players already enter at cap, so XP is secondary. Preserve gold-at-cap behavior unless separately changed. |
| Consumables and professions | Leave rewards unchanged for later rebalance; exclude their item budgets from the equipment conversion. |
| Quest dependencies | Assume players have flying and dungeon access. Preserve flying objectives and normal dungeon completion requirements; do not add bypasses or convert instances. |
| Playerbots | Leave bot behavior and global access rules unchanged. |

## Zone progression model

| Zone | Order index | Health factor | Damage factor | Reward center |
|---|---:|---|---|---|
| Hellfire Peninsula | 0 | 1 | 1 | 63 |
| Zangarmarsh | 1 | 1.2 | 1.2 | Owner supplies per zone |
| Terokkar Forest | 2 | 1.4 | 1.4 | Owner supplies per zone |

The saved interpretation of default scaler 1.2 is a linear factor `1 + index * (1.2 - 1)` for health
and damage. It is not repeated multiplication by 1.2. Keep health and damage steps independently configurable
if a later tuning request separates them; both default to 0.2 here. Reward levels and allowed ranges are owner inputs for each zone, not a formula derived from its index.
Hellfire uses the supplied level 63 and offsets -4/+3, giving 59–66. Do not assume those offsets for other zones. Index 0 uses the converted baseline, not original expansion combat stats.

At 10,000 effective sustained DPS, ten seconds suggests roughly 100,000 effective damage to kill a common
mob. This is a starting estimate, not an approved identical raw HP for every creature. Verify armor,
resistances, ramp-up, travel and downtime against the reference player; preserve role and encounter differences.

## Audit-derived proposals and later decisions

The inputs are sufficient to begin the Hellfire audit and tuning proposal. No further owner input is mandatory
before that audit. Implementation and deployment remain separate requests.

- Derive exact incoming damage from the comfortable-solo goal and representative Normal Naxxramas player
  health/defenses. Compare physical and caster pressure and test multiple attackers; do not infer it from mob HP.
- Propose the 82–89 equipment distribution by quality, source, slot and role from installed comparables.
- Retain group encounters with a five-player target. Identify any outdoor raid boss whose conversion requires
  a substantial mechanic redesign and bring that concrete exception back to the owner.
- Disclose shared-item effects outside Hellfire before making in-place edits to shared records.
- Obtain each later zone's reward level and allowed range from the owner when that zone is requested;
  do not extrapolate them from Hellfire or the combat scaler.

Creature/quest IDs, current rates, row counts, item sharing and baseline measurements are investigation outputs,
not data the owner must supply. Present concrete exceptions and the remaining numerical choices in the audit.

## Proposed Hellfire changes after a separate implementation request

- Define the outdoor parent zone and included subareas with index 0, preserving adjacent zones and instances.
- Rebudget enemy levels, effective HP, armor/resources and damage to the chosen character benchmark. Preserve
  elite/rare/boss identity and inspect caster spells, periodic effects, scripted summons and quest events.
- Use level-appropriate quest gates and displayed levels; adjust objective encounters and rewards together.
  Preserve quest history, faction routes and valid chain dependencies. List any instance-dependent chain gaps.
- Reduce over-60 character item requirements and rebuild equipment budgets by source, quality, slot and role.
  Trace equipment vendors, reputation rewards and shared copies. Leave consumable and profession rewards unchanged.
- Define reusable zone order and shared step inputs so the same procedure can later produce Zangarmarsh and
  Terokkar budgets. Exact config names and storage are implementation decisions, not features already installed.
- Verify ordinary mobs, casters, elites, a boss, escorts, summons and representative quest rewards. Exercise
  respawn/restart and repeated migrations. Confirm an excluded instance and shared records remain unaffected.

Playerbots has independent Outland restrictions on level-60 realms. Those global controls remain unchanged.
Do not open random-bot travel or alter bot behavior as a side effect of this conversion.

The later dungeon skill can take over instance conversion and any deferred dungeon-linked reward decisions.
This outdoor skill must remain usable without converting those instances.

## Read-only audit and proposed budgets

The 2026-11-21 audit used source revision `6830333ab8`, installed terrain/DBC files, and read-only live
world queries. These observations are not a deployed conversion or gameplay verification.

- Hellfire is parent area 3483 on map 530, with 53 parent/child area records. Terrain lookup identified
  3,196 creature spawns across 443 templates and 2,095 gameobject spawns. These include friendly NPCs,
  holiday objects and helpers, not just hostile conversion targets. No creature rows are tagged zone 3483.
  Outland had two missing terrain tiles; terrain counts are provisional. Caves/WMO ownership, patrols,
  dynamic summons and cross-border endpoints still need runtime or targeted source confirmation.
- There are 265 candidate quests from the Hellfire category and local quest starters, plus six extra
  quests ending locally. Of the initial candidates, 223 display above level 60 and 54 have minimum levels
  above 60; the latter includes 23 minimum-level-255 rows. Preserve these disabled rows rather than clamping
  them to 60. There are 17 quests advertising group sizes and 13 marked dungeon content in the candidate set.
- Candidate quest equipment comprises 156 unique items: 113 uncommon and 43 rare, at item levels 60–114.
  All already require level 60 or less. Rebudget stats rather than merely altering equip requirements.
  Three of these rewards are also offered by Zangarmarsh quest 9734, Return to the Marsh: items 25522–25524.
  Disclose that in-place edits affect those rewards and owned copies too.
- Recursive creature loot contains 775 candidate equippable items, including generic shared world drops.
  Local vendors have 716 offers, 91 classed as weapons/armor; these are audit candidates, not a final gear
  manifest. Gathering nodes, quest objects, profession supplies and consumables remain outside rebudgeting.
  Finish chest/reference-loot and scripted-reward ownership before finalizing the manifest.
- Nineteen local creature templates also have spawns on other maps. Shared templates include instance
  helpers and holiday NPCs. A continent-wide or blanket template update cannot preserve excluded content.
- Enabled outdoor scaling currently supplies health `1.17 + 0.013 * level` and damage
  `2.16 + 0.013 * level`: factors 1.95 and 2.94 at level 60. Final zone budgets must include these once.
  Existing context/map scaling lacks a zone-index budget. Extend or integrate its world path with a
  zone-specific definition; do not override all of map 530.
- Native quest/drop item scaling and equipped-NPC bonus equipment drops are enabled in configuration.
  Their player-choice conditions and final item-level ownership must be checked in implementation so
  converted rewards remain within the chosen band without changing these systems globally.
- Source-stat estimates put Bonestripper Buzzard at about 8.4–8.8k HP and Bonechewer Evoker at about
  6.7–7.0k HP at their existing 58–59 levels, after the configured world health factor. At level 60 with
  unchanged modifiers these would be about 10.6k and 8.5k, far below the ten-second goal. These are estimates,
  not observed in-game pools, and exclude script or aura changes.

Proposed targets for review, not applied values:

| Encounter role | Level | Effective HP proposal | Pacing basis |
|---|---:|---:|---|
| Ordinary quest enemy | 60 | About 100k | Ten seconds at 10k effective sustained solo DPS. |
| Solo rare | Up to 63 | About 300k | About thirty seconds before mechanics and mitigation differences. |
| Five-player elite | Up to 63 | About 1M | About 33 seconds with three damage dealers each doing 10k. |
| Arazzius | 63 | About 1.8M | About sixty seconds under the same three-DPS assumption. |
| Fel Reaver | 63 | About 2.4M | About eighty seconds; preserve dangerous outdoor identity. |
| Doom Lord Kazzak | 63 | About 3.6M | About two minutes, subject to a separate five-player mechanic review. |

The five-player estimates assume three DPS, one tank and one healer; tank damage, healing effects, movement
and uptime are not yet modeled. Kazzak is currently a level-73 scripted outdoor raid boss. Its three-minute
berserk, Mark of Kazzak, Twisted Reflection and area damage need explicit inspection before accepting the
five-player proposal. Do not blindly scale that encounter's template damage modifier of 65.

For ordinary incoming damage, propose roughly 20–30% of the reference player's health lost over a ten-second
single-target fight after mitigation, without defensive cooldowns or healing. Several attackers then become
threatening. Derive actual melee/spell budgets from measured player defenses and validate caster pressure.
This percentage is a proposed interpretation of comfortable combat, not an owner-supplied value.

Propose ilvls 82–84 for ordinary quest equipment and common zone-specific equipment drops, 85–86 for chain
rewards and rarer equipment, and 87–89 for group finales and outdoor bosses. Preserve quality distinctions
and budget each slot/role independently. Existing Bladefist's Breadth is already ilvl 88; Normal Frostfire
armor is 88 and Nathrezim Mindblade is 92, so late rewards can compete with entry gear without exceeding
Karazhan's stronger weapons. Individual effects still need review rather than an item-level ratio alone.

At the initial audit stage no SQL, C++ or live data had changed. The conversion below is now installed live as a beta. Remaining qualification includes exact hostile and
summon ownership, all active quest paths, chest and shared-world-drop policies, spell/proc budgets, real
reward delivery, and isolated tests of scaling, damage, quests, repeated application and instance exclusion.

## Implementation candidate

The first pass has scoped runtime budgets for 128 combat templates, level-60 gates for 215 outdoor quests,
and in-place budgets for 1,239 uncommon-or-better equipment items from quests, rare drops, Kazzak, shared outdoor loot, chests and vendors. Existing disabled quests, dungeon
and raid quests, profession rewards and global bot behavior remain outside these changes. Native item scaling
must defer to the fixed equipment budgets, including their PvE/PvP Power values. Three obsolete class-specific
relic effects use role stats instead; Charm of Alacrity has a separate 120-dodge, ten-second effect.

Use [the pre-conversion baseline](evidence/hellfire-preconversion.json) when retuning this zone; do not apply
ratios to already-converted live stats. The initial five migrations under `data/sql/updates/pending_db_world/` are activated and applied live.
Migration 15 supplies the follow-up ordinary-enemy health budgets.
The SQL fixture harnesses explicitly support both draft and activated filenames.

The owner explicitly chose Hellfire budgets for shared items as well. Existing item IDs are retained, so these
stats also affect copies obtained outside Hellfire, including instance drops. Instance creatures, quests and
loot membership remain unchanged. Consumables, profession items and grey equipment remain excluded.

Of the equipment manifest, 749 items use fixed random properties and 93 use random suffixes. The fifth
migration supplies per-item loot pools and mappings to existing client-known affixes with the same name and
stat role. Existing copies normalize on inventory load or acquisition; canonical mappings point to themselves
so relogging cannot compound the adjustment. Suffix budgets use the converted item level. Preserve previously
issued canonical affixes as aliases if regenerating mappings for a later retune.

Build, unit, policy, SQL replay and installed-DBC affix checks pass. Native worldserver scenarios for outdoor
budgets, quest summons, dungeon exclusion and existing-copy equipment remain pending. Verify those, representative damage, actual
quest/reward delivery and five-player Kazzak mechanics before deployment. A build or SQL fixture pass is not
live combat or quest acceptance.

## Live ordinary-enemy health revision

The owner approved a 10x multiplier over each ordinary creature's original health recalculated at level 60.
Use the preserved original expansion-specific creature base health and HealthModifier, not the installed
100,000-HP budget. Include the existing world-health factor once: at level 60 it is 1.95.
Compute `10 * floor(1.95 * ceil(base_health_at_60 * original_health_modifier))`.
Keep the calculated integer HP; do not round to thousands or impose a common 100k pool. This preserves
variation between creature templates; it does not add random HP rolls to identical spawns.

The follow-up migration updates 103 ordinary entries. Elite, rare, boss and special-purpose budgets,
including the 10k Blistering Oozeling, remain unchanged. Damage and level budgets remain unchanged.
Examples: Bonestripper Buzzard 106,410; Bonechewer Evoker 85,150; Deranged Helboar 134,000;
Shattered Hand Grunt 97,090. The preserved baseline includes original class-level stats and all calculation
inputs. Reapply the follow-up after the initial migration; never modify already-applied migration hashes.
A restart is required because the runtime zone budgets load at startup and are pinned to creature instances.

## Hellfire-specific equipment scope and ilvl-63 revision

The owner superseded the broad shared-item policy: only Hellfire-specific equipment is converted.
The explicit manifest contains 196 items: 126 outdoor quest rewards, 12 named rare-drop items, 10 Kazzak
items, and 48 Honor Hold/Thrallmar or Hellfire PvP vendor items. Generic world drops, chest-reference
world pools and broadly shared gear are excluded, including Six Demon Bag, Outlander's Girdle and Fireheart
Girdle. The follow-up restores the original template fields for 1,043 items changed by the earlier beta.

The reward center is 63 and the allowed band is 59–66. Ordinary green rewards target 60, blue rewards 63,
group rewards and epics 65, and Kazzak items 66. Character requirements remain at most 60. Recalculate from
preserved original stats, never multiply previously rebudgeted stats. Armor, weapon damage, ratings,
resistances, sockets, fixed/random affixes and Power values use the new budget. Creature HP/damage are unchanged.

The owner delegates numeric proc/on-use tuning: original magnitude times target item level divided by original
item level. Preserve durations, cooldowns and activation chances. Treat percentage and utility effects according
to their mechanics. Use isolated copies for item effects shared with unrelated content. Nine flat effects receive
new spell records; no Six Demon Bag script or effect changes are included. Existing role-neutral relic
replacements follow their previously established role budget rather than resurrecting obsolete class abilities.

Migrations 16–18 apply the narrower gear budgets, fixed-affix mappings and scaled effects. Removed items no
longer belong to fixed zone scaling. Retain cleanup-only affix mappings for older owned copies; they restore a
valid original-pool affix of the same name/stat family. Original exact rolls cannot always be reconstructed
because the first conversion merged some rolls. Prefer an already valid original roll, otherwise the nearest
original-pool equivalent. Canonical mappings must remain idempotent. Allow cleanup mappings independently of
fixed equipment ownership, and test an excluded shared item on relog.
