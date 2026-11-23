# 1238. A rank hit mean models the per-level truncation

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: mentor D-288 (Sun Cleric 27, Dawnbreak 504580 hit_mean)
- Amends: ADR 0147, its bullet on `HIT_CHECKS`, for the `hit_mean` of a rank hit

## Context

Stock `SpellEffectInfo::CalcValue` truncates `level x EffectRealPointsPerLevel` before the sum (SpellInfo.cpp:497).
ADR 0147 left every hit check unmodelled for that truncation: an alert on such a rank carries "per-level
truncation, engine computation not modelled". A script hit (`hits.script_hit_model`) already carries an engine
variant (`HitModel.engine`, `engine_rule`), and `compare.judged_hit` consults it when the tooltip model is not `ok`.
A rank hit (`hits.rank_hit`, the default `hit_mean` path) had none, so Dawnbreak 504580 (effect 0: 2 levels x
1.34444 = 2.68888, truncated to 2) kept the "not modelled" label in pair 13.

## Considered options

1. Exclude the effect from the hit judge. Rejected: the computation can be modelled from Spell.dbc.
2. Give `rank_hit` the engine variant of `script_hit_model`. Chosen.

## Decision

- `rank_hit` computes `hits.per_level_fraction` (Spell.dbc, stock level clamp) for each hit effect of a `school` or
  `heal` kind. With a loss, it builds the engine model from the same rolls less the loss (`engine_rolls`), so each
  value is `floor(base + trunc(term) + roll + bonus)`, and sets `engine` and `engine_rule`.
- The tooltip model (mean, sigma, `minimum_hits`) is unchanged: generation does not move.
- When the engine model cannot be built (`engine_rolls` raises `Unmodelled`, as for Temple Guardian 803792, whose
  heal reads a sibling effect's token), the rank keeps its model without an engine variant, as before.
- Periodic, weapon and triggered-weapon kinds keep ADR 0147's label.

## Consequences

- A rank hit whose mean leaves the tooltip model is `ok` only inside the engine model's 99% interval; otherwise its
  alert names the engine mean and "does not explain it either", and no longer the "not modelled" label.
- Where the floor of each tooltip value already drops the lost fraction, the engine mean equals the tooltip model's
  (Dawnbreak 504580: 203.188 both); only the label changes.
- Finished classes, re-judged on their archived pairs: Templar 572741 and 807805 `ok` (the engine is not consulted),
  Witch Hunter 680273 `insufficient_trials`, Necromancer no rank with a loss. No verdict changes.
- Seeded test `test_hits.HitScenarioTest.test_a_rank_hit_with_a_truncated_per_level_term_is_ok_only_around_the_engine_mean`
  (Reckoning 572741, loss 0.5072): the engine mean is `ok`, a 6% lower mutant alerts.
