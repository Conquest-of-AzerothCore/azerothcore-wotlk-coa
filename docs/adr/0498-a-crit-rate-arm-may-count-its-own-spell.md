# 0498. A crit-rate arm may count its own spell

- Status: accepted
- Date: 2026-11-13

## Context

Fix FN-c4-1 (ADR 0442) lets Flesh to Worms ticks critically strike. Its regression forces the spell crit chance to
100%, so it cannot tell "ticks crit at the caster's spell crit chance" from "ticks always crit". `crit_rate` (ADR 0173)
counts the landed hits of one `observe_spell` in both arms and judges the difference of their critical shares, so it
cannot compare a damage over time with a direct spell. `spell_damage_count` already counts periodic damage ticks
(SMSG_PERIODICAURALOG) with their critical flag.

## Options

1. A new judge of an absolute tick crit share against a read spell crit chance: it needs a crit chance read per school
   and its own band rule.
2. Per-arm overrides in `crit_rate`: each arm may count its own spell and wait after each cast, and the existing
   difference judge runs at `expected` 0 points. Chosen.

## Decision

- `behaviours.crit_rate_arm_overrides` takes `observe_spell` and `wait_ms` (0 to 30000) out of the `control` and
  `treatment` objects of a `crit_rate` entry. `crit_rate_scenario` casts and counts each arm's spell, learns it once,
  and sleeps `wait_ms` after each cast. Two arms with equal auras and casts are accepted when they count different
  spells.
- `model['observed']` and a contract clause name the arms' spells only when they differ. Entries without overrides
  generate the same scenarios as before.

## Consequences

- An entry such as Flesh to Worms 500338 (treatment, `wait_ms` 3000) against Lichfrost 801722 (control) at `expected`
  0 alerts on "always crits" at 300 casts per arm. An interval inside the 2-point band needs the larger counts that the
  verdict's `hits_needed_per_arm` states (G-20).
- The two arms must share the caster's crit chance: a school-specific crit modifier on one spell makes the comparison
  invalid. The entry's expected source states that none applies.
- Templar `generate --class 19`, `--stack` and Necromancer `--class 23` are byte-identical to bf83cf15b1.
- Tests: `CritRateTests` (test_behaviours.py).
