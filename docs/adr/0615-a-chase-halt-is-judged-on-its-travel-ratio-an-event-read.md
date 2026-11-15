# 0615. A chase halt is judged on its travel ratio, an event read

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0584, ADR 0596, ADR 0604

## Context

The `chase_halt` kind (`kinds/chase_halt.py`) reads `distance_2d` four times, but judges one number: the yards the
hooked mover covers over a stamped window divided by the yards the unhooked control covers under the same harness
move order. Its verdict stamped `distance_2d` as its metric, a state read (ADR 0584) with no learned or own-cast
contrast, so the coverage audit read Necromancer claim 81.1, Command: Hook 504316 "slowing their movement speed to a
halt", as data although the entry was ok in both runs of the counted pair 20261113-181701 / -184212.

## Options

1. Override the base `distance_2d` row from the kind module: refused, the override guard
   (`KIND_ROW_OVERRIDES`, empty) exists to keep base rows class-independent.
2. The kind stamps its own metric, `chase_travel_ratio`, registered by the kind module as `event`: the ratio is a
   movement that happened (or not) during the window against a control that moved, not a position held.

## Decision

Option 2. `chase_halt` verdicts carry `metric: chase_travel_ratio`; `kinds/chase_halt.py` declares
`METRIC_EVIDENCE = {'chase_travel_ratio': 'event'}`. `distance_2d` stays `state` and `KIND_ROW_OVERRIDES` stays empty.

## Consequences

- An ok `chase_halt` verdict is behaviour evidence; an alert or unmeasured one is not.
- Generated scenarios do not change (the metric is the expectation model's, not a read).
- Seeded tests: `kinds/test_chase_halt.py` (the event class proves the halt; without its row the audit refuses the
  verdict).
