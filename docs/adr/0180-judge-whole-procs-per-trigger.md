# 0180. Judge whole procs per trigger

- Status: accepted
- Date: 2026-11-11
- Extends: ADR 0130 (Scourgebane counts strikes per landed swing)

## Context

Retribution 707391, "Melee damage dealt now has a $h% chance to strike 2 additional times for $s1% of the damage
dealt as Holy Damage." Its rate (`707391 proc_rate`, events divided by `events_per_proc` 2) and the size of each
strike (`707391 trigger_magnitude_ratio`) were proven, but "strike 2 additional times" was not. A summed count reads
the same 0.4 strikes per swing for two strikes at 20% as for one strike at 40%, or for a server that strikes once
in some procs and twice in others.

The per-trigger mode of ADR 0130 reads the strikes after every swing and alerts on more procs than the stated
limit. With two events per proc, a trigger with one strike reads half a proc. It counted as no proc and only lowered
the rate, so a server striking once now and then could still pass.

## Options

1. A new behaviour kind that swings and counts strikes per swing. It repeats the per-trigger reads.
2. Keep the summed rate and add a magnitude check per proc. The magnitude is per strike, not per proc.
3. In the per-trigger judge, alert on a one-hit trigger whose events are not a whole multiple of
   `events_per_proc`.

## Decision

Option 3. `judge_proc_per_trigger` counts the one-hit triggers with a fractional proc count and alerts when there
is any. The explanation names how many. Retribution's proc entry sets `most_procs_per_trigger` 1, sourced from the
tooltip and from `AscensionTemplarEvents.cpp` (one `OnProc` per proc, two casts of 525028, the event flag refusing
the strikes' own hits).

## Consequences

- An entry with `events_per_proc` 1 cannot read a fractional count, so Scourgebane is judged as before.
- Retribution's 13 proc parts now read every swing (per-trigger steps), so they differ from the base generation.
  The rate claim (255) is judged by the same counted runs.
- Seeded tests: two strikes in a fifth of the swings pass; one single strike, a server that strikes once per proc,
  and a three-strike swing alert.
