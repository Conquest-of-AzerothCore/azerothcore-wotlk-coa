# 0200. Amount match

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0125 (hit ratios)

## Context

Silverhand Incantation 801465: "...deal ${$m1+$ppl1+$AP*2} Holy damage to all nearby enemies and heal nearby allies
for the same amount." The review of side b (lean/r1-review-b.md, I2) found that the `ally_heal` hit ratio proves the
heal follows 2 x AP, not that it equals the damage: a heal of half the damage reads the same ratio. No kind compared
two amounts of one cast.

## Options

1. A ratio of the heal on the ally to the damage on the dummy across two scenarios. Two scenarios do not share a cast.
2. A kind that casts once per trial and reads both amounts after each cast.

## Decision

Option 2: `amount_match`, check `behaviour_amount_match`, behaviour evidence. Each trial sets the entry's `auras` on the
caster, casts `cast_spell` at `cast_target`, waits `wait_ms` and reads the non-critical totals and counts of two sides
(`first`, `second`: `spell_damage_total` or `spell_heal_total` of a spell on the dummy, the ally or the caster). In
every trial with an event on both sides, the per-event amounts must be equal within `tolerance` (1 point of engine
rounding by default); fewer than half the trials with both is `unmeasured`. `group` groups the ally first.

## Consequences

- Silverhand Incantation reads 740 damage on the dummy and 740 heal on the ally per cast in 20 of 20 trials.
- Seeded tests: equal and one point apart pass; half the heal alerts; trials with only one side are unmeasured.
