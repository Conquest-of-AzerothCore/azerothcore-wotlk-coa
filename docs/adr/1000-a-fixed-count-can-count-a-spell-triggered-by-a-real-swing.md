# 1000. A fixed count can count a spell triggered by a real swing

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-17
- Builds on: ADR 0950

## Context

Witch Hunter part 373.0 (Flourish 805365, "causing your Flames of Sin to cleave up to $s3 additional enemies for $d")
was measured with `fixed_count` casting Flames of Sin 802850 directly at the primary (pair 20261117-144038 / -144507):
the primary was hit once and the four extras read 0. The direct cast is not triggered, so
`spell_ascension_witch_hunter_flame_damage` (it loads only for a triggered cast) adds no copied damage; the hit is the
DBC base 1, each jump takes `int32(1 x 0.95) = 0`, and a 0-damage target logs nothing. In play 802850 is cast by the
Flames of Sin aura 803422 on every landed auto attack, with 40% of the swing's damage. Mentor D-467 approved design
D-nfd-1 (category A: judging unchanged).

## Options

- An opt-in `swing_ms` on `fixed_count`: each cast step becomes the caster's own `attack` on the primary for `swing_ms`,
  then `stop_attack`; dummies, reads, the per-cast model and the judge stay as they are.
- `swing_cleave` (ADR 0950): built for a creature's cleave; it commands a pet, learns the cause between two phases and
  forbids the caster's own attack.
- A new kind: more code for a change of one step.

## Decision

The first option. `swing_ms` needs a positive time, `cast_target` the primary, and no `layout`, `swing_cleave` or
`gate`. The contract adds one sentence naming the swing route. The model and the judge are unchanged, so a window
whose swing did not trigger `target_rank` on the primary is unmeasured, as a cast that missed it.

## Consequences

- Absent by default: entries without the field generate and judge as before; Templar 19 and Necromancer 23 regenerate
  byte-identical (`snapshots.py check`).
- Seeded tests in `test_fixed_count_swing.py` (`FixedCountSwingTests`, run through `test_behaviours.py`): three extras
  on a landed swing are ok; a cap of four, no cleave or a far hit alert; a window without a primary hit is unmeasured;
  a negative window or a cast at the caster is refused; without the field the scenario casts as before and the model
  is the same.
- The swing must land for the window to be judged; the entry states how avoidance is removed (Witch Hunter: the class
  ratings).
- Witch Hunter: `805365 flourish_swing_cleave behaviour_fixed_count` and its control
  `805365 flourish_swing_cleave_control behaviour_fixed_count` (Flames of Sin from its helper 803710, no Flourish).
