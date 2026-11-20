# 0740. A metric delta displacement can state its direction

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claims 33.0 (Vault 500085, "Dash in the direction you are moving") and 34.0 ("Distance scales with
movement speed.") need the leap's direction and its distance against the run speed. The server takes the direction
from the caster's movement flags and the distance as 15 x the run speed rate (`AscensionWitchHunterAbilities.cpp:
380-395`). Gap design A2 (c13 gap designs), on top of D-9 (built first as ADR 0739) and A1 (ADR 0731), mentor ruling
D-201.

## Options

- A `bearing` on the `displacement` option: the treatment displacement must point the stated angle from the facing
  read at its start; the distance arm is the plain `expected_ratio` on the displacements with a run speed aura in
  the treatment phase.
- Static points at an offset from the start (the design's `point_distance_2d` plus `{dx, dy}`): they need the start
  coordinates at generation time, which a leap in the control phase moves.

## Decision

The bearing, judged on `atan2` of the displacement less the start facing, with a default tolerance of 15 degrees, and
a 1 yd minimum length (a shorter move shows no direction). The promise of `displacement_2d` widens to
`dash\w*|direction|distance` (a row of the option, not a global row).

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests: 90 and 100 degrees pass for a stated 90, 110, 0 and -90 alert; 180 and -175 pass for 180; the mutant
  that ignores the start facing would pass a move along a facing of 90 degrees, which alerts; a bearing outside
  (-180, 180], a tolerance without a bearing or at 90 is refused.
- Witch Hunter: `500085 behaviour_metric_delta strafe_left` (90 degrees, at least 5 yd), `vault_backward` (180) and
  `vault_speed` (22.5 against 15 yd, ratio 1.5). Pilot 20261116-064510: 12.5 yd at 90.1 degrees (terrain shortened
  the strafe; the direction claim states no distance), 15 yd at 180.0, ratio 1.5.
