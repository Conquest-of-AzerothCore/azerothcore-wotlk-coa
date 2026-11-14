# 0443. A run speed read promises a slow clause

- Status: accepted
- Date: 2026-11-13

## Context

Winds of Northrend 301333: "Increases the amount slowed by Lichfrost by $s1%." Its entry reads the dummy's live run
speed rate after a real Lichfrost 501978: 0.742859 without the talent (Lichfrost's -35%) and 0.57143 with it (-50%,
the talent's SPELLMOD_EFFECT3 -15). `STATE_PROMISES['run_speed_rate']` named "movement speed" and "run speed" only, so
the learned contrast counted as data for a clause that says "slowed".

## Decision

`STATE_PROMISES['run_speed_rate']` also names "slow" and its inflections.

## Consequences

- A learned run speed contrast proves a clause about a slow's amount.
- Tests: `SlowPromiseTest` (test_coverage.py), the slow clause and a damage proxy clause (data).
