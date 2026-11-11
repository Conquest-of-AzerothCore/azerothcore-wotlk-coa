# 0135. Deterministic stat readings are judged to their rounding

- Status: accepted
- Date: 2026-11-11
- Amends: ADR 0051 (the tolerated band) and ADR 0124 (the `data_only` floor rule) for stat readings

## Context

The owner ruled on 2026-11-11 (`owner-rulings-2026-11-10.md`, "Lean package follow-up rulings", stat passives):
the 5%-or-2-points tolerance applies to random measurements (damage, healing, rates), not to deterministic stat
readings, which are judged to the rounding; where rounding cannot separate the stated value the clause stays data
conformant. The batch 1 preparation found two paths that still widened a stat reading: `banded_status` called a
reading within 5% of the expected delta `tolerated`, a conformant status, and `delta_margin` took
`max(floor, 0.5% of |expected|)`, wider than one point for an expected delta above 200 (armor +815.5, +1631).
`behaviour_group_stack_cap` used the same `max(1, 0.5%)` margin on its readings, `attack_power` among them, and the
pre-truncation `stat_exact` reading `max(0.01, 0.5%)`.

## Considered options

1. Leave the paths as they are because no current verdict uses them. Rejected: the chunk 2 brief applies the ruling
   in full, and a future stat reading would pass through them.
2. Drop the relative margin and the tolerated tier for every `passive_delta` metric. Rejected: spell modifier and
   damage-done readbacks are not stat readings, and the ruling names stats.
3. A named set of deterministic stat metrics judged to their floor, ok or alert, everywhere a stat delta is judged.
   Chosen.

## Decision

- `compare.DETERMINISTIC_STAT_METRICS`: the state metrics coverage counts as stat readings (`coverage.METRIC_EVIDENCE`
  state class without `moving` and `threat`).
- `delta_margin` returns the metric's floor for them; `delta_status` gives ok within it and alert outside it; the
  explanation states the rounding rule (`delta_margin_rule`).
- `exact_truncated_verdict` uses `FRACTIONAL_FLOOR` alone; `behaviour_group_stack_cap` takes `delta_margin` of its
  metric (unchanged for its non-stat metrics).
- `floor_only_reason` is unchanged: a reading the rounding cannot separate keeps `data_only`.

## Consequences

- A stat reading off its expected delta by more than its rounding is an alert where it was `tolerated` or `ok`.
- Seeded test: `test_compare.PassiveDeltaTest.test_seeded_stat_reading_off_by_more_than_its_rounding_is_an_alert`
  (+805 and +834 for +802 armor, both conformant under the old rule).
- The verdicts that change on the batch 1 results are listed in `lean/batch1-c2-tool.md`.
