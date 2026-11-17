# 0746. A ranged crit read proves a crit claim with its learned contrast

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter Slayer 300968 states "Increases your critical strike chance by $s2%" (Effect[1], aura 350, EffectMiscValue
127, every school). The ranged part of the claim reads `ranged_taken_crit_chance`, the player's
`GetUnitCriticalChance(RANGED_ATTACK, target)` (`CoAGameplayTest.cpp`): the own field `PLAYER_RANGED_CRIT_PERCENTAGE`
plus the target-side aura terms. The metric had no row in `coverage.py`, so the cross-class guard of the source stage
refused the entry (cycle 14 crit report: 3 failures, unstamped label `300968 behaviour_metric_delta personal_ranged`)
and the part was parked on `feat/coa-witch-hunter-c14-crit-ranged`.

## Options

- A readback row, next to `spell_done_crit_chance`: the read depends on the target, so a change between two phases
  would count as data without a contrast.
- A state row like `melee_crit_chance` with no contrast proof: any unconditioned delta of the metric would prove a
  crit claim.
- A state row, the crit words as promise, and the learned contrast as proof: the delta must come from learning the
  talent, on the same target in both arms.

## Decision

`METRIC_EVIDENCE['ranged_taken_crit_chance']` is `STATE`, `STATE_PROMISES['ranged_taken_crit_chance']` is
`CRIT_WORDS`, `CONTRAST_PROOF['ranged_taken_crit_chance']` is `LEARNED_CONTRAST`. Row text: own field + target-side
terms, contrast on the same target. An entry that uses the metric states in its evidence row that the target carries no
aura applied by the caster in either arm, so a delta cannot come from a target-side term.

## Consequences

- Tests (test_coverage.py): `ContrastProofTest.test_a_ranged_crit_read_is_a_state_that_proves_a_crit_chance_claim_only_with_the_learned_contrast`
  and `ContrastProofTest.test_a_ranged_crit_read_does_not_prove_a_claim_that_does_not_promise_crit`; the state/promise
  consistency tests cover the new row.
- Generation is not touched: the Templar and Necromancer snapshot digests are unchanged (`snapshots.py check`).
- Witch Hunter: `300968 behaviour_metric_delta personal_ranged` becomes a counted label of claim 24.
- Number provisional: shared ADRs are numbered at merge.
