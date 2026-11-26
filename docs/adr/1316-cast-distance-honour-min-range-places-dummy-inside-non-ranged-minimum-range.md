# 1316. `cast_distance` honours `RangeMin[0] > 0` for non-ranged spells when `honour_min_range` is enabled

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist class-end pair 2 diagnosis (`806175` Dreadfall `cooldown_ms` and `gap_closer_distance`)

## Context

In Cultist (class 25), Dreadfall `806175` uses `RangeIndex = 94` (`SpellRange` *Sting*: `RangeMin[0] = 8.0 yd`,
`RangeMax[0] = 40.0 yd`, `Flags = 0`). `values.cast_distance` previously returned `(RangeMin[0] + RangeMax[0]) / 2`
only when `SpellRange.Flags == SPELL_RANGE_RANGED (2)` and fell back to `DUMMY_DISTANCE = 3 yd` for all other
flags.

As a result, both generated scenarios for `806175` failed with `SPELL_FAILED_TOO_CLOSE (128)`:
- `conformance-cultist-value-806175` placed `dummy` at `3 yd < 8 yd`, leaving `806175 cooldown_ms` `unmeasured`.
- `conformance-cultist-hit-806175` placed `dummy` at `3 yd` and relocated the caster by `dx = +10 yd`, leaving
  caster and dummy `|10 - 3| = 7 yd < 8 yd` apart and `806175 hit_mean gap_closer_distance` `unmeasured`.

Finished class 15 (Witch Hunter) has a spell (`802006` Hunt, `RangeIndex = 54`, `Flags = 0`, `5–30 yd`) whose
generated hit scenario (`conformance-witch-hunter-hit-802006.json`) calls `cast_distance` and must remain
byte-identical.

## Options

- Honour `RangeMin[0] > 0` unconditionally in `values.cast_distance`: rejected, because it alters finished class 15's
  generated scenario `conformance-witch-hunter-hit-802006.json`.
- Gate non-ranged `RangeMin[0] > 0` midpoint placement on an explicit opt-in boolean `"honour_min_range": true` in
  the class file, passed by `value_scenario` and `hit_parts` into `cast_distance`. Chosen.

## Decision

Extend `values.py` and `hits.py` ([value-scenarios.md](../../apps/coa-gameplay-test/conformance/docs/value-scenarios.md),
[hit-scenarios.md](../../apps/coa-gameplay-test/conformance/docs/hit-scenarios.md)):

- Add top-level optional class-file boolean `honour_min_range` (`HONOUR_MIN_RANGE_KEY = 'honour_min_range'`,
  default `False`, rejecting non-boolean values).
- Extend `values.cast_distance(records, spell_id, min_range=False)`: when `Flags != SPELL_RANGE_RANGED` and
  `min_range` is true and `RangeMin[0] > 0`, return `(RangeMin[0] + RangeMax[0]) / 2` (refusing ranges whose
  midpoint does not lie strictly between `RangeMin[0]` and `RangeMax[0]`).
- Pass `honour_min_range(class_file)` from `values.value_scenario` and `hits.hit_parts` into `cast_distance`.
- When `honour_min_range` is omitted or `false`, `cast_distance` and all generated scenarios are byte-identical.

## Consequences

- Purely opt-in via `"honour_min_range": true` in `cultist.json`; zero diff on finished classes 13, 14, 15, 19, 23,
  and 27.
- Cultist `806175` Dreadfall spawns `dummy` at `24.0 yd` (`(8 + 40) / 2`): `value-806175` casts from `24 yd`
  (measuring `cooldown_ms`), and `hit-806175` relocates `+10 yd` to `14 yd` inside `[8, 40]` (measuring
  `gap_closer_distance`).
- Unit tests in `test_values.py` verify `cast_distance`, `value_scenario`, `hit_parts`, default identity, and
  boolean validation.
