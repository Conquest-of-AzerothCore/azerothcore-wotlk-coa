# 0552. A periodic hit's period is judged from stamped hits

- Status: accepted
- Date: 2026-11-13

## Context

Soulfreeze 801724: "dealing ... Frost Damage every $t1 sec for $d" (claim 397.0, one chain read alone on an Ice-Locked
dummy, ADR 0538). Four held / ends hit-count reads in 10 ms windows bracketed the first and second hits; one of them
moved under load in pair c2-final-3. ADR 0535 already judges a cast period from stamped first and last events.

## Decision

- Behaviour kind `hit_period` (module `cast_period.py`, with the same hooks as ADR 0550). Precondition fixtures are set
  first (`set_aura`); a control read before the cast must count no hit. Then the trigger cast at the dummy, and the
  game time and the dummy's hits of `hit_spell` are polled over a game-time window that covers at least two periods.
  The verdict is ADR 0535's `cast_period` judge: (last stamped hit - first stamped hit) / (hits - 1), bracketed by the
  polls, inside the expected period +- the G-19 band.

## Consequences

- 801724 `chain_period`: about 10 ms polls over 1250-3600 ms; pair c2-final-4 read 980-990 ms against 1000. The four
  10 ms brackets were withdrawn.
- Tests: `HitPeriodTests` (test_cast_period.py), with a 1100 ms period that must alert. Templar `generate --class 19`
  and `--stack` byte-identical.
