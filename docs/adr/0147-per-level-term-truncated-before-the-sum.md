# 0147. The per-level term truncated before the sum is a known engine rounding

- Status: accepted
- Date: 2026-11-11
- Extends: ADR 0141 (percent-path stats) and ADR 0145 (int32 truncation of rolled formula values)

## Context

Stock `SpellEffectInfo::CalcValue` adds `int32(level * RealPointsPerLevel)` to the base points (SpellInfo.cpp:497),
before the roll, the CoA hook and the final `int32(value)` (SpellInfo.cpp:592). The client tooltip keeps the
per-level term continuous. Four Templar reads in round 10 run 2 lie more than 1 below their formula range under the
ADR 0145 judge, and the triage (`lean/low-reads-triage.md`) traces all four to that early truncation:
- Temple Guardian 801165 e1, 8.68 to 8;
- Temple Guardian 803792 e1, 11.55 to 11;
- Armor of Faith 804930 via 801546 e0, 40.6 to 40;
- Titanstrike 806834 e0, 16.98 to 16.

The owner ruled option (a) (`owner-rulings-2026-11-10.md`, "Per-level truncation", 2026-11-11): this is the third
known engine rounding, for all 21 classes, with no server change. A read is ok only when the full engine
computation reproduces it exactly, and the verdict carries the computed value or range. No flat "1 below" band
applies. Where the tool cannot yet model the computation, the read stays an alert labelled "per-level truncation,
engine computation not modelled". A mutant of the same size that the computation does not explain still alerts.

## Considered options

1. Widen the roll judge by up to 2 below. Rejected: a flat band, which the ruling excludes.
2. Model the per-level truncation in the tooltip reader. Rejected: the tooltip is the client's continuous text; the
   expectation must stay the tooltip, and the engine model only explains reads that leave it.
3. Keep the tooltip expectation. Accept reads outside the range only when the engine model reproduces every read,
   and judge them around the engine mean. Chosen.

## Decision

- `compare.per_level_loss` computes the engine's term from Spell.dbc as `SpellInfo.cpp:485-497` does: the caster
  level clamped to MaxLevel (when set) or raised to BaseLevel, less `max(BaseLevel, SpellLevel)`, times the float32
  rate. It keeps the truncation and the lost fraction.
- `compare.judge_roll`: if some read lies outside the per-roll range and every read is
  `trunc(float32(value - loss))` of a per-roll value, and that loss changes the integer set the rolls give (a
  loss below the fraction of the per-roll minimum leaves the set unchanged and ADR 0145 names it), the verdict is judged
  around the engine mean (the 99% interval
  half-width as before, no widening). The explanation names "known engine rounding, per-level term truncated before
  the sum (SpellInfo.cpp:497)". `detail['per_level_rounding']` holds `per_level`, `truncated_to`, `loss`,
  `engine_range` and `engine_mean`. Otherwise ADR 0145 applies unchanged; a read the engine model does not explain is
  an alert, and the explanation states which reads the model reproduces.
- The model has no `ApplyEffectModifiers` factor: the tooltip expectation has none either, and the reference
  character's value scenarios carry no effect modifier.
- Hits, melee means and periodic totals (`HIT_CHECKS`) do not model the computation (damage multipliers, weapon
  flat bonuses, tick counts). An alert of such a check on a rank with a fractional per-level loss carries
  `detail['per_level_rounding']` "per-level truncation, engine computation not modelled". It never becomes `ok`.

## Consequences

- The four low reads are `ok` as known engine rounding with their engine ranges: 801165 e1 361-367, 803792 e1
  548-554, 801546 e0 268-271, 806834 e0 583-711 (`lean/mech-batch-author.md`).
- Seeded tests in `test_compare.CompareTest`: Temple Guardian's 20 reads with 8.68 truncated to 8 (accepted); the
  same reads with an integer per-level term, and with a read of 360, both rejected; the hit label and its absence on
  an ok verdict or a rank without a loss.
- Ranks whose loss the server credits back (ADR 0045's list) read inside the range and do not take this path; their
  removal is a separate server change.
- The clamp follows the stock code. A CoA hook that changes the level, or an effect modifier, is outside the model.
