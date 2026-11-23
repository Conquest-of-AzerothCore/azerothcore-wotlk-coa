# 0620. A metric delta may kill several corpse fixtures

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0493, ADR 0582

## Context

Corpse Explosion 533239 "Explode all nearby corpses, each dealing ... Plague damage" (claim 325.0) needs a count of
explosions that grows with the corpses, against a control with fewer corpses (mentor, 17:39). The `corpse` option
(ADR 0493) adds one creature, killed by the entry's setup cast in the treatment phase; Void Zone 92559, the killing
cast, strikes one target.

## Options

1. Let `corpse` take a list (changes the parsed value every existing corpse entry and test reads).
2. A new `metric_delta` option module `extra_corpses` that adds `corpse2`, `corpse3`, ... and kills each with the same
   setup spell right after setup cast 0, through the `setup_cast_steps` named point.

## Decision

Option 2. `metric_delta_options/extra_corpses.py` (`[{"entry", "health", "distance"}, ...]`) requires the `corpse`
option and exactly one setup cast. No harness change: the fixture creatures and casts already exist.

## Consequences

- 533239 `several_corpses` (corpses at 5 and 7 yd: 2 hits of 533240 on the dummy) and `fewer_corpses` (one corpse:
  1 hit), both with the no-corpse control phase (0).
- Templar scenarios are unchanged (no Templar entry sets the option).
