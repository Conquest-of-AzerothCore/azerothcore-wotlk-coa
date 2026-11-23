# 1029. Rows for rooted and carried_aura_count; costs and brews promise their metrics

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 1008 (a module promises only its own metric)

## Context

Two harness metrics had no `coverage.METRIC_EVIDENCE` row, so entries reading them could not count: `rooted`
(`HasUnitState(UNIT_STATE_ROOT)`) for "Root yourself for 8 sec" and `carried_aura_count` (the listed auras present
on a unit) for Loa's Blessing's random empowerment. Two state reads were data only because their clause words miss the
promise: `power` is promised by `\bcost` inside `\b(?:...)\b`, which does not match "resource costs", and
`item_count` only by `creat\w*`, not "Brews". A kind or option module may not add these rows (ADR 1008).

## Decision

In `coverage.py`:

- `METRIC_EVIDENCE`: `rooted` and `carried_aura_count` are STATE;
- `STATE_PROMISES`: `rooted` is promised by `root\w*`, `carried_aura_count` by `empower\w*`, `power` by
  `\bcosts?` instead of `\bcost`, `item_count` also by `brew\w*`.

## Consequences

- Generated scenarios do not change; the guard tests (`test_every_state_metric_names_its_promise`) still hold, since
  both new metrics are state metrics with a promise.
- Audits of the finished classes can change only for verdicts on `rooted` or `carried_aura_count` and for claims with
  "costs" or "brew" words read by `power` or `item_count`.
- Witch Doctor: the held cycle 9 entries 704497 `root` and 705848 `empowerment` are merged, 501205 `empowerment` and
  `empowerment_lasts` are added; the ledger rows of clauses 142, 171 and 446 link them, and the rows of 800195
  ("resource costs") and 807056 ("Brews") lose their `no_behaviour_route`.
- Seeded tests in `test_coverage.py` for each row and promise.
