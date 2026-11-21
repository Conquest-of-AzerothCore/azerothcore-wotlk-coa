# 0732. A ring sum can judge the caster's maximum health

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claims 177.0 ("increases your health by 15% of the damage dealt") and 178.0 ("stacking $524669u
times.", Blade of the Misbegotten 680530) are judged by `ring_sum` (ADR 0725) on the 524669 aura amount, a readback:
the audit counts them as data. 524669 is aura 34 `SPELL_AURA_MOD_INCREASE_HEALTH`, so the same ring is observable
on the caster's maximum health, a state. The state promise of `max_health` is "maximum health", which neither clause
says. Gap design H1 (c13 gap designs), mentor ruling D-201.

## Options

- An opt-in `read: max_health` on `ring_sum`, with an evidence metric the option module declares itself, promised by
  `health|stack\w*`; `coverage` merges the option modules' rows as it merges the kind modules' rows.
- Widening the global `max_health` promise: it would move other classes' verdicts.
- A ledger `promise_of` (D-3): neither clause of 680530 says "maximum health".

## Decision

The opt-in read. The ring judge is unchanged; the model carries `evidence_metric: ring_sum_max_health`.
`metric_delta_options.option_rows` merges `METRIC_EVIDENCE` and `STATE_PROMISES` of the option modules into
`coverage.metric_evidence()` and `state_promises()`; an option row may not override a base row (registry test).

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`); no base coverage
  row changes, so archived verdicts audit the same.
- Seeded tests: the reads are the caster's `max_health`; the new metric is a state promised by "stacking" and
  "health", not by "for 8 sec"; the last three shares pass and the sum of four (the mutant that forgets the ring)
  alerts; a read that is not the caster's `max_health` is refused; no option row overrides a base row.
- Witch Hunter: `680530 behaviour_metric_delta ring_max_health`.
