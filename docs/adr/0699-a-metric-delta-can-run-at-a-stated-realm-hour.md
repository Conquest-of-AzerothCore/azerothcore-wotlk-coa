# 0699. A metric delta can run at a stated realm-local hour

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Evil Never Sleeps 804185 (Witch Hunter) casts Night Hunter 807198 or Day Hunter 807231 by
`AscensionRealmClock::IsNight()`. Hand-written scenarios set a top-level `hour`, which the batch runner and the
harness already honour (`batch.py`, `CoAGameplayTest.cpp` stop-case record); generated scenarios could not, so the
night and day clauses stayed data (c10-hound). Mentor decision D-158 (design D-2).

## Options

- A `metric_delta` option module `hour` that sets the scenario's top-level `hour`.
- A `MetricDeltaSpec` field: the guide keeps new options in their own module (ADR 0582).

## Decision

The option module `metric_delta_options/hour.py`: an integer hour 0-23, set on the scenario and named in the
contract and model. It adds no check; a second entry at the other hour is the control arm.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (no entry states the option).
- Witch Hunter: `804185 night_agility` (hour 0, Agility 127 -> 132) with `day_agility_control` (hour 12, 127 -> 127).
