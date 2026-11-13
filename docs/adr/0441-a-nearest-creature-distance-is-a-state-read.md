# 0441. A nearest-creature distance is a state read that promises a return

- Status: accepted
- Date: 2026-11-13

## Context

Summoning Ritual 805038: "Summon a ritual circle at your location for $d. While active, you may cast Ritual Return
to return to it." Ritual Return 807098 teleports the caster to its owned Scourge Transporter 575091
(AscensionNecromancerAbilities.cpp:421-431). The harness already reads `nearest_creature_distance` (the caster's 2D
distance to the nearest living creature of an entry, -1 without one), but `coverage.METRIC_EVIDENCE` had no class for
it, so a metric_delta on it failed the evidence step.

## Decision

`nearest_creature_distance` is a STATE read; `STATE_PROMISES` lets it promise a clause naming a return or teleport
("return", "teleport" and their inflections).

## Consequences

- The `return_position` entry: no circle, Ritual Return refused (-1, control); after a real Summoning Ritual and a
  15 yd move, Ritual Return brings the caster onto the circle (0, within 0.5; 15 without the return).
- Tests: `ReturnDistancePromiseTest` (test_coverage.py): the return clause is behaviour, a damage proxy clause stays
  data, and the metric's evidence class is STATE.
