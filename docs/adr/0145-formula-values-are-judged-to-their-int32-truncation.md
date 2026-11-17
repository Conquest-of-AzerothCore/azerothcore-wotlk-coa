# 0145. Rolled formula values are judged to their int32 truncation, with a known engine rounding

- Status: accepted
- Date: 2026-11-11
- Extends: ADR 0141 (percent-path stats) to damage and healing amounts read by `spell_effect_value`

## Context

`SpellEffectInfo::CalcValue` computes an effect's amount in float and returns `int32(value)` (SpellInfo.cpp:592), a
truncation toward zero. The roll judge of `effect_value` (`compare.judge_roll`) has always widened its 99% interval of
the mean by 1 toward zero for it, without naming the cause in the verdict. Force of Golganneth 500694, clause 68,
"Explode with holy power, dealing ${$803153m1+$803153ppl1+$AP*0.25+$sph*.25} Holy damage", read 388 against the
per-roll range 388.25 to 390.25 (`rounding/after/f2-r1`); `lean/rounding-tool.md` left it to the owner, because the
stat rule of ADR 0141 excludes damage.

The owner ruled (`owner-rulings-2026-11-10.md`, "Integer truncation of formula values", 2026-11-11): int32 truncation of
a fractional formula value is accepted as known engine rounding for damage and healing amounts when the reading is at
most 1 below the tooltip range, toward zero, and the engine's computation reproduces it (the formula value, then the
int32 truncation); the verdict carries the computed value. Anything else stays a deviation.

## Considered options

1. Name the rule in the explanation only. Rejected: a read one below that no formula value truncates to, or a read
   above the range, would keep passing through the interval of a single read.
2. Accept any read up to 1 below the range. Rejected: the ruling needs the truncation to reproduce the read.
3. Judge every read against the per-roll range; accept one below only where a per-roll value truncates to it. Chosen.

## Decision

- `compare.truncation_reads`: a read inside the per-roll range [min, max] is unchanged. A read at most 1 toward zero
  outside it is accepted when it equals `trunc(float32(value))` of a per-roll value; the verdict says "known engine
  rounding, int32 truncation: <value> truncates to <read>" and `detail['engine_rounding']` lists the values. Any
  other read outside the range is an `alert` ("a deviation").
- The interval of the mean, its widening and the tolerated tier are unchanged for reads inside the range.
- Not covered: fixed effect values (`deterministic`, `max(1, 0.5%)`), periodic and hit damage, which keep their rules.

## Consequences

- Clause 68 keeps `ok` with evidence 388.25 for its 388 reading; 389 and 390 readings are inside the range.
- Seeded tests in `test_compare.CompareTest`: 388.25 read as 388 (accepted, evidence), integer values read 1 below
  (rejected), a read 1 above the range (rejected), a read inside (no rounding named).
- On the round 10 results, 40 rolled verdicts now name the rounding, and four reads lie more than 1 below their range
  and become alerts when judged (801165 e1, 803792 e1, 804930 801546e0, 806834 e0; `lean/mech-batch-author.md`).
- The per-roll values are the tooltip reader's, in double, rounded to float only at the end; where the engine sums the
  terms in float in another order, a value near an integer may truncate differently.
