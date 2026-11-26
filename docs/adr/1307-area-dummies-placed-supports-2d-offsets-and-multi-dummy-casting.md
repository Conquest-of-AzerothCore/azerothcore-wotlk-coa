# 1307. `area_dummies` `placed` supports explicit 2D `(dx, dy)` offsets and multi-dummy casting

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Builds on: ADR 0995 (`area_dummies`), ADR 1224 (`cone` and `edge`), ADR 1293 (narrow cone offsets)
- Harness note (G-39): opt-in `dx`/`dy` creature placement in `CoAGameplayTest.cpp` (`CreateTargets`), zero gameplay
  effect, default `distance` path untouched

## Context

Cultist Crushing Dissonance `804056` states `"Unleash a wave of maddening resonance, interrupting the current spell
cast of all enemies around you and preventing any spell in that school from being cast for $d."` (`Effect[0] = 68`
`SPELL_EFFECT_INTERRUPT_CAST`, `TARGET_SRC_CASTER` / `TARGET_UNIT_SRC_AREA_ENEMY`, `EffectRadiusIndex[0] = 14` = 8 yd,
`DurationIndex = 27` = 3000 ms). Claims `[0]` (interrupt) and `[1]` (3 s school lockout) were proved on a single dummy;
claim `[2]` (`"of all enemies around you"`) remained an accepted tool gap (approved GO #4 in `cu-rt3/review.md:200`):

1. `CoAGameplayTest.cpp:3592` (`CreateTargets`) placed fixture creatures only along `+x` (`distance`).
2. `metric_delta` `target_casts_before` (`behaviours.py:2036-2039`) cast only on the single primary `dummy` actor.
3. `area_dummies` list form placed dummies along `+x` with no casting step or per-dummy judge, while `cone` and `edge`
   require damage metrics (`804056` deals no damage and applies no aura).
4. `coverage.STATE_PROMISES['casting']` matches `"cast"`/`"interrupt"` words, not `"of all enemies around you"`.

## Decision

1. **Opt-in `dx` and `dy` on creature fixtures (`CoAGameplayTest.cpp`, `run.py`, `test_runner.py`, `README.md`):**
   - `CreateTargets` accepts optional `dx` and `dy` float offsets relative to the owner player (`position.m_positionX`
     and `position.m_positionY`). When neither is set, it executes the unchanged `distance` line.
   - `run.py` validates `dx` and `dy` in `[-100, 100]` with `hypot(dx, dy) <= 100`, refusing combinations that set both
     `distance` and `dx`/`dy`.
2. **Opt-in `placed` form on `metric_delta_options/area_dummies.py`:**
   - Accepts `{"placed": [{"dx", "dy", "before_expected", "expected", optional "tolerance"}, ...], optional
     "casts_before": [spell, ...]}` with 1 to 11 distinct non-zero `(dx, dy)` placements (also distinct from the
     primary dummy) and at least one placement expecting `expected != before_expected`.
   - Emits `area1..areaN` with `dx`/`dy`, inserts `casts_before` casts + settle wait for every `areaN` in both phases,
     reads `position_x/y/z` of `caster`, `dummy` and every `areaN` before the treatment trigger cast, and reads the
     entry's metric on every `areaN` after each phase's primary read.
   - Voids the trial (`unmeasured`) if any dummy's read planar offset differs from its plan by more than `0.25` yd or
     its height differs from the caster's by more than `1.0` yd, and alerts if any placed dummy misses its stated
     `before_expected` or `expected` within `tolerance`.
   - Declares self-contained `METRIC_EVIDENCE = {'area_casting': 'state'}` and `STATE_PROMISES = {'area_casting':
     r'all enemies|around you|nearby enemies|interrupt\w*|\bcast\w*'}` in `area_dummies.py`, stamping
     `evidence_metric: 'area_casting'` only for `placed` entries reading `casting`.

## Consequences

- Strictly opt-in: existing `area_dummies` list, `cone` and `edge` entries and all finished classes regenerate
  byte-identical; zero existing `coverage.py` rows are altered or overridden.
- Unlocks Cultist Crushing Dissonance `804056` row 375 claim 2 (`"of all enemies around you"`) with simultaneous
  multi-bearing enemies (`0°` front, `180°` behind, `+90°` left, `-90°` near the `11.935` yd effective edge) plus an
  uninterrupted outside control beyond the edge (`14` yd).
- Seeded tests in `test_area_dummies_placed.py` cover generation, `ok`, mutants (behind dummy not interrupted, outside
  dummy interrupted, control dummy not casting, primary alert, missing read), `unmeasured` (planar/height misplacement),
  evidence classification (`area_casting` promise match/non-match), and 18 refusal cases.
