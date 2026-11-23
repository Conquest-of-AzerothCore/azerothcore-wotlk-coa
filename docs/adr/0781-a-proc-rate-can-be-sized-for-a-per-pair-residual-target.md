# 0781. A proc rate can be sized for a per-pair residual target

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

D-197 bounds the false-alert probability of a probabilistic label at 0.1% per pair, and D-198 asks for its false-pass
probability against a neighbouring value. A banded `proc_rate` (ADR 0346) judges a 99% interval, so its residual
depends on how far the interval sits inside the band, which authors computed by hand per entry. Mentor decision D-250
(item T9, c15 tool batch), owner delegation O-12.

## Options

- An opt-in `residual_target` with `min_detectable`: the per-run Wilson confidence becomes `1 - residual_target / 2`,
  the sizing requires `band + 2 x half-width <= min_detectable`, generate refuses an under-sized plan with the attempt
  count it needs, and the verdict row computes the rejection probability of a `min_detectable` deviation.
- Sizing the trials automatically to the target: hides the run cost from the author and the mentor, who decide
  whether an attempt count is affordable.
- Keeping hand-written residual statements: not checked by the tool.

## Decision

The opt-in fields, on banded entries only. `procs.residual_sizing` computes `z = Phi^-1(1 - residual_target / 4)` and
the trials `ceil(z^2 p (1 - p) / ((min_detectable - band) / 2)^2)`; `proc_plan` fails when the scheduled attempts are
fewer than those trials times the 1.5 outcome margin; the model's `minimum_trials` is raised to the sizing. The judge
uses the pooled Wilson interval at that `z` (not the between-part interval), then the band rule, and appends
`residual_note`: confidence, trials, "a deviation of D points from the chance rejected with probability >= X" and the
per-pair false alert at the chance, from the normal approximation at the measured trials. Wilson coverage is nominal.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests: unset entries carry no residual model or rule text; a set and sized entry (by `min_parts`) models the
  confidence and the raised minimum trials; an under-sized entry fails with its attempt count; a missing band, a target
  outside (0, 1) or a shift inside the band is refused. Judge: the stated chance is ok and the row states the
  rejection; mutants off by the detectable shift (both sides) alert; too few trials are not judged.
- Witch Hunter `804192 proc_rate`: 0.001 per pair, `min_detectable` 5 points (10% of the stated 50%, twice the
  2.5-point band), 19386 trials, 29079 attempts, 110 parts of 266 attempts (60 parts before).
