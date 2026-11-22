# 1016. A metric delta may read grouped allies in stated arms

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-22
- Builds on: ADR 0582

## Context

Six Sun Cleric claims state what an ally receives: Bless 804247 "Bless yourself and an ally", Pious 300943 and
680656 "grant allies Replenishment", Mercy 504848 "an ally and up to 5 nearby allies", Holy Form 805301 "healing your
ally affected by Bless" and Heat Wave 534267 "heals up to 5 of the target's lowest health nearby allies". A
`metric_delta` scenario has one player, so `measure_actor: "ally"` failed `run.py validate` ("unknown actor"), a
caster read cannot stand beside an ally read in one scenario, and an uncast before phase reads at once, so a periodic
effect has no control read at the treatment's time. The harness already reads `health`, `power`, `aura` and the heal
and energize totals on any player fixture, and other kinds (`party_stat_ratio`, `hit_ratio`, `internal_cooldown_gate`)
already add grouped ally players (code reading only for the reads on an ally in a `metric_delta` scenario; no run
yet).

## Options

1. Core fields in `MetricDeltaSpec` and `metric_delta_scenario` (an ally list, a second read, a control wait).
2. One opt-in option module, `ally_arm`, through the named points of ADR 0582.

## Decision

Option 2 (mentor D-48, controller design approval). `metric_delta_options/ally_arm.py`, `ORDER` 24:

- `allies` (1 to 5): grouped ally players `ally`, `ally2` .. `ally5` with the class's player fixture, regeneration off
  when the entry sets `disable_regeneration`, grouped right after the base steps. `measure_actor`, `target` and
  `fields.target` may then name them.
- `ally_health` `[value, maximum]` and `ally_casts` (spells the caster casts at `ally`, each followed by 2000 ms for
  the global cooldown) in both phases, through `phase_steps`, ahead of the trigger.
- `control_wait`: the uncast before phase waits the entry's `wait_ms` before its reading, so the control is read at
  the treatment's time. Only with `cast_in_before` false and the default gate timing.
- `arms`: extra reads, each summed over its `actors`, placed right after the main before and after readings. Every
  arm states `before_expected`, `expected`, `tolerance` and its `source`; an arm without one is refused at load, and
  there is no default tolerance (a random value such as a heal takes the G-19 band from its data). The arm's metric
  needs a `METRIC_EVIDENCE` row that is not a readback.
- Verdict: the main verdict is judged as before; an arm off its expectation turns it to alert, a missing arm read to
  unmeasured. The evidence class stays the main metric's. Without arms the verdict is the plain one.

## Consequences

- No new metric, no core or harness edit. Finished classes regenerate byte-identical (Witch Hunter, class 15, checked
  by `diff -r` at base and head; the other finished classes by the source stage's snapshot guard).
- The reads on an ally rest on code reading until a class author runs the exploratory probe of the T2 report in game.
- An ally cast's power is not set by the option: the caster's power at that point pays it.
