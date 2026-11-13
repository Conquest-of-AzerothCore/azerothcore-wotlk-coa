# 0501. A metric_delta reading is stamped in game time

- Status: accepted
- Date: 2026-11-13

## Context

ADR 0485 found that every harness wait step runs 10 to 17 ms of game time past its nominal `ms`, and the mentor ruled
that a duration, expiry or cast-time claim judged through nominal waits counts only after a rejudge in game time.
ADR 0485's `aura_expiry` kind reads a minion aura applied by a forced roll; it cannot read an aura on the dummy, a
summon's timed explosion or a cast's end. The Necromancer batch M side c entries (Crypt Plague duration, tick period
and no refresh, Entomb duration, Wormfood explosion time, Scourge Disciple cast time) read such ends with held / ends
pairs of metric_delta entries whose read times are nominal wait sums.

## Decision

- metric_delta takes an optional `game_time` field: `after` (and `expired`, only with `expiry_wait_ms`) are windows in
  ms. The scenario reads the read-only `game_time_ms` metric (ADR 0485) right before the treatment phase's trigger
  cast and right before each judged reading. The verdict keeps the metric judgement and adds: every stamped reading's
  game time after the cast lies in its window, else `alert`; a missing stamp is `unmeasured`.
- The windows are the G-19 band around the stated value (5% of the tooltip duration or cast time), so a held / ends
  pair brackets the end inside the band on both sides in game time. The expected readings do not change; read times
  close to a band edge move inward by the measured overhead of their wait steps.
- No harness C++ change; entries without `game_time` generate the same scenarios (Templar `generate --class 19` and
  `--stack` byte-identical).

## Consequences

- Converted entries (integration of batch M): 500341 held / ends, 570131 lasts / ticks / no_refresh, 560800
  explode_before / explode_after, 531126 cast_held / cast_done.
- Icebound Champion's pushback reduction (807813, six entries) is a ratio of three cast ends across the two phases of
  several scenarios; a per-reading window cannot judge it against the observed control, so it is not converted and
  stays not final until a game-time design reads it.
- The P5 passive link names the `aura_expiry` label (`<spell> behaviour_metric_delta <label_suffix>`), which plain
  `generate --class 23` needed once an `aura_expiry` entry's spell was linked from a passive.
- Tests: `MetricDeltaGameTimeTests` and `AuraExpiryPassiveLinkTests` (test_behaviours.py).
