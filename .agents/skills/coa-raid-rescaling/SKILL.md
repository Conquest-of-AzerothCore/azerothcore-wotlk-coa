---
name: coa-raid-rescaling
description: Plan or implement a fixed level-60 raid conversion for the Conquest of Azeroth realm, with custom release order, attunement, flex combat, tier loot, and reward integrations.
---

# CoA raid rescaling

Use the target checkout's AGENTS.md and coa-development skill for repo procedures. For
Karazhan, load [the worked example](references/karazhan.md); for Naxxramas, load
[its conversion reference](references/naxxramas.md). Treat examples as per-raid inputs. Preserve decisions the owner already made.

## Collect inputs

- Source raid, placement in release order, character cap, and the adjacent gear benchmarks.
- Entry and attunement requirements, including the original chain, prerequisite encounter,
  qualifying modes, character or account scope, treatment of older clears, bot exemptions,
  and any physical key or other entrance item.
- Raid sizes, flex policy and bot weighting, difficulty modes, and any mechanics to preserve.
- Gear progression across bosses and modes, whether existing item IDs may be rebalanced in
  place, and any special items, tier sets, or currencies.
- Launch Scope, including any reputation faction the owner names for conversion. Record
  token exchanges, Registrar resets, companion content, and which alternate reward
  systems should expose the new gear and when.
- Intended clear times and difficulty curve, with playtest roster sizes, human/bot mix,
  gear benchmarks, and any existing logs. Include the owner’s usual roster if it differs
  from the minimum-size tuning roster.

Reuse the realm defaults when requested. Derive exact stat budgets from effective data.
For exploration, deliver the audit and proposal. Implementation and deployment follow
the scope the owner authorized.

## Audit and propose

1. Trace release and entry gates, position in the current progression, prerequisites, and
   lockouts using the installed database and running code. Check portals and group entry.
   Trace the physical door lock and the map-entry check separately. Walk the entire quest
   path with the target character cap and available content. When the owner chooses a
   replacement quest, verify that the real encounter completes its objective in the
   supported modes and that turn-in grants the item the door accepts.
   Keep stable raid identities when inserting tiers. Audit saved overrides and all consumers
   before changing stage numbers.
2. Inventory native encounters, NPC stats, spell effects, difficulty mappings, loot references,
   reputation, and quest and vendor rewards. Compare gear by slot, role, encounter position,
   and difficulty. Include weapon damage and speed, armor, stats, sockets and gems, procs,
   and set bonuses. Trace shared item IDs across reward sources and existing copies. Rebalance
   in place where authorized. Show the benchmarks supporting the proposed budgets.
3. Use fixed encounter levels and tune HP, melee, spell effects, adds, and timers for the
   intended roster. Preserve each mechanic's purpose and trace the interaction between
   existing flex, bot weighting, and other scaling before adding any tuning. Inventory
   fixed-health trash and combat adds alongside flex bosses. For multi-phase fights,
   record shared health, resets, and inherited health separately from full phase pools.
   Compare the opener, midpoint, and final boss with adjacent and earlier tiers at the
   same difficulty and effective roster size. Show estimated clear time and tank
   pressure using available raid DPS, swing intervals, and ability damage.
   Before applying a raid-wide ratio, show pre-conversion, current, and proposed HP for
   representative trash and bosses at the flex floor and a full roster, including the
   owner’s actual bot mix. Derive fixed-health mob changes from their effective HP after
   other scaling. Apply map-specific tuning once, preserve unrelated maps and player
   summons, and inspect special health mechanics before scaling scripted units.
4. Trace the full reward path, including token denomination by difficulty, vendor pagination,
   and any cache, reputation, or reset interactions in scope. For Callboard, check progress-bar
   and generic cache paths separately. Apply the Callboard `PreviousStageOnly` cap to both
   when enabled. For Manastorm, check depth eligibility, item levels, and release-stage fallback.
