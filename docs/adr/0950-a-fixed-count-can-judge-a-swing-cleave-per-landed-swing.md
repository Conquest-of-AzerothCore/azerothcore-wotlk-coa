# 0950. A fixed count can judge a swing cleave per landed swing

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 106.0 (Rampaging Hounds 570726, "Your Shadow Hounds melee attacks now cleave 1 additional nearby
enemy.") was tried twice with `fixed_count` (author f-m3, four runs, every 567570 count 0). The diagnosis
(`diag-106-cleave.md`, mentor D-327) found two faults in the measurement, not a server defect: the per-cast judge needs
a 567570 hit on the primary for each cast, and the cleave never strikes the swing's victim
(`AscensionWitchHunterEvents.cpp:432-443`, the first other valid enemy within 5 yd); and nothing read the hound, so a 0
could not be told from "the hound never swung". Mentor decision D-328 approved one third design (T21).

## Options

- An opt-in `swing_cleave {entry, aura, arm_wait_ms, control_ms}` on `fixed_count`: a control phase without the cause,
  the cause learned, then an arm phase; the cleave is judged as a count per landed swing of the creature.
- The per-dummy "ever hit" count: with two candidates in range the server may strike either one on different swings, so
  a correct one-per-swing cleave can read 2.
- A new kind: more code for a shape that only replaces the judge of an existing kind.

## Decision

The first option. The scenario casts `cast_spell` once at the primary, reads at the start and end of each phase the
`target_rank` `spell_damage_count` on every dummy, the creature's landed hits (`owned_creature_damage_count` with
`entry`: crit, glancing and plain swings plus spell hits whose caster resolves to `entry`; the proc's HitMask 9283
leaves out misses, dodges and parries), the damage of each of its own spells listed in the optional `creature_spells`
(`spell_damage_count` by `caster_entry`, so a spell hit that would inflate the count is visible), and
`owned_creature_count` of `entry` on the primary, with and without `aura`. The caster commands its pet to attack the
primary after the cast (the existing `attack` step with `pet`); the caster itself never attacks, since a player holding
the cause would cleave too. `pet_melee_hits` is not used: it filters `attacker.GetEntry()`, and a pet's GUID carries
its pet number in that field (`Pet.cpp:2336`, `CoAGameplayTest.cpp:4935-4936`), so it never matches the creature
entry (first run of this design: the hound on the primary, 0 read). The cause (`spell`) is learned only between the phases and may not be
in `learn`. The judge, used only for models that carry `swing_cleave`:

- landed melee hits per phase = the `owned_creature_damage_count` delta minus the deltas of the creature's own
  `creature_spells` hits (mentor D-336): the cleave 567570 and the Call landing strike 706332 are logged with the
  hound as caster (run 20261116-191718), so they count in `owned_creature_damage_count` and would halve the ratio;
- unmeasured when the creature is not on the primary, the aura is held in the control or absent in the arm, or a phase
  has no landed melee hit;
- alert when the control shows any hit, the arm shows a hit on the primary or beyond the radius, or the extra dummies'
  hits differ from `expected` times the arm's landed swings (compared exactly);
- otherwise ok; the measured value is the arm's extra hits per landed swing.

## Consequences

- Absent by default: entries without the field generate and judge as before; Templar 19 and Necromancer 23 regenerate
  byte-identical (`snapshots.py check`).
- Seeded tests in `test_behaviours.py` (`SwingCleaveTests`): one hit per swing is ok, with the creature's spell hits
  taken out; two per swing, a primary hit, a far hit, a control hit or the cleave counted as a landed hit alert; no landed swing, a wrong aura state or an absent hound is unmeasured; a learned cause
  or a malformed field is refused.
- A fully blocked swing procs the cleave but carries no damage, so the hit count misses it; the dummies carry no
  shield, so this rests on the fixture.
- Witch Hunter: `570726 rampaging_cleave behaviour_fixed_count`.
