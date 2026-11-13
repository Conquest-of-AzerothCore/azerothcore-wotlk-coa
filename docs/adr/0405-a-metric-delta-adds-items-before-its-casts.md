# 0405. A metric delta adds items before its casts

- Status: accepted
- Date: 2026-11-13

## Context

Create Bone Reliquary 803771 "Create $s1 Bone Reliquaries" consumes one reagent, 37201, and creates five of item 11521.
A `metric_delta` had no step that puts a reagent in the caster's bags, and the harness's `item_count` read had no
evidence class in `coverage.METRIC_EVIDENCE`.

## Decision

- `metric_delta` takes `items` (`[item, count]` pairs): an `add_item` of each right before every cast of the trigger
  spell, in both phases.
- `item_count` is a state read (the caster's bags), promised by a clause that names a creation (`creat\w*`).

## Consequences

- Entries without `items` generate as before: Templar `generate --class 19` and `--stack` are byte-identical.
- Create Bone Reliquary reads 0 items without a cast and 5 after one.
