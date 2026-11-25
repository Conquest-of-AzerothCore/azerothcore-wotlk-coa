# 1317. Opt-in `aura_duration_map_update_carry_in` adds `MapUpdateInterval` carry-in for `aura_duration_ms`

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist class-end pair 2 diagnosis (`502216` Darkwither `aura_duration_ms #1` transient alert); amended after independent review `cu-rev7`

## Context

In Cultist class-end pair 2 Run 1, `conformance-cultist-value-502216` (*Darkwither*, instant cast, 15000 ms
duration) produced a transient `alert` on `502216 aura_duration_ms #1`: measured `14990 ms` against `[14997, 15000]`.
In Run 2, the same binary measured `15000 ms` against `[14925, 15000]` (`ok`).

In Run 1, the concurrent simulated lanes stepped at `1 ms` throughout `502216`'s run (`max_step_ms = 1`).
`compare.elapsed_bound` summed `elapsed_ms + max_step_ms` over the 3 steps after `cast` (`cast_failure`,
`aura_present`, `aura_duration_ms`), giving `W_step = 3 * (0 + 1) = 3 ms` and lower bound `14997 ms`.

However, `WorldConfig.cpp:241` sets `CONFIG_INTERVAL_MAPUPDATE` (`MapUpdateInterval`) to `10 ms`, and
`MapMgr.cpp:53, 460-461, 478` accumulates world tick `diff` into `i_timer[3]` and only invokes
`map->Update(i_timer[3].GetCurrent(), diff)` once `i_timer[3].Passed()` (`>= 10 ms`). When `cast` executes,
`i_timer[3]` can already hold up to `9 ms` (`MAP_UPDATE_INTERVAL_MS - 1`) carried in from ticks *before* the cast,
regardless of `max_step_ms < 10`. Crossing `10 ms` within the next post-cast ticks flushes `map->Update(i_timer[3])`,
subtracting up to `9 + step_diff` ms from the newly applied aura (`15000 - 10 = 14990 ms` at `max_step_ms = 1`,
or `17 ms` over 1 step at `max_step_ms = 8`).

By contrast, `cooldown_ms` reads `Player::GetSpellCooldownDelay` (`CoAGameplayTest.cpp:6724-6725`,
`Player.cpp:17696-17714`), which compares against `GameTime::GetSystemTime()` and does **not** pass through
`MapMgr::i_timer[3]`. Carry-in therefore has no engine justification on `cooldown_ms`.

Furthermore, an ungated change in `compare.py` alters judging for finished classes (13, 14, 15, 19, 23, 27)
invisibly to scenario generation guards, and an uncapped `9 ms` carry-in on a short `1000 ms` aura at
`max_step_ms = 1` (`W = 3 + 9 = 12 ms`) would allow a duration short by `1%` (`990 ms`) to pass.

## Options

- Move the read step earlier in `values.py`: rejected; cannot prevent a `9 ms` pre-cast carry-in from flushing on
  the very first tick after `cast`, and would alter generated scenarios of finished classes.
- Apply carry-in unconditionally to all time checks in `compare.py`: rejected; widens `cooldown_ms` without engine
  basis, alters finished classes without re-audit, and allows `1%`-short passes on `<= 1200 ms` auras.
- Gate the physical `9 ms` carry-in behind a class-file opt-in boolean (`"aura_duration_map_update_carry_in": true`),
  restrict it to `aura_duration_ms` checks only, and cap application to `W_step + 9 < 0.01 * expected`. Chosen.

## Decision

Update `compare.py` ([doc](../../apps/coa-gameplay-test/conformance/docs/generate-and-compare.md)):

- Add top-level optional class-file boolean `aura_duration_map_update_carry_in`
  (`AURA_DURATION_MAP_UPDATE_CARRY_IN_KEY = 'aura_duration_map_update_carry_in'`, default `False`, rejecting
  non-boolean values). Set `"aura_duration_map_update_carry_in": true` only in `classes/cultist.json`.
