# Summon random-direction movement (`kind: "summon_random_direction"`, ADR 1311)

ADR 1311 has a provisional number and is renumbered at merge (guide 14.4).

Proves that a spell creating multiple same-entry owned creature copies sends every copy running (displacing above
walk speed) in unbiased, non-deterministic directions across repeated casts.

## Harness primitives

- Read `owned_creature_copy_x` and `owned_creature_copy_y` (`actor`, `entry`, `index` in `0..31`): enumerate living
  summons of `entry` owned by `actor` sorted ascending by GUID and return the `index`-th creature's X or Y position
  (or `NaN` when fewer than `index + 1` copies exist).
- Both metrics are registered as `event` evidence inside `kinds/summon_random_direction.py`'s `METRIC_EVIDENCE` dict
  (no edit to `coverage.py`).

## Scenario and arms

- Reads `duration_ms` of `duration_spell` from `Spell.dbc` (refusing reads at or past `duration_ms` or despawn waits
  that do not clear `duration_ms`).
- `control`: reads `owned_creature_count == 0` before any cast (nonzero alerts).
- `treatment`: across `casts * parts` independent casts (`casts * copies * parts >= 24` total copies), verifies `0`
  leftover copies before each cast, casts `trigger_spell`, reads `owned_creature_count == copies` and GUID-sorted
  `(x, y)` at `+start_wait_ms` and `+start_wait_ms + run_ms` (`< duration_ms`), then waits `despawn_wait_ms`.
- Every copy must displace `>= min_run_yd` during `run_ms` (catching stationary and walking-only summons).
- Across all `M >= 24` movement bearings `atan2(dy, dx)`:
  - Mean resultant length `R <= max_resultant` (default `0.65`, catching single-direction and narrow-cone mutants).
  - Occupied 45-degree sectors `>= min_sectors` of `8` (default `5`, catching deterministic 1/2/3/4-way fans).
  - At `M = 24`, the uniform-direction false-fail upper bound is `<= 4.4e-5` per run (`<= 8.8e-5` per 2-run pair,
    well below `0.1%`).

## Refusals

Refuses unknown fields, `copies < 2`, fewer than `24` total observed copies, non-positive `min_run_yd`,
`max_resultant` outside `(0, 1)`, `min_sectors` outside `5..8`, and timings that read at/after `duration_ms` or fail
to wait past `duration_ms` for despawn.
