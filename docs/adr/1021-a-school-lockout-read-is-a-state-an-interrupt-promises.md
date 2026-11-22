# 1021. A school lockout read is a state an interrupt promises

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22
- Builds on: [ADR 0403](0403-a-phase-power-and-a-counted-primary.md),
  [ADR 0426](0426-a-dummy-cast-before-the-trigger.md); guide sections 9.7 and 14.5

## Context

Luminary Mendicant 547214 states "and causes Horusath Blast to interrupt the target for $547217d" (547217
DurationIndex 27, 3000 ms). Horusath Blast 572801 is a missile (Speed 20, at least 5 yd of travel,
`Spell.cpp:2474-2476`), so the lockout starts 250 ms after the cast. The `school_lockout` kind times its arms from
the cast and alerted in both runs; two `metric_delta` entries reading the harness metric `school_prohibited`
3000 ms and 3475 ms after the cast passed in both runs (pair 20261122-054957 / 20261122-055034). The audit could not
class them: `school_prohibited` had no row in `coverage.METRIC_EVIDENCE`, so `metric_class` raised and the
cross-class guard of `test_coverage.py` failed.

## Options

1. A `METRIC_EVIDENCE` row of a `metric_delta` option module: no option is involved, the entries are plain
   `metric_delta` reads.
2. A built-in `STATE` row with a promise word in `STATE_PROMISES`, like `casting` (ADR 0403).
3. An `EVENT` row: a lockout read is the creature's state at an instant, not a logged event.

## Decision

Option 2: `school_prohibited` is a `STATE` metric whose promise words are `interrupt\w*`, `lock(?:s|ed|ing)? out`
and `lockout`. A learned-contrast `metric_delta` read counts as behaviour only where the clause, its row or its
promise source names an interrupt or a lockout; elsewhere it stays data.

## Consequences

- Judged events, attribution and tolerances are unchanged; only the evidence class of a `school_prohibited`
  `metric_delta` verdict is new.
- The `school_lockout` kind (Witch Hunter 802139, Templar 806153) is judged by `behaviour_expiry`, whose evidence is
  `BEHAVIOUR` and is returned before any metric lookup: its coverage does not move. Templar, Necromancer and Witch
  Hunter generate byte-identical output.
- Unit tests seed the row as a readback (the claim drops to data), an unlearned contrast and an unpromised clause,
  and remove the row (the cross-class guard names `sun_cleric.json`).
