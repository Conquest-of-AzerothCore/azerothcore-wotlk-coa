# 1317. `elapsed_bound` adds `MapUpdateInterval` carry-in when `max_step_ms < 10`

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist class-end pair 2 diagnosis (`502216` Darkwither `aura_duration_ms #1` transient alert)

## Context

In Cultist class-end pair 2 Run 1, `conformance-cultist-value-502216` (*Darkwither*, instant cast, 15000 ms
duration) produced a transient `alert` on `502216 aura_duration_ms #1`: measured `14990 ms` against `[14997, 15000]`.
In Run 2, the same binary measured `15000 ms` against `[14925, 15000]` (`ok`).

In Run 1, the concurrent simulated lanes stepped at `1 ms` throughout `502216`'s run (`max_step_ms = 1`).
`compare.elapsed_bound` summed `elapsed_ms + max_step_ms` over the 3 steps after `cast` (`cast_failure`,
`aura_present`, `aura_duration_ms`), giving `W = 3 * (0 + 1) = 3 ms` and lower bound `14997 ms`.

However, `WorldConfig.cpp:241` sets `CONFIG_INTERVAL_MAPUPDATE` (`MapUpdateInterval`) to `10 ms`, and
`MapMgr.cpp:53, 460-461, 478` accumulates world tick `diff` into `i_timer[3]` and only invokes
`map->Update(i_timer[3].GetCurrent(), diff)` once `i_timer[3].Passed()` (`>= 10 ms`). When `cast` executes,
`i_timer[3]` can already hold `7–9 ms` carried in from ticks *before* the cast. Crossing `10 ms` within the next
3 ticks flushes `map->Update(10)`, subtracting `10 ms` from the newly applied aura (`15000 - 10 = 14990 ms`)
despite only `3 ms` of world ticks elapsing since `cast`.

Moving the `aura_duration_ms` step earlier does not eliminate this: `CoAGameplayTest::Progress` executes one step
per world tick, so even 1 tick after `cast` a `9 ms` carry-in flushes `map->Update(10)`.

## Options

- Move the read step earlier in `values.py`: rejected; cannot prevent a `9 ms` pre-cast carry-in from flushing on
  the very first tick after `cast`, and would alter generated scenarios of finished classes.
- Widen `elapsed_bound` in `compare.py` by a large fixed tolerance: rejected; would weaken detection of genuinely
  wrong durations.
- Add the exact `MapUpdateInterval` carry-in `max(0.0, 10.0 - run.max_step_ms)` in `compare.elapsed_bound` when at
  least one step follows the cast. Chosen.

## Decision

Update `compare.py` ([doc](../../apps/coa-gameplay-test/conformance/docs/generate-and-compare.md)):

- Define `MAP_UPDATE_INTERVAL_MS = 10.0` matching `CONFIG_INTERVAL_MAPUPDATE` (`WorldConfig.cpp:241`).
- Exact bound formula before:
  `W_before = sum(CAST_MARGIN_MS + max_step_ms if label == 'cast time' else elapsed_ms + max_step_ms for step in steps[cast + 1 : position + 1])`
- Exact bound formula after:
  `W_after = W_before + (max(0.0, MAP_UPDATE_INTERVAL_MS - max_step_ms) if position > cast else 0.0)`
- When `max_step_ms >= 10` (such as `25 ms`), `carry_in = 0` and `W_after == W_before`.
- When `max_step_ms = 1` with 3 post-cast steps (`elapsed_ms = 0`), `W_after = 3 + 9 = 12 ms`, giving `[14988, 15000]`
  for a `15000 ms` duration (`14990 ms` is `ok`).

### Sensitivity check (wrong durations still alert)

- A duration off by one tick period (e.g. `3000 ms` on Darkwither, or even a `1000 ms` tick period) differs by
  `>= 1000 ms >> 12 ms` and always alerts.
- A duration off by `1%` on `15000 ms` (`14850 ms` or `15150 ms`, delta `150 ms >> 12 ms`) alerts; even on a short
  `1500 ms` aura, `1%` (`15 ms`) exceeds `W_after = 12 ms` (`1485 < 1488`) and alerts.
- The upper bound `measured <= expected` is unchanged.

## Consequences

- Judge-only change in `compare.py`; zero changes to generated scenarios of any class (no opt-in key needed).
- Eliminates transient `aura_duration_ms` / `cooldown_ms` false alerts on fast `max_step_ms < 10` runs while
  leaving `max_step_ms >= 10` bounds unchanged.
- Unit tests in `test_compare.py` verify the `14990 ms` `max_step_ms = 1` case, `max_step_ms = 25` identity, and
  alerts for durations off by one tick period, by `1%`, by `1 ms` below `[14988, 15000]`, or above `expected`.