- Keep `elapsed_bound(run, label)` identical to its pre-branch formula:
  `W_step = sum(CAST_MARGIN_MS + max_step_ms if label == 'cast time' else elapsed_ms + max_step_ms for step in steps[cast + 1 : position + 1])`.
- Restrict carry-in to `aura_duration_ms` checks only (`judge_token` passes `carry_in=aura_duration_map_update_carry_in(class_file)`
  to `judge_time`; `cooldown_ms` always calls `judge_time` with `carry_in=False`).
- Define `MAP_UPDATE_INTERVAL_MS = 10.0`, `MAP_UPDATE_CARRY_IN_MS = 9.0` (`MAP_UPDATE_INTERVAL_MS - 1.0`), and
  `CARRY_IN_MAX_RELATIVE = 0.01`.
- Compute `applied_carry` in `aura_carry_in_ms(run, label, W_step, expected)`:
  - `9.0 ms` when `carry_in` is opted in, `position > cast`, `run.max_step_ms < 10.0`, and
    `W_step + 9.0 < 0.01 * abs(expected)`;
  - `0.0 ms` otherwise (including `max_step_ms >= 10`, no preceding `cast` step, or any short duration where adding
    carry-in would reach or exceed `1%` of `expected`).
- Total bound for `aura_duration_ms`: `W = W_step + applied_carry`, lower bound `expected - W`, upper bound
  `expected` (unchanged).
- Emit the `plus 9 ms map-update carry-in` explanation note only when `applied_carry > 0`.

### Sensitivity check (wrong durations still alert)

- `1000 ms` aura (`1% = 10 ms`, 3 post-cast steps, `max_step_ms = 1`): `W_step + 9 = 12 >= 10`, so
  `applied_carry = 0`, `W = 3 ms` (`[997, 1000]`). Both `990 ms` (`1%` short) and one tick period short (`500 ms` /
  `0 ms`) alert.
- `15000 ms` aura (`1% = 150 ms`, 3 post-cast steps, `max_step_ms = 1`): `W_step + 9 = 12 < 150`, so
  `applied_carry = 9`, `W = 12 ms` (`[14988, 15000]`). Darkwither `502216`'s observed `14990 ms` passes (`ok`),
  while `14850 ms` (`1%` short) and `12000 ms` / `14000 ms` (one tick period short) alert.
- `60000 ms` aura (`1% = 600 ms`, 3 post-cast steps, `max_step_ms = 1`): `W_step + 9 = 12 < 600`, so
  `applied_carry = 9`, `W = 12 ms` (`[59988, 60000]`). Both `59400 ms` (`1%` short) and one tick period short
  (`57000 ms` / `59000 ms`) alert.
- `max_step_ms = 8` (`< 10`, 1 or 3 post-cast steps, `15000 ms` aura): `applied_carry = 9`, giving `W = 17 ms` (1 step)
  or `W = 33 ms` (3 steps), bounding the physical `9 + 8 = 17 ms` / `17 + 0 + 16 = 33 ms` `MapMgr::i_timer[3]` flush.

## Consequences

- With `aura_duration_map_update_carry_in` absent or `false`, the `judge_time` code path and verdict text are
  byte-for-byte identical to pre-branch `compare.py` for every class (13, 14, 15, 19, 23, 27).
- `cooldown_ms` is never affected, even in classes that opt in.
- Eliminates transient `aura_duration_ms` false alerts on fast `max_step_ms < 10` runs for opted-in classes while
  never allowing a `1%`-short or one-tick-period-short duration to pass.
- Unit tests in `test_compare.py` verify opt-in gating, `cooldown_ms` immunity, small-step `max_step_ms = 8` carry-in,
  the `14990 ms` `502216` case, `1%`-short and one-tick-period-short alerts for `1000 ms`, `15000 ms`, and `60000 ms`
  auras, no carry-in note without a preceding `cast`, and non-boolean validation.
