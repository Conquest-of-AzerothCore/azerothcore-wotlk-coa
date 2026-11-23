# 1119. The caster can step to one side of a range edge, with the layout read back

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0582 (metric_delta option modules), ADR 0993 (relocate_during_wait), G-29

## Context

Veil of Darkness 802100 "If you are within $806473r yds of the target": every 1500 ms the aura deals its hit only while
the caster is within 40 yd of the target (`IsWithinDistInMap`, both combat reaches). The cast range is also 40 yd, so
the caster can only be beyond the edge by moving after the cast. `relocate_during_wait` moves back and forth by a fixed
offset and reads nothing about the layout (cycle 8 tool note).

## Decision

- Option module `step_out`: `{"dx", "after_ms", "hold_ms", "radius", "side"}`. In the treatment phase, `after_ms` after
  the trigger cast at the dummy the caster moves `dx` yd along x (at most 20), is held `hold_ms` and moves back (named
  point `after_trigger_steps`). Right after the move and at the end of the hold the scenario reads the caster's 2D
  distance to the dummy, both heights and both combat reaches.
- Verdict (named point `verdict`): unmeasured unless both reads put the caster at least 0.25 yd on its `side` of
  `radius` (the 3D distance less both reaches); otherwise the plain judge stands.

## Consequences

- Witch Doctor: `802100 range_inside` (the tick lands, 1) and `range_beyond` (no tick, 0), the inside entry the control
  of the beyond one.
- New module only; classes 19 (with and without `--stack`) and 23 generate byte-identical output.
