# 1293. `area_dummies` cone allows offsets down to 0.5 yd and pre-relocation setup casts

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25

## Context

Cultist Eldritch Force 681474 (row 276 claim 3: "to enemies in front of you") triggers Eldritch Force 680576, a
narrow, short cone (`TARGET_UNIT_CONE_ENEMY_24` = 24 degrees in `Spell.cpp:1289-1291`, `EffectRadiusIndex[0] = 14` =
8 yd), reachable only after 5 critical ability casts earn `681794` and temporarily replace Gaze of C'Thun `502141`
with `680576`.

In `metric_delta_options/area_dummies.py` (ADR 1224), `parse_cone` enforced `2 <= offset <= 12` and `check` refused
any `setup_casts`. At `angle = 24` degrees (`inside = 10.8` degrees), the minimum offset of `2` yd placed the inside
dummy at `2 / sin(10.8°) = 10.67` yd, beyond `radius - 1 = 7` yd. Allowing `offset` down to `0.5` yd (with default
unchanged at `6.0` yd) places a 24-degree, 8-yd cone cleanly at `offset = 1.0` yd and `behind = 166` degrees
(`inside = 5.34` yd, `outside = 4.38` yd, `behind = 4.13` yd, all inside `[4, 7]` yd). Allowing treatment-only
`setup_casts` distinct from the trigger and hit spells lets the 5 crit setup casts run at the dummy before the caster
relocates to the cone vertex and casts the cone spell. Orchestrator decision D-39 approved this Python-only extension.

## Decision

- Lower the minimum opt-in `cone.offset` in `metric_delta_options/area_dummies.py` from `2` yd to `0.5` yd; keep the
  default `6.0` yd and all distance/bearing/height bounds unchanged.
- Permit treatment-only `setup_casts` with `area_dummies.cone` provided neither `spec.trigger_spell` nor
  `spec.fields['spell']` is in `spec.setup_casts`, and `setup_in_before` and `setup_only_after` are false. Because
  `cone_fixtures` inserts `relocate` and the geometry reads immediately before the single trigger cast, the setup casts
  run at spawn targeting the dummy before the cone relocation, and the read positions and orientation still verify the
  exact cone layout before the cone cast.

## Consequences

- Opt-in: existing cone entries (default `offset = 6.0`, no `setup_casts`) regenerate byte-identical, including their
  contract text.
- Zero C++ harness changes.
- Seeded tests in `test_area_dummies_cone.py` cover narrow-cone geometry (`24` deg / `8` yd / `offset = 1.0` /
  `behind = 166`), `setup_casts` ordering before `relocate`, `ok`, mutant (`outside` struck -> `alert`), `unmeasured`
  (skewed layout), and refusals (`offset < 0.5`, trigger/hit spell in `setup_casts`, `setup_in_before`,
  `setup_only_after`).
