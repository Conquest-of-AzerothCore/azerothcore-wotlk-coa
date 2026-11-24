# 1236. A metric delta brackets its reading from the aura apply stamp

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: mentor D-282 (Sun Cleric 27, Stalwart 300355 "prevent you from being critically struck again for
  $301342d", ledger L43 claim 1, review I-1)

## Context

A duration claim read at a game time after the trigger cast proves the duration only when the aura starts at the
cast. Stalwart's aura 301342 starts at the landing of a Strike before the clock cast, at an offset that no read
bounded: a gone reading 4010..4130 ms after the cast excluded a 4400 ms duration only for an offset below 270 ms.
`event_first_ms` drops events before its `since_spell` cast and takes the last cast of a repeated spell, and the
`game_time_ms` reads give no aura apply time.

## Options

- A `game_time_ms` read before the first Strike: bounds the offset from above only, and needs the landing to follow
  that read.
- A harness read of the aura's apply time: new harness C++.
- The existing encounter timeline (`encounter_start`, `timeline_first_ms`, `timeline_count`), which already stamps
  aura applies (`OnAuraApply`, refreshes included) and casts in one game-time base.

## Decision

The `metric_delta` option `apply_stamp` (`{aura, window, source}`) opens the timeline before the after phase's
strikes, reads the apply count and the game time right after the trigger cast, and reads the game time, the apply
count, the trigger cast stamp and the first apply stamp right after the after reading. The reading is bracketed from
the apply: at least `game_time after - cast_upper` (no apply after the cast, counts equal), at most `read_upper -
game_time cast + (clock - first)`. The bracket must lie in `window`, else `alert`; a missing stamp, no apply or an
apply after the cast is `unmeasured`. Python only, opt-in, default off; the evidence metric stays the entry's own.

## Consequences

- Test: `ApplyStampTests` (metric_delta_options/test_apply_stamp.py), with the seeded mutant (a 4400 ms duration
  hidden by an apply 400 ms before the cast) that passes the game-time window alone and alerts with the stamp.
- Only entries that set the option change; finished-class scenario digests are unchanged.
- A scenario with the option runs exclusive in a simulated-clock batch (`encounter_start` is process global).
- Documented in `apps/coa-gameplay-test/conformance/docs/metric_delta_options/apply_stamp.md`.
