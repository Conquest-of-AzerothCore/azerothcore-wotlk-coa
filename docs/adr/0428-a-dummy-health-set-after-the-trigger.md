# 0428. A dummy health set after the trigger cast

- Status: accepted
- Date: 2026-11-13

## Context

- Death's Due 807796: "If the target's health is below 20% at the end of duration," was judged only with the dummy's
  health set before the cast (15%, 19%, 21%, 25%). That does not separate "at the end of duration" from "at the cast"
  (B4 side b review, I-5).
- The earlier crossing design lowered the health through a setup cast, which was refused at exactly its Runic Power
  cost (pair rv-1). `metric_delta` had no step between the trigger cast and the read.

## Decision

- `metric_delta` takes `target_health_after: [delay_ms, pct]`. After the trigger cast it waits `delay_ms`, sets the
  dummy's health percent (`set_health_pct`, the same harness fixture as `target_health_pct`), then waits the rest of
  `wait_ms`.
- It is refused unless the target is the dummy, there are no attack phases, the delay lies inside the wait and the
  percent lies between 0 and 100.
- An entry without it is unchanged: `generate --class 19` and `--stack` are byte-identical (2460 and 40 scenarios).

## Consequences

- `TargetHealthAfterTests` (test_behaviours.py) checks the step order and both waits, the refusal of a delay outside
  the wait, and the single wait of an entry without the field. Dropping the health step is the mutant that the first
  test catches.
- Death's Due gains a crossing-down arm (25% at the cast, 15% 1500 ms later: one hit). A crossing-up arm is not
  possible: the harness `set_health_pct` cannot raise health (pair route-5).
