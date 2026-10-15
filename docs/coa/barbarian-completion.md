# Barbarian source completion — 2026-09-08

This package addresses the 73 findings in the Barbarian class audit. It builds on
the [Guardian reconstruction](guardian-completion.md), including its shared raid
groups and spell replacement API. Source completion is distinct from linked-build,
deployment and gameplay acceptance.

## Evidence and reconstruction choices

The starting contracts are the active client descriptions, effective installed DBC
records and the dated audit, followed by the archived Ascension changelog. Hidden
helpers can describe retired mechanics. They do not override the active description.

- Barbarian class audit dated 2026-09-07.
- Effective server Spell.dbc SHA-256:
  `7651A1FC8C13640268F8E316917379AECB234F8AD5B52CC9801C0A0D68A16FE7`.
- Archived Ascension changelog records 70978 and 70980, dated
  2026-08-13, specify the 2.7-second Ancestral Strike baseline and the Whirling
  Assault internal cooldown following Barbaric Whirl's actual cooldown. Record
  54404 confirms Impaling Spear's 15% RAP endpoint term. Public primary source:
  <https://ascension.gg/en/changelog/4>.

The following values are explicit local choices where the recovered evidence does
not give a complete formula or event policy. They are not measured official output.

| Mechanic | Local implementation |
| --- | --- |
| Power Tosser | Add 20% current Agility to Throw Weapon's flat effect, including the Rapid Throw damage helper. |
| Ancestral Trauma | Add 30% current Strength to Ancestral Strike and Crush's flat term. |
| Brutal Form | Add 10% current Agility per Born in Blood healing tick. A 25% faster rate means 1,000 / 1.25 = 800 ms; retain periodic critical healing. |
| Ale of the God-King | Preserve the selected rank's helper base and add 20% of the original Barbarian caster's melee AP. An extra ally receives that same rank base. |
| Impaling Spear | A 1.5-yard frontal line plus each target's combat reach, ordered by distance. Each preceding successful damage selection reduces damage by 10 percentage points, with a 10% floor. Misses and immune selections do not count. |
| Impaling endpoint | Snapshot the farthest selected target's position, or the forward radius endpoint when empty. Shatter there after the cast. This is not a simulated projectile collision trace. |
| Barbaric Whirl | A successful damaging parent hit dispatches an independent native off-hand hit if an intact off-hand weapon is equipped. Both use the parent percentage; the parent's flat rank term is applied once, on the main hand. |
| Whirling Assault | Count distinct successful damaging parent targets. Three reset Whirl once. The internal cooldown equals the native remaining cooldown at that hit, including cooldown reductions. |
| Rancor | Two immediate native extra auto attacks against the current living melee victim per distinct damaging Brutal Swing target. Triggered parent casts do not recurse. |
| Damage conversions | Headlopper 30%, Shards 100%, Frostbite 30% and Legacy 40% use resolved event damage. DoTs carry the same caster's unpaid ticks into a fresh full duration. Integer division rounds down. |
| Mitigation of conversions | Do not add AP/SP, caster modifiers, armor or critical multipliers again. Ordinary immunity, absorption, resistance and PvP resilience remain native. |
| Sustaining Combat | Use 10% of resolved melee damage for self healing; the selected next Ancestral Strike receives the 50% modifier once. |
| Ancestor healing | Transfer 30% of effective healing taken, excluding overhealing, only to the living owned Guardian pet with native entry 51265. |
| Outrage / Ramhorn | Critical hits add 1 second to Outrage; melee autos add 2 seconds to Ramhorn. The total lifetime budget is 10/20 seconds for Outrage and 15 seconds for Ramhorn, not a repeatedly refillable remaining-time cap. Reapplication starts a fresh budget. |
| Mak'Gora | Each Barbarian challenges at most one enemy at a time; a new eligible critical hit removes that caster's old challenge. Its helper adds 100% melee AP once. |
| Rage of the North | Choose the nearest living friendly party/raid player within 30 yards and line of sight. |
| Berserker | One 20%-base roll per successful ranged spell instance, with the native 2-point chance stack applied afterward; exclude ranged autos and its own bonus throw. Separate Rapid Throw pulses are separate spell instances. |

## Spell and event ownership

