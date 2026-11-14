# 0640. A periodic hit ratio may remove its observed aura before each read

- Status: accepted
- Date: 2026-11-13

## Context

Necromancer claim 399.0, Expunge 705754: "Increases the target's damage taken from your Necromancer diseases by
$573233s1%". Its `hit_ratio` entry reads the cumulative Crypt Plague 570131 damage and hit count after every trial.
The harness runs one step per world update, so a periodic tick can land between the total read and the count read.
In the cycle 10 pair this happened once per run: run 1 control trial 2 read 24360 (two ticks of 12180) with a count
of 3, trial 3 read 36540 with a count of 2 (run 2: trials 17 and 18). The per-trial mean then varied, and the judge
returned insufficient_trials although every tick carried the same damage. The tick period (2000 ms) drifts against
the trial period, so no wait places the reads away from a tick.

## Options

- One step that reads the total and the count together: harness C++ beyond a read, and a metric pair the judge
  does not know.
- A settle wait before the reads: the disease keeps ticking through any wait.
- Remove the observed spell's aura from the target before each read, opt-in per entry.

## Decision

`clear_observed` (behaviours.py, `hit_ratio`): before each read pair, including the start read, a `set_aura`
`stacks: 0` step removes the observed spell's aura of the caster from the cast target. The last trial skips the
drain wait, which only lets pending hits land. Refused with swings, a rate entry or a target that is the caster.
Entries without the field generate unchanged; Templar `generate --class 19` and `--stack` are byte-identical.

## Consequences

- Each trial applies the observed aura afresh, so an entry that needs it held between trials (stack cap, a gate
  that reads it) must cast it inside each trial before the gated casts; 705754 now casts a one-stack Crypt Plague and
  then the Command at the start of every trial.
- Seeded tests in test_behaviours.py: the removal precedes every total read, the drain is dropped, an entry without
  the field keeps both, and swings are refused.
