# 1275. An effectiveness delta can read a resistance

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-24
- Builds on: ADR 0601, ADR 0671, ADR 1160

## Context

Pact Hunter 704612: "Increases the effectiveness of your Pacts by $s1%." (SPELLMOD_ALL_EFFECTS, +50%, on every
Pact's class mask). The effect of Vengeful Pact 803885 that a unit read shows is the Shadow resistance its area aura
gives party allies (aura 143, 65). Two Felsworn `metric_delta` entries read it, 65 without the talent and 97 with it,
but `resistance` is a state metric promised by `resistances?`, a word the claim lacks, so the audit counted the read
as data. `effectiveness_delta` promises its own state metric to the word "effectiveness", but did not read a
resistance. The mentor approved the new evidence rows (Felsworn ruling D-99), with the expected value
floor(65 x 1.5) = 97 and the tolerance 0.5 kept: the truncation of 97.5 is the known engine rounding.

## Decision

`effectiveness_delta` also reads `resistance` (with the `school` field, on the unit `measure_actor` names), stamped
as the state metric `effectiveness_resistance` with the promise word `effectiveness`.

## Consequences

Opt-in only; generated scenarios of classes 15, 19 (with and without `--stack`), 23 and 27 are byte-identical. The
Felsworn gains 704612 `pact_effectiveness`: a real Vengeful Pact cast in both phases, Pact Hunter learned between,
the ally's Shadow resistance 65 -> 97.
`test_effectiveness_delta.test_an_ally_resistance_is_judged_as_its_effectiveness_state` covers the read, the
judge, the promise and the mutant without the metric.
