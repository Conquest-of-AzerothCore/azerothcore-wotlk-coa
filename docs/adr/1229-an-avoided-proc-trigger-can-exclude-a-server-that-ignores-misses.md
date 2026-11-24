# 1229. An avoided proc trigger can exclude a server that ignores misses

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: mentor D-252 and D-253 (Sun Cleric 27, Blessed Bulwark 680663)

## Context

ADR 1210 counts misses among the trials of an avoided proc trigger. A server that rolls the proc on dodges and parries
only reads 0.25 x (1 - miss share) over those trials; at the 5.1% miss share of the measured runs that is 0.237,
inside the band [0.23, 0.27], so the verdict stays `ok` and no mutant alerts.

## Options

- Force an arm where every avoided attack is a miss: the trigger requires dodge + parry = 100 and the attackers'
  miss share is clamped at 60%, so it is not reachable with existing means.
- Narrow the band: changes every finished proc entry.
- An opt-in exclusion judged on the miss share read in the same run.

## Decision

The avoided trigger field `miss_exclusion: {"min_share": s}` (needs `count_misses`, s in (0, 0.5)) reads the miss
share m = missed swings / attacks taken of the counted parts. Under `min_share` the verdict is `unmeasured`: too few
misses to separate the two rates, the threshold being fixed in the entry before the run. Otherwise the rate of a server
that ignores misses, expected x (1 - m), must lie below the Wilson interval, else the verdict is `alert`. Python only,
opt-in, default off.

## Consequences

- Tests: `AvoidedProcMissesTest` (test_proc_avoided.py), including the mutant that never procs on a miss, which
  alerts although its interval is inside the band.
- Finished-class scenario digests (classes 15, 19, 19 --stack, 23) are byte-identical before and after.
