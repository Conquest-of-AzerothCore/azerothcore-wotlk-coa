# 1028. Ratio-only arms, single-landing durations, no-cast dispel arms and an avoided-swing script hit

- Status: proposed (provisional number; renumbered at merge, guide 14.4)
- Date: 2026-11-22
- Related: [ADR 0582](0582-metric-delta-options-are-modules.md) (option modules),
  [ADR 0120](0120-two-proof-statuses-computed-by-clause-coverage.md) (evidence classes),
  [ADR 0160](0160-judge-a-script-cast-hit-against-the-tooltip-that-states-it.md) (script hits),
  [ADR 0900](0900-a-proc-rate-can-count-avoided-swings.md) (avoided trigger), [ADR 1027](1027-opt-in-fixture-fields-a-cooldown-tick-cut-kind-and-ground-effect-reach-reads.md).
- Decided by: mentor D-163 (Sun Cleric tool group 6) and D-166 (script hit avoidance), controller approval of each
  design note.

## Context

Sun Cleric claims state an amount as a percent of another amount of the same phase (301011 "heals ... for $s1% of
the amount it heals you", 800612 "$s1% of the damage dealt", 803913 "mana equal to $807451s1% of the damage dealt"),
a stun reduction that the three-landing duration scenario reads on a diminished re-application (704581), and a
disease count that needs a control without the cast (504848). The absolute totals of the first three are not stated
by any data, and the mana is truncated per strike.

## Options

- A new `total_ratio` kind (design g6 need 1). Rejected: the `metric_delta` option `ally_arm` already reads arms after
  each main reading and judges a ratio of their deltas; it lacked only caster-only arms, arms without an absolute
  expectation, a truncation band and a summed denominator.
- Change the defaults of `duration_ratio`, `dispel_count` and `script_hit`. Rejected: Templar and Witch Hunter use the
  first two, and their scenarios would move.
- Opt-in fields, absent by default.

## Decision

- `ally_arm`: `allies: 0` (no ally player, no group step); ratio-only arms (`count_metric` in place of
  `before_expected`, `expected`, `tolerance`), judged only through a ratio, which is unmeasured unless every
  ratio-only arm's count moved; a ratio's `denominator` may be a list of ratio-only arms, summed; `floor_count`
  widens only the low end by the counted events over the denominator (one unit per truncated event), with a
  tolerance below 10% of `expected` and the ratio unmeasured when the widened band no longer excludes 10% below.
- `duration_ratio`: `attempts` (1 to 3, default 3) and `margin_ms` (the judge's margin becomes `margin_ms` plus the
  tick overshoot; unmeasured unless below 10% of the expected delta).
- `dispel_count` arms: `learns` (learned before the arm, unlearned after) and `cast: false` (a no-cast control that
  expects no removal).
- `script_hit`: `caster_avoidance {dodge, parry}` set before each trial with a hostile melee striker in place of
  `strike_spell`.

## Consequences

- Witch Hunter 15, Templar 19 (with `--stack`) and Necromancer 23 regenerate byte-identical and their coverage audits
  are identical before and after.
- An unmeasured ratio is not behaviour evidence (tested through `clause_coverage`).
- 807507 c408 and 807873 c415 stay tool gaps: 10% of their expected 381.6 ms delta is below any tick margin; an exact
  read needs a player aura maximum-duration harness read, not built here.
