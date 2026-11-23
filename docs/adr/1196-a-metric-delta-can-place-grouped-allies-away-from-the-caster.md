# 1196. A metric delta can place grouped allies away from the caster

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22
- Builds on: [ADR 1186](1186-a-metric-delta-may-read-grouped-allies-in-stated-arms.md),
  [ADR 0713](0713-a-metric-delta-can-move-the-caster-before-each-trigger-cast.md)

## Context

Sun Cleric owner ruling O-13 (class ADR 0028): Light of Absolution 807523 restores "to allies within $807524a1 yds"
(40 yd). The `ally_arm` allies stand at the caster's spawn. `relocate_before_trigger` moves the caster, not an ally,
before every trigger cast, and `run.py` bounds one `relocate` step to 20 yd, so neither places one ally inside and
another outside a 40 yd edge in the same scenario.

## Options

1. An option module `ally_offsets`: named grouped allies are moved along x once, right after grouping, in steps of at
   most 20 yd.
2. Raise the bound of `relocate_before_trigger` and move the caster: one distance per scenario, and the runner's step
   bound still refuses it.
3. A harness placement action: harness C++ for what relative steps already give.

## Decision

Option 1, `metric_delta_options/ally_offsets.py`: `{"<ally id>": yards}`, each above 0 and at most 100. Every id must
be a grouped ally of the entry's `ally_arm`. The moves are inserted right after the last `group` step, before either
phase, with dz 0; the caster stays at the spawn. The contract names each distance and the model carries the map. It
adds no check and no reading: the entry states the distances through `ally_arm` arms (`distance_2d`, a state).

## Consequences

- Absent by default, so the generated scenarios are unchanged; no other class file states it.
- Seeded tests in `test_ally_offsets.py`: 39 and 41 yd give 20 + 19 and 20 + 20 + 1 yd steps; zero, negative, above
  100, a non-number, a non-ally id, an ally outside the `ally_arm` count and a missing `ally_arm` are refused.
- Sun Cleric 807343 `ally_radius` uses it (ally at 39 yd, ally2 at 41 yd).
- Relative moves keep the spawn's height; a slope between the units would change the 3D distance, which the arms read
  in 2D only. The entry states the dz 0 premise.
