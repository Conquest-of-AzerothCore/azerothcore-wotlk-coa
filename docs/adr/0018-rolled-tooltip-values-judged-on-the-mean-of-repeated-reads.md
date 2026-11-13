# 0018. Rolled tooltip values are judged on the mean of repeated reads

- Status: accepted
- Date: 2026-11-06
- Supersedes, for no-combat `effect_value` and `aura_amount` checks: the rolled-effect rule of
  [ADR 0011](0011-class-tooltip-conformance.md) ("judged against the range of the token over every roll")

## Context

A rolled effect (`EffectDieSides` neither 0 nor 1) adds one `irand` roll to its points in every
`SpellEffectInfo::CalcValue` call, and `spell_effect_value` returns one such call. ADR 0011 judged that single read
against the range of the token over every roll, each bound widened by the deterministic tolerance.

[ADR 0014](0014-level-scaled-tooltip-values-use-the-skill-rank.md) made level-scaled tokens readable. The client
reading omits a per-level part that the server adds (`SpellInfo.cpp:492`). A constant server offset smaller than the
roll range therefore passes on most rolls. The phase-2 Templar run of 2026-11-06 (stamp 20261106-162551) gave `ok` for
Reckoning 572741, 748507 and 805421 and for Vindication 501589, 501590 and 501592, while their sibling ranks with the
same cause were alerts, the Reckoning hit mean alerted on the same quantity, and two identical runs swapped `ok` and
`alert` on these ranks. A false `ok` is the outcome the method must never give.

## Considered options

1. Keep one read and report every rolled check of a level-scaled effect as `measured`. Rejected: it gives up every
   rolled check, including the correct ones, and the cause (a single roll) applies to any constant offset.
2. Read the value k times and require every read inside the range and the extremes to reach it. Rejected: k depends
   on the smallest offset worth catching, which nothing gives.
3. Read the value k times and judge the mean with the hit-mean rule of ADR 0011. Chosen: the reads are no-combat
   queries, so k reads cost k assertion steps, and the rule is the one hit means already use.

## Decision

- D1. A rolled own or foreign `effect_value` is read k times in its value scenario (`<label>` and `<label> sample
  <n>`). k = `ceil((2.576 x sigma / (0.01 x |mean|))^2)`, with the mean and the population sigma of the token read
  once per roll at the structure stats. The rolls are equally likely, so these are the moments of a uniform roll.
- D2. The mean of the reads must lie in expected mean ± 2.576 x sigma / sqrt(n), with the moments re-read at the
  measured stats. The interval is widened by 1 toward zero, because `CalcValue` returns `int32(value)`
  (`SpellInfo.cpp:587`) and the truncation lowers each read of a positive value by less than 1.
- D3. When the copies do not fit in the scenario's budget, the effect is read once. The budget is the harness's
  10000-step limit (`run.py` `validate`) and 1800 reads (45 s at 25 ms, the largest step of the simulated clock, half
  the 90 s default timeout). The verdict is `measured` when fewer reads than the measured stats need exist, and when
  the mean is 0.
- D4. A rolled `aura_amount` is read once, after the one cast of the scenario, so it is `measured` unless one read is
  enough.

## Consequences

- The six `ok` verdicts above become judgements of the mean. A per-level part of the server shifts the mean by the
  whole offset and is an alert when it exceeds the half-width plus 1 (the regression test: an offset of half the roll
  spread alerts at the computed k).
- A value scenario holds up to about 1800 more assertion steps (Templar: 51 rolled tokens, 2 to 1716 reads).
- `detail` of a rolled verdict gains `reads` and `reads_needed`; `roll_spread` stays for `diff`, which is coarser than
  the interval of a mean but never turns a verdict into `ok`.
- A passive delta on a rolled target still compares two single reads (not changed here).
