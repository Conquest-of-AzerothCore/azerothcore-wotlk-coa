# 1027. Opt-in fixture fields, a cooldown tick cut kind and ground-effect reach reads

- Status: proposed (provisional number; renumbered at merge, guide 14.4)
- Date: 2026-11-22
- Related: [ADR 0581](0581-behaviour-kinds-are-modules-discovered-at-run-time.md) (kind modules),
  [ADR 0582](0582-metric-delta-options-are-modules.md) (option modules), [ADR 0718](0718-an-attack-proc-can-count-off-hand-trials.md) (off-hand trials),
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
- Kind module `cooldown_tick_cut`: reads `cooldown_ms` with `game_time_ms` one amplitude apart. One amplitude holds
  exactly one tick wherever it falls, so `r2 = (1 - p)(r1 - a) - (D - a)` for an unknown offset `a` in `[0, D]`, and
  `1 - (r2 + D) / r1` and `1 - r2 / (r1 - D)` bracket the cut `p` with no epoch; every bracket must lie inside the
  G-19 band. The derived metric `cooldown_tick_cut_pct` is an event: it is the tick handler observed acting on the
  cooldown over time, not a stored value read back. 301176 Effect[1] is BasePoints 9 + DieSides 1 = 10%.
- Harness reads `dynamic_object_radius` (`DynamicObject::GetRadius`) and `dynamic_object_size` (`GetObjectSize`),
  read-only, readback evidence, beside `dynamic_object_height` (G-39 note sent to the controller).
- Boss arms of 704579 use the existing `target_entry`; the raid-encounter and world-boss-rank arms are left to the
  Twilight server fix (D-154).

## Consequences

- Witch Hunter 15, Templar 19 (and its stack) and Necromancer 23 regenerate byte-identical.
- An interval whose game time is not exactly one amplitude is unmeasured, never judged.
- The both-hand plan assumes the handler rolls on either hand; a main-hand-only handler reads half the rate and
  alerts.
