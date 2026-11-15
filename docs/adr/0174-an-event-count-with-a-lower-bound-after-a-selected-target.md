# 0174. An event count with a lower bound after a selected target

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0058 (metric_delta setup fields), ADR 0170

## Context

Testament of Hope 1397742, "copies of yourself that charge at a nearby enemy and aid you in combat" (claim 430):
the review found no label for the combat half. The copies attack the owner's selected enemy, so a phase must select
the dummy, and the number of copy hits in a window is not a fixed value, while `metric_delta` judges exact equality.

## Options

1. A wide tolerance around a guessed count. It would also widen the before read, the control.
2. A selection of the dummy in both phases and a lower bound on the after read only.

## Decision

Option 2. `metric_delta` `select_dummy` selects the dummy at the start of both phases (and adds the fixture);
`after_at_least` judges the after read as at least that value. The before read stays exact.

## Consequences

- Without the fields every scenario regenerates byte-identical.
- Seeded tests: 0 before and 6 or 1 after is ok; 0 after, or 1 before, alerts.
