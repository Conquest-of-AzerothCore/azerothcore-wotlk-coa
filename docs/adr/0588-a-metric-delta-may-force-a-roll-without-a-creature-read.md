# 0588. A metric delta may force a roll without a creature read

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0482, ADR 0545, ADR 0582

## Context

The effect claims after a landed proc (cluster A of the c4 route designs, gap T1) need the proc's roll forced inside a
`metric_delta`. `forced_chance` (ADR 0482) forces it but also requires the rolled aura on an owned creature before
both readings, which a caster buff or an instant cast never has; `forced_roll` existed only in `cost_gate` (ADR 0545).

## Options

1. Make the creature read of `forced_chance` optional (a change of a `MetricDeltaSpec` field and its judge).
2. A `metric_delta` option module `forced_roll` (ADR 0582) with a model point.

## Decision

Option 2. `metric_delta_options/forced_roll.py` inserts the `SPELLMOD_CHANCE_OF_SUCCESS` +1000% mutant on the talent
right after the base steps, removes it at the end and reads `spell_mod_mutants`. A third named point,
`metric_delta_options.option_model(spec)`, merges `{'forced_roll': {talent, released_label}}` into the expectation
model; `compare.forced_roll_metric_delta_verdict` judges the metric delta and alerts when the mutant is still active.
`forced_roll` and `forced_chance` together are refused.

## Consequences

- Death Commander 300235: the caster's and the minion's haste after a landed proc (claim 6.1; with `forced_chance`
  the presence read counted 301334 on 0 of 2 Ghouls although the Ghoul's haste reads 0.8333, cause not traced);
  Bone King 707175: the instant Lichfrost (claim 208.1).
- A roll that must stop before a consuming cast (185.1, 167.1: every cast re-rolls under the mutant) needs a release
  point inside a phase; that is not part of this option.
