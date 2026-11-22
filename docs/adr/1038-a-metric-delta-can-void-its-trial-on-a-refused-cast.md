# 1038. A metric delta can void its trial on a refused cast

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Sun Cleric Learning Light 300360 ("Lasts for $301265d or 3 casts"): the charge-count scenarios spaced Illumination 500143
casts 1600 ms apart, shorter than its 2000 ms cast time (Spell.dbc), so one cast per phase was refused with reason 105
and the count was off. The judge of a `metric_delta` entry never reads the run's `cast_failures`, so the refusal went
unnoticed and the readings were judged as alerts. Mentor ruling D-204.

## Options

- Add `cast_failure` reads for every setup cast: a harness and scenario change, and it still would not change a verdict.
- An opt-in flag that reads the result's existing `cast_failures`: Python only.

## Decision

An opt-in `void_on_cast_failure` in `metric_delta_options`: its option verdict hook sets `unmeasured` when
`cast_failures` lists a refusal. Refused for a `cast_failure` metric.

## Consequences

- Absent by default: no entry of an existing class writes it; the finished classes regenerate byte-identical.
- Seeded test: a refused setup cast gives `unmeasured`, a clean run is judged, the mutant without the flag judges the
  refused run.
