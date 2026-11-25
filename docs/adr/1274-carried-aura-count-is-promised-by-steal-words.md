# 1274. carried_aura_count is promised by steal words

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-24
- Builds on: ADR 1029 (rows for rooted and carried_aura_count)

## Context

Magic Fiend 704613: "Increases the amount of beneficial magic effects stolen by your Consume Magic by $s1." The
Felsworn entry `704613 behaviour_metric_delta stolen_effects` makes a real Consume Magic 800353 cast at a dummy holding
three beneficial Magic buffs and reads `carried_aura_count` of those buffs on the caster: 1 without the talent (the
control) and 2 with it learned between the phases, so an over-steal (3) fails. `carried_aura_count` is a state metric
whose only promise words were `empower\w*` (ADR 1029), so the audit counted this read as data. The mentor approved
steal words for this metric only (Felsworn ruling D-91, item 2), with the real cast and the no-talent control reading
one fewer.

## Considered options

- A `STATE_PROMISES` row in an option or kind module: refused by the cross-class guard, since `carried_aura_count`
  already has a base row and `KIND_ROW_OVERRIDES` is empty.
- Widen the base row of `carried_aura_count` to `empower\w*|steal(?:s|ing)?|stolen`, without `steal\w*`, so
  "stealth" does not promise it.

## Decision

The second option. Only `carried_aura_count` gains the words; no other metric, judge, tolerance or evidence class
changes, and the promise still needs a learned or own-cast contrast (`coverage.promised_state`).

## Consequences

Across every class ledger, only Felsworn 704613 has a clause (or `promise_of` source) with the new words, so no
finished-class count moves; generation does not read the row, so no snapshot digest moves.
`test_coverage.test_a_carried_aura_count_is_promised_by_a_steal` covers the words, "stealth", the missing contrast,
another metric and the mutant row without the words.
