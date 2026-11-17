# 0691. A spell crit read proves a crit claim with its learned contrast

- Status: proposed
- Date: 2026-11-15

## Context

`spell_done_crit_chance` reads the crit chance the server computes for a spell against the dummy
(`Unit::SpellDoneCritChance`). It is a readback metric, so a `behaviour_metric_delta` verdict on it counted as data
even when the read changed between a phase without the talent and a phase with it learned. Three Witch Hunter talents
state only a crit chance: One Shot 680331 ("Increases the critical strike chance of Heartseeking Bolt by $s1%."),
Bringing the Law 705500 (Shadowblast) and Secret Society 680514 (Shadow critical strike chance). Their final07
verdicts are ok with the learned contrast and stayed data.

`coverage.verdict_evidence` promotes a readback metric to behaviour only through `CONTRAST_PROOF`. Without a
`STATE_PROMISES` row that path accepts any clause words.

## Options

- A `CONTRAST_PROOF` row alone: a crit read would prove a damage or range clause of the same spell.
- A `CONTRAST_PROOF` row with a `STATE_PROMISES` row of the crit words, the pairing that
  `owned_creature_spell_crit_chance` already has.

## Decision

`CONTRAST_PROOF['spell_done_crit_chance']` is the learned contrast and `STATE_PROMISES['spell_done_crit_chance']` is
`CRIT_WORDS`. A state promise for a metric that is not a state metric is allowed only as the word gate of its
contrast proof; `test_every_state_metric_names_its_promise` checks that.

## Consequences

- Tests: `ContrastProofTest.test_a_spell_crit_read_proves_a_crit_chance_claim_only_with_the_learned_contrast`,
  `ContrastProofTest.test_a_spell_crit_read_does_not_prove_a_claim_that_does_not_promise_crit` and
  `test_a_promise_beyond_the_state_metrics_gates_a_contrast_proof` (test_coverage.py).
- Re-audit of the Necromancer final16 set (runs 20261114-084514 and -090752): identical before and after. The Templar
  has no archived single-build verdict set (ADR 0590). Re-audit of the Witch Hunter final07 pair: 680331, 680514 and
  705500 move from data to behaviour, nothing else changes.
- Generation is not touched: the finished classes' snapshot digests are unchanged.
- Number provisional: shared ADRs are numbered at merge.
