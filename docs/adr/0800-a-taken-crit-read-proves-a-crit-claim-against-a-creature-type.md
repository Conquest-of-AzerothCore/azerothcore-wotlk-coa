# 0800. A taken crit read proves a crit claim against a creature type

- Status: proposed
- Date: 2026-11-16

## Context

Witching Bolt 680322: "Increases the critical strike chance of Damnation against Undead and Demons by $s1%." ($s1 =
25). Its aura 112 (EffectMiscValue 20008) becomes a creature-masked crit rule (`AscensionConditionalCombatData.h:66`,
condition 36 = Demon 4 + Undead 32) that `Unit::SpellTakenCritChance` adds on the target side
(`Unit.cpp:10560-10562`). `spell_done_crit_chance` does not see it. The harness already reads
`spell_taken_crit_chance` (`CoAGameplayTest.cpp:5268-5282`: the caster's done chance, then the target's taken chance),
but the metric had no `METRIC_EVIDENCE` row, so no entry could use it. A hit-count judge would need about 8,000
Damnations per arm for the 2-point band.

## Options

- A crit-rate count of real Damnation hits: thousands of casts per arm, and Damnation is gated below 35% health.
- The existing state read with the rows `spell_done_crit_chance` has (ADR 0691): `READBACK`, the crit words as the
  gate of its learned contrast proof.

## Decision

`METRIC_EVIDENCE['spell_taken_crit_chance']` is `READBACK`, `STATE_PROMISES['spell_taken_crit_chance']` is
`CRIT_WORDS` and `CONTRAST_PROOF['spell_taken_crit_chance']` is the learned contrast, the same three rows as
`spell_done_crit_chance`. No harness or generation code changes.

## Consequences

- Witch Hunter entries `680322 behaviour_metric_delta undead`, `demon`, `humanoid` and `other_spell`: the read of
  Damnation 520217 at creature entries 201 (Undead), 416 (Demon) and 6 (Humanoid, gain 0), and of Dusk Blade 802258
  (outside the class mask, gain 0) at entry 201, before and after 680322 is learned, with `crit_field_refresh`.
- Tests (test_coverage.py):
  `ContrastProofTest.test_a_taken_crit_read_proves_a_crit_chance_claim_only_with_the_learned_contrast`,
  `test_a_taken_crit_read_does_not_prove_a_claim_that_does_not_promise_crit`,
  `EvidenceTablesTest.test_the_witch_hunter_taken_crit_read_without_its_evidence_row_is_found` (mutant: the row
  removed), `WitchingBoltTakenCritTest` (the arms, and a judge mutant: a rule that ignores the creature type or the
  class mask alerts).
- The read proves the chance the server would use, not a rolled crit; the clause states a chance.
- Generation of other classes is untouched: the Templar and Necromancer digests are unchanged.
- Number provisional: shared ADRs are numbered at merge.
