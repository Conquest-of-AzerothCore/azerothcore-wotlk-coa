# 0027. Hit models treat same-kind hit siblings as repeated events, not a combined total

- Status: accepted
- Date: 2026-11-08

## Context

`hit_kind` groups every effect index of one kind into a single `indexes` list before handing it to
`effect_hit` (ADR 0020). For Temple Guardian's live rank 803792, that list is `[1, 2]`: `Effect[1] = 10
(HEAL)` lands on the charged ally, `Effect[2] = 10 (HEAL)` lands on the caster, both sharing one tooltip
token (`matching_sibling`, ADR 0020). `effect_hit` summed the two indexes' rolls into one convolved
distribution, as if both effects were terms of a single combined event — `model.mean` became
`E[effect1] + E[effect2]`.

The harness does not log one combined event per cast: `Unit::SendHealSpellLog` fires once per healing
`SpellEffectInfo`, i.e. once per receiver. `hit_measurements` already sums both receivers' events into one
`total`/`count` (round 2's ally-targeting fix), so `compare.judge_hit`'s `mean = total / count` is a
per-event mean. Comparing that per-event mean against a per-cast, two-events-summed `model.mean` is off by a
factor of two, independent of server behaviour. Round 2's full run measured exactly this: `803792 hit_mean`
`measured: 439.75-441.0` against `expected: 882.8163`, `status: alert`, while round 2 had already confirmed
the server heals both receivers correctly. ADR 0020's own text says a token-less sibling should "roll in its
place" / "share the first's expected value" — not be added to it; the summing in `effect_hit` was an
implementation bug relative to the ADR that authorized `matching_sibling`, not a documented design.

## Considered options

1. Leave `effect_hit` summing and fix the comparison side (e.g. divide `model.mean` by `len(indexes)` at the
   call site). Rejected: `model.mean` would stop meaning "the expected value of one hit of this kind",
   breaking every other consumer of `HitModel.mean` (mitigation, modifiers, `casts_needed`) for a kind that
   happens to have several indexes.
2. Hardcode a Temple-Guardian-specific divisor. Rejected: `hits.py` is class-agnostic; the shape (`hit_kind`
   grouping more than one index under the same kind) is generic, and a hardcoded fix would not catch the next
   class whose tooltip repeats it.
3. Model each index as an independent per-cast event: mix (equally-weighted average) the per-index
   distributions instead of summing them, and scale `hits_per_cast` by the index count. Chosen.

## Decision

- `effect_hit` builds a list of per-index distributions and tooltip means instead of a running
  sum/accumulator, and combines them with a new `mixed()` function: an equally-weighted mixture (average),
  never a convolution. For every existing single-index caller (every spell but Temple Guardian),
  `len(indexes) == 1` and `mixed([d]) == d`, byte-identical to the previous output.
- `expected_hit` computes `events = len(indexes)` in the non-weapon, non-ticking branch and uses it as
  `HitModel.hits_per_cast` (the same field periodic ticks already use for the same purpose). `model_record`'s
  `minimum_hits = needed * hits_per_cast` and `casts_needed`'s division by `hits_per_cast` already consume
  this field generically, so no other function changes.
- `hit_measurements`, `hit_kind`, and round 2's ally-targeting scenario fix are unchanged: the measurement
  side was already correct; only the model side was wrong.

## Consequences

- Temple Guardian's `803792 hit_mean` now compares a per-event `model.mean` (one receiver's heal) against the
  harness's per-event measured mean, instead of a doubled model mean against a single-event measurement.
- `minimum_hits` doubles for any kind with two same-kind indexes, so a regression that drops one receiver
  (e.g. the ally-targeting fix regressing) is caught by `insufficient_trials` even though both receivers'
  single-event means are numerically identical and would not move a mean-only check.
- Generic: any future class spell whose `hit_kind` grouping has more than one index benefits without a
  further code change, and no class-specific code was added to `hits.py`.