The #88 follow-up connects Might of Utgarde to Ancestral Combat's existing proc.
With the talent and a living owned Ancestor, its native helper makes the Ancestor
use Ancestral Whirl and heals it for 5% of maximum health. The extra attack and
Fill Level remain separate existing effects. `apps/coa-tests/barbarian_passives/run.py`
checks the production callback, ownership, missing/dead pets and recursion guards.

The new scripts use class 12 and family 18 checks. Spears include all four families:
Barbed, Maiming, Headhunter's and Impaling. Frothing Savage additionally includes
the real Berserker Axe damage helper 806960; the old private mask incorrectly
included Throw Weapon instead. Spear Thrower's existing reset also gains Maiming.

Cast events run after native validation, cost and cooldown handling. Decapitate
spends half the remaining Energy, capped at the rank's 55-point metadata, only
after a successful native target selection. Its extra damage applies to creatures
not controlled by players. Jawbreaker refunds half its actual cost only after a
successful interrupt. Native one-shot bookkeeping prevents repeated spending or
refunds on additional effects or targets.

You Want Axe restores three native category-60 charges. Its three selected cost
modifiers and Sustaining Combat's one selected damage modifier use native spellmod
charge ownership, without a second broad damage proc consuming them.

Gurubashi Technique grants Rapid Throw as a temporary spell and replaces active
Throw Weapon ranks while the proc is present. Expiry restores the original buttons.
The temporary grant survives proc consumption during the channel and is removed
when the talent is removed. Permanent ownership is preserved. The existing shared
Guardian replacement API supplies server-side cast routing and client packets.

Spite fires at 200/400/600 ms and jumps backward only after its third shot. Rapid
Throw retains the native initial-period attribute and fires at 0/750/1,500 ms.
Their scripts cap execution at three shots and stop for invalid/dead targets.

Only one of the five baseline Spirits remains active. Raging Spirits' Energy
grant occurs when Unbridled Rage is applied; its free Spirit costs exist only while
both Unbridled Rage and the talent are active. Respeccing recalculates that modifier.

Owner-specific helpers and duration extensions use caster ownership. Guardian pet
selection checks entry, owner GUID and life state; it does not select arbitrary
charms or nearby summons. Ramhorn regeneration, Guts Splatter, Berserker chance and
Storm of Steel damage stacks are cleaned up with their owning auras.

## Shared changes

- Thane uses the existing item-contribution armor path for its intact shield's
  contribution, preserving ordinary armor modifiers and Guardian's existing cases.
- The shared private ignore-armor aura honors a nonempty ability mask, including
  caster-specific target debuffs. Empty masks retain their ordinary all-attack use.
  Guts Splatter therefore affects the caster's abilities, not ordinary auto attacks.
- Defiance supplies a live damage-taken multiplier of `0.2 + 0.5 * healthFraction`
  in native spell/periodic damage and melee damage calculations. At full health this
  is 30% reduction; it approaches 80% at zero health. It does not alter healing ticks.
- Spell instances store actual extra Energy spent. The event mask is mutable
  bookkeeping so a native read-only proc callback can claim an event once per cast.
- Frozen Blades and Uniting Voice join Guardian completion's corresponding raid
  critical-chance and haste groups, preserving the other members and stack rules.

## Data and installation boundary

The [Barbarian migration](../../data/sql/updates/pending_db_world/rev_20260908_06_barbarian_completion.sql)
contains 45 proc rows, 124 exact script bindings, 11 coefficient rows and two
additions to existing raid groups. Applied Barbarian damage SQL and Guardian
01/02 are immutable. Guardian completion 05 supplies the shared group definitions
required by 06.

Hodir's Wrath uses the stated 120% AP. Maximum Carnage's real damage helper uses
30% AP per pulse, taking the active talent formula rather than its stale hidden
25% text; per-pulse allocation is a local reconstruction. Shatter's 15% RAP and
Puncture's 5.5% RAP per tick are computed on the actual effects. Explicit zero
SQL coefficients prevent unintended stock SP terms or duplicate scaling.

New sources are collected by the existing module source glob. Installation must
include a coherent Guardian/Barbarian source and migration package, using the
normal backup/updater workflow and the Guardian gameobject conflict check.
See the [release history](local-release-state.md) for later integration.

The source audit cannot establish combat feel, packet/UI rendering, pathfinding,
interrupt interactions, group aura behavior, reconnects or full official parity.
Those require gameplay acceptance after an explicitly requested build/install.
