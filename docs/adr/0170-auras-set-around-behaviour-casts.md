# 0170. Auras set around behaviour casts

- Status: accepted
- Date: 2026-11-11
- Extends: ADR 0058 (metric_delta setup fields), ADR 0153 (taken_hit)

## Context

Six Templar claims of R1 had a behaviour route that the existing kinds could not express:

- Crusader's Brand 300513, "preventing them from ... fleeing, or increasing their movement speed above normal
  movement speed": the measured unit needs a second aura (a fear, a speed buff) beside the brand.
- Libram of Consecration 803893, "and 4 nearby enemies": the Libram must be held when a damaging ability lands.
- Devotion of Khaz'goroth 560096, "Does not stack with similar effects.": `group_stack_cap` read attack_time_ms, a
  state read that stays data conformant, and took its percent from the learned spell, which only casts 567572.
- Testament of Hope 1397742, "each copy reduces all damage you take by": the copies must be summoned once, not on
  every trial.
- Claim 91 (Norgannon's Wrath pierces absorbs): its two single casts could crit, which made the check flaky (ok in
  one batch, alert at 1.5 in another, same scenario bytes).

## Options

1. One new kind per claim. More code and more judges for the same readings.
2. Optional fields on the existing kinds that set auras (or make one cast) at fixed points of their existing steps,
   judged by the existing judges, with one judge change: an inverse relation for an interval metric.

## Decision

Option 2. `metric_delta` `phase_auras` / `after_auras`, `fixed_count` `auras`, `absorb_pierce_ratio` `target_auras`,
`group_stack_cap` `value_spell` / `swing_ms` / `marker_spell` / `tolerance` (judge: `relation: inverse` divides the
baseline by each factor), `taken_hit` arm `opening_casts`. Without the fields every scenario regenerates
byte-identical (1440 class scenarios and 40 stack scenarios, compared before and after).

## Consequences

- Seeded tests in test_behaviours.py cover the step placement of each field, and judge the seeded readings: a summed
  haste interval (2500 / 1.21) and an ignored own aura alert, a breadth of three where four are stated alerts, an
  uncapped speed alerts.
- The Blessed Resilience guard changes claim 91's scenario; its stored verdicts are replaced by the R1 pair.