5. Audit reputation rewards only for factions named in Launch Scope. Follow vendor and quest
   rewards through crafted outputs, Bloodforged copies, ammunition, and enchantments where
   present. Check character level, profession rank, materials, and separate spell or
   enchantment level requirements.

## Bring decisions back to the owner

- Show blocked attunement steps, tier pieces sourced from unopened raids, and any proposed
  changes to where those rewards come from.
- Flag meaningful cross-difficulty upgrades with concrete slot and role comparisons.
- Ask if preserving an encounter across the flex range requires a material redesign. Use the
  original encounters as evidence when estimating routine difficulty, including optional bosses.
- Ask about unresolved alternate reward eligibility or reset interactions that materially
  change the economy. Honor settled choices, including realm-phase-only Callboard eligibility
  when specified.

## Implement and verify

For each original WoW class-specific set bonus, first look for a class-neutral mechanic
that preserves its purpose, such as all bleed periodic damage. Where one is unavailable,
use a role-based bonus or the closest supported CoA ability if the effect depends on a
specific ability to work. For standalone item effects, choose the closest supported CoA
ability or a role-based replacement. Fit every replacement to the new item budget. Proceed without requesting
approval for these mappings. Include every mapping in the final before-and-after item
report, with the item or set, affected versions, original effect, replacement effect,
target class or role, and the reason for the choice.

For each new raid tier, generate and wire up a distinct raid phase at the approved
position in the progression. Add it to the release configuration and `.raidphase`
command, gate raid entry on it alongside personal attunement, and use it in all
approved phase-gated reward paths. Account for the phase in the supported range and
release-all behavior. Preserve the meaning of existing saved overrides and config
values with stable phase identifiers or an explicit migration.

Audit which requested difficulty modes and matching item tiers already exist. Reuse and
verify those that exist, and generate the missing ones. Check map mode selection, spawn
masks, encounter scripts, loot references, and instance saves for each mode. Ensure data
updates can be reapplied without compounding the rescale.

Reuse existing release, loot, flex, and vendor code. Keep raid-specific inputs and data
separate from the common implementation. Use shared transformations where the evidence
supports them and document encounter or item exceptions in the raid definition. Preserve
existing Classic progression, difficulty meanings, and saved state unless the task changes
them. Apply repository SQL authorization and deployment rules.

Verify in an isolated test environment with resources separated from production. Cover entry
before and after release, including characters without attunement and exempt playerbots
where specified. Test the entrance door as well as the transfer, accept and turn in the
quest through its NPC, and verify attunement survives relog, restart, and Registrar resets.
Check the actual instance and kill credit through normal entry. Record any access bypass
used by a test fixture. Check flex endpoints and bot weight, fixed-health trash on each
mode, combat and loot in each mode, token redemption and pages,
reputation, and reset behavior. Verify cache eligibility at the preceding, new, and next
raid phases where applicable, including both Callboard paths with `PreviousStageOnly`
enabled. Verify approved class bonuses on the intended CoA classes. Use automated checks
for configured HP, flex and bot weighting, encounter events, and repeatable damage or loot
assertions where practical. List the representative roster playtest as manual acceptance.
Have the owner or a designated tester judge clear time, tank pressure, and gear readiness
with the intended roster and, where relevant, the usual bot roster.

List client-only checks for the owner, including fresh tooltip display and vendor or item
interaction when relevant. Stale cached item data can persist after the server migration.
Record client checks as pending until the owner reports results. Save the per-raid
definition, before-and-after comparisons, decisions, and verification results for reuse.

For an authorized deployment, use the verified release candidate and its matching SQL.
The server’s configured source checkout supplies pending migrations to the startup updater.
Verify the installed binary, startup readiness, recorded migration names and hashes, and
effective rows. An applied update can still be labeled `PENDING` in that ledger.
Allow for generated CMake install scripts that retain absolute paths from the original
build directory. Use the realm’s rollback procedure for both the binary and database state.
If the owner chooses production for playtesting, record which gameplay checks remain
pending after startup.
