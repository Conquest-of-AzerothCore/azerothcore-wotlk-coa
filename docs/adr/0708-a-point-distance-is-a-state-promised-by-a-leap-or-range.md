# 0708. A point distance is a state promised by a leap or a range

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

The harness metric `point_distance_2d` (the horizontal distance from a unit to a fixed point) had no row in the
closed evidence tables, so no scenario could count it. Night Walker 789256 (Witch Hunter) increases the leap
distance of Vault in the class script, not the spell range (c10-hound, key 308.0). Mentor decision D-158 (design
D-9).

## Decision

New keys only: `METRIC_EVIDENCE['point_distance_2d'] = STATE` and `STATE_PROMISES['point_distance_2d'] =
leap|range|yd`. No existing row moves.

## Consequences

- Digests identical. Necromancer final16 re-audit identical; no Templar or Necromancer scenario or ledger uses the
  metric.
- Witch Hunter use not proven: no generated scenario reads `point_distance_2d`, because a fixed point needs the
  caster's start coordinates; a start-point fixture (a scenario `location` and the point fields) is a further design
  (cycle 11 tool report).
