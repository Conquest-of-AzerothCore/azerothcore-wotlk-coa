# 0584. A distance read is a state read

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0131, ADR 0539, ADR 0553

## Context

`distance_2d` (`run.py` `METRICS`, the 2D distance between two scenario actors) had no class in
`coverage.METRIC_EVIDENCE`, so `compare` and the coverage refused any `behaviour_metric_delta` entry that reads it
(`test_coverage` `EvidenceTablesTest`). Necromancer claim 81.0, Command: Hook 504316 "hook an enemy to their
location", needs it: the dummy is placed 25 yd from the caster (`dummy_distance`, ADR 0539) and its distance to the
caster is read after the Command, 25 without an Abomination and 3.5 with one in the c4 pilot and pair.

## Options

1. `event`: every `distance_2d` delta counts as behaviour.
2. `state`, with promise words: a distance is a position read like `nearest_creature_distance`; it counts as
   behaviour only where the clause promises a position change and the contrast is learned or own-cast (ADR 0553).

## Decision

Option 2. `distance_2d` is `state`; `STATE_PROMISES['distance_2d']` is `location|hook\w*|pull\w*`. A distance read in
a `condition` contrast (an Abomination present or not, the Command cast in both phases) stays data.

## Consequences

- A metric_delta entry reading `distance_2d` is judged and counted; the 81.0 `hook_pull` entry returns as a data
  read until its contrast is learned or own-cast.
- `metric_delta_contrast` reads `METRIC_EVIDENCE`: a `distance_2d` entry whose setup casts are all the spell's own
  cast now gets the `own_cast` contrast. No such entry existed before (`generate --class 19`, `--stack` and the
  Templar fixtures are unchanged).
