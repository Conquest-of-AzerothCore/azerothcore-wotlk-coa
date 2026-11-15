# 0427. Dummy casts in the uncast phase, and long metric deltas

- Status: accepted
- Date: 2026-11-13

## Context

- Heartchill 801739's interrupt read (`casting` on the dummy) needs the channel in both phases: the control phase has
  no Heartchill (`cast_in_before: false`) but must show the dummy channelling. `target_casts_before` (ADR 0426) ran
  only with a trigger cast, so the control read 0 (pair b4-2, B3 side b).
- Unholy Erosion 807700's chance claim drives 35 Crypt Swarm channels per phase (252 s of waits). `metric_delta` set
  a timeout only for attack phases, so the scenario timed out at the harness default of 90 s (run.py).

## Decision

- `target_casts_before` are also cast in a phase without the trigger cast.
- A `metric_delta` scenario whose waits exceed the 90 s default carries `timeout_ms` (its waits plus the margin,
  `hits.timed`, up to the accelerated cap, as ADR 0361 already decided). Shorter scenarios are unchanged, so every
  existing scenario is byte-identical (`generate --class 19`, `--stack`).

## Consequences

`UncastTargetCastAndTimeoutTests` (test_behaviours.py) checks the channel before the control read and both timeout
cases.
