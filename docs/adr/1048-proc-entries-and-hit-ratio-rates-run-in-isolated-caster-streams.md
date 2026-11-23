# 1048. Proc entries and hit-ratio rates run in isolated caster streams

- Status: accepted (provisional number, renumbered at merge; outside the 1023 to 1047 range of task T)
- Date: 2026-11-21
- Builds on: the caster streams of the chance rate kinds (commit e922f54ed5, `kinds/stack_chance_rate.py`)

## Context

The six Witch Doctor `procs` entries take 54.0 h of game time per run and `300663 jinx_crit_rate` (a `hit_ratio`
critical rate over 175 parts) 25.4 h. Their triggers are single-target casts at the dummy (Reclamation 806288,
Malefic Arrow 801674, Malefic Wrath 807037; Lethargy Jinx 802065 and Hexfire 573026). The chance rate kinds already run
up to 12 isolated caster and dummy pairs in one scenario, with placement and cross-stream asserts.

## Decision

- `procs`: a cast-trigger entry at the dummy may set `streams` with an `isolation` (the `isolation_of` rules of the
  chance rate kinds, keyed on the aura). The plan, its parts and `scheduled_attempts` are unchanged; each stream makes
  ceil(attempts per part / streams) attempts and ceil(baseline attempts / streams) baseline attempts. Every step is
  copied per stream (`procs.streamed_steps`, the stream helpers of `kinds/stack_chance_rate.py`) and every read gets its
  stream suffix. Charges, extra dummies, minion events, excluded trial spells and other triggers are refused.
- `hit_ratio` with a `rate` (non-swing, the caster's own casts at its own dummy) may set `streams` the same way; each
  stream makes ceil(`trials` / `streams`) trials per arm and part.
- The judges are unchanged. `compare.judge_proc` and `behaviour_hit_ratio_verdict` first read the isolation bounds (a
  cross-stream damage read alerts, a placement breach is `unmeasured`), then sum every listed read over the streams
  per label (`compare.stream_summed`), so the statistic of each part is the one a single stream would give with all
  the attempts.

## Consequences

- Single-stream output is byte-identical: classes 19 (also `--stack`) and 23 generate unchanged (`diff -r`,
  2026-11-21).
- Witch Doctor, 8 streams each (game time per run, sum of waits): 503712 via 801674 11.86 to 1.67 h, 503712 via
  806288 13.65 to 1.95 h, 681242 10.75 to 1.53 h, 705871 3.46 to 0.51 h, 804620 5.25 to 0.78 h, 807904 9.02 to 1.28 h
  (54.0 to 7.7 h); 300663 jinx_crit_rate 25.4 to 3.6 h.
- Seeded tests in `test_procs.py` (`ProcStreamTests`) and `test_behaviours.py` (`HitRatioStreamTests`).
