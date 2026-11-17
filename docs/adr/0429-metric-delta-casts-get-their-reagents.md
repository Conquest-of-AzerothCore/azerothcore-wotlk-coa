# 0429. Metric delta casts get their reagents

- Status: accepted
- Date: 2026-11-13

## Context

- Create Frozen Reliquary 803777 needs Reagent[0] 37201. Its `item_count` entry read 0 items: the cast failed without
  the reagent (pair b4-1, B3 side b).
- B2 side a added reagents to `metric_delta` casts in ADR 0361 (5750261c26 on `feat/coa-necromancer-conformance`),
  in one commit with a caster strike and a long-wait timeout. That commit does not apply here: its strike builds on
  fields this branch lacks (`helper_casts`), and the timeout is already here (ADR 0427).

## Decision

- Port the reagent part of ADR 0361 only: before every `metric_delta` trigger cast and setup cast, the caster gets each
  `Reagent[i]` of the cast spell in its `ReagentCount[i]` (`reagent_steps`, the same function as ADR 0361).
- A spell without reagents adds no step: `generate --class 19` and `--stack` are byte-identical (2460 and 40
  scenarios).

## Consequences

- `MetricDeltaReagentTests` (test_behaviours.py) checks that 803777's cast follows an `add_item` of 37201 and that a
  cast without reagents adds none. Dropping the call is the mutant that the first test catches.
- The integrator keeps one `reagent_steps` when it merges this branch with ADR 0361.
