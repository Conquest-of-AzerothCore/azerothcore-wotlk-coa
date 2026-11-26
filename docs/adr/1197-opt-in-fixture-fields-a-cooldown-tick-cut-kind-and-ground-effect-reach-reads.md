# 1197. Opt-in fixture fields, a cooldown tick cut kind and ground-effect reach reads

- Status: proposed (provisional number; renumbered at merge, guide 14.4)
- Date: 2026-11-22
- Related: [ADR 0581](0581-behaviour-kinds-are-modules-discovered-at-run-time.md) (kind modules),
  [ADR 0582](0582-metric-delta-options-are-modules.md) (option modules),
  [ADR 0718](0718-an-attack-proc-can-count-off-hand-trials.md) (off-hand trials),
  [ADR 0120](0120-two-proof-statuses-computed-by-clause-coverage.md) (evidence classes).
- Decided by: mentor D-145 / D-147 (Sun Cleric tool group 5), controller approval of the design note, D-153
  (the four hysteresis edges), D-154 (boss fixture arms).

## Context

Eight Sun Cleric claims could not be expressed: a health state with a 75%-80% hysteresis read only from full health
(704585, 561328), an immunity whose spell targets an enemy (520024), a proc that rolls on either hand's auto attack
(802935), a cooldown cut 10% per tick (300361), a proc on an effective heal inside a cost gate (300349), a ground
effect's reach written term by term (520647), and a boss gate (704579, entries only).

## Options

- Change the defaults of the kinds. Rejected: the finished classes' scenarios would move.
- Opt-in fields and new modules, each absent by default, so every existing scenario regenerates byte-identical.
- For 300361, a cooldown read at a stated tick epoch (design A) or a read-only periodic-timer metric (design B).
  Rejected in favour of an epoch-free bracket: both need a value (the epoch) not read yet.

## Decision

- `taken_hit` `caster_health_from_pct`: each arm opens at that percent, 1000 ms, then `caster_health_pct`, 1000 ms,
  regeneration off. `metric_delta` option module `caster_health_from` does the same once per phase.
- `immunity` `cast_target: "dummy"`: the spell is cast at the dummy, the carrier `aura` read on the caster with no
  extra settle; an immune window longer than the carrier's duration is not modelled.
- `procs` `trial_hand: "both"`: trials and attempts read with no hand (the harness sums both) and the plan spaced by
  the combined swing rate.
- `cost_gate` `caster_health_pct`: the caster's health is set before every arm's after casts.
- Kind module `cooldown_tick_cut`: reads `cooldown_ms` with `game_time_ms` several times per amplitude. An interval
  shorter than the amplitude holds at most one tick, seen as a drop beyond the time elapsed, and for it
  `r2 = (1 - p)(r1 - a) - (D - a)` for an unknown offset `a` in `[0, D]`, so `1 - (r2 + D) / r1` and
  `1 - r2 / (r1 - D)` bracket the cut `p` with no epoch; every bracket must lie inside the G-19 band and the tick
  count must match the span over the amplitude. The count alone does not prove the period: over 3108 ms a 900 ms
  period gives 3 or 4 ticks and an 1100 ms one 3 in most phases, both allowed (t9 review I-1). The period is
  judged on its own bracket instead: tick `j` falls in its read interval `[s_j, e_j]`, so the period lies between
  `(s_j - e_i) / (j - i)` and `(e_j - s_i) / (j - i)` for every pair of ticks. That bracket must lie inside the
  amplitude +- 5%; one wholly outside or empty alerts, so a period 10% off on either side never passes. Its width
  is `2 * step / (ticks - 1)`, so the reads default to 61 at 100 ms (about 6.5 s, 6 or 7 ticks, width about 44 ms
  with the 109 ms measured intervals), and a layout whose width cannot stay below 5% of the amplitude is refused.
  A first design read exactly one amplitude apart: the pilot measured
  1009 ms intervals (the read steps take game time), so an interval could hold 0 or 2 ticks. The derived metric
  `cooldown_tick_cut_pct` is an event: it is the tick handler observed acting on the cooldown over time, not a
  stored value read back. 301176 Effect[1] is BasePoints 9 + DieSides 1 = 10%.
- Harness reads `dynamic_object_radius` (`DynamicObject::GetRadius`) and `dynamic_object_size` (`GetObjectSize`),
  read-only, readback evidence, beside `dynamic_object_height` (G-39 note sent to the controller).
- Boss arms of 704579 use the existing `target_entry`; the raid-encounter and world-boss-rank arms are left to the
  Twilight server fix (D-154).

## Consequences

- Witch Hunter 15, Templar 19 (and its stack) and Necromancer 23 regenerate byte-identical.
- An interval as long as the amplitude is unmeasured, never judged.
- The both-hand plan assumes the handler rolls on either hand; a main-hand-only handler reads half the rate and
  alerts.
