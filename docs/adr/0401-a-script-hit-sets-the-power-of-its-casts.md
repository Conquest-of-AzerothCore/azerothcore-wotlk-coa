# 0401. A script hit sets the power of its casts

- Status: accepted
- Date: 2026-11-13

## Context

`script_hit_trial` casts each of its `casts` through `hit_ratio_cast`, which sets the power to the spell's cost. A
Necromancer spell with a cast time and a Runic Power cost pays at the end of the cast, and Runic Power decays out of
combat: Ice Barrage 501997 (300 Runic Power, 2000 ms cast) failed with `SPELL_FAILED_NO_POWER` (85) on every cast of
pair 20261113-011238 / -011309 (build 17ff0cc7e580), so its tick damage read no hit. `hit_ratio_cast` already takes a
power value; `hit_ratio` and `metric_delta` entries expose it as `cast_power`.

## Decision

- A `script_hit` entry takes `cast_power`: the value `hit_ratio_cast` sets, in each cast's own power type, before every
  cast of the trial. Without it the cost is set as before.

## Consequences

- Entries without `cast_power` generate as before: Templar `generate --class 19` and `--stack` are byte-identical.
- Ice Barrage 501997's tick entry sets 1000 Runic Power.
