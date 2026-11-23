# 1193. A critical block chance read proves its claim with the partner arms

- Status: proposed
- Date: 2026-11-22
- Related: [ADR 1188](1188-a-scripted-crit-read-proves-a-crit-claim-with-its-partner-arms.md) (the partner gate),
  [ADR 0691](0691-a-spell-crit-read-proves-a-crit-claim-with-its-learned-contrast.md) (the learned contrast).
- Decided by: mentor D-117 (option C).

## Context

Sun Cleric Sun Strider 680641 says "Consuming the stacks increases your critical block chance and movement speed by
$524859s1%". 524859 Effect[1] is aura 253 `SPELL_AURA_MOD_BLOCK_CRIT_CHANCE`, BasePoints 9 + 1 = 10. The harness already
serves `critical_block_chance` (`CoAGameplayTest.cpp:5139-5140`,
`player->GetTotalAuraModifier(SPELL_AURA_MOD_BLOCK_CRIT_CHANCE)`; first used by #4270 and `starcaller-enchanted-aegis`),
and the engine rolls on exactly that sum (`Unit::isBlockCritical`, `Unit.cpp:3719-3723`), but `coverage.METRIC_EVIDENCE`
has no row for it, so a class file entry that reads it fails the cross-class guard (ADR 0120).

## Options

- STATE, like `block_chance`: a unit property that every consumer reads. Rejected: the value is not a computed unit
  field; it is the aura total, and a server that stores the right amount but never rolls on it would pass.
- READBACK without a contrast row: the read stays data. Safe, but the claim could never reach behaviour.
- READBACK with the learned contrast, the words and the partner gate of ADR 1188.

## Decision

The third option.

- `METRIC_EVIDENCE['critical_block_chance'] = READBACK`, `STATE_PROMISES['critical_block_chance'] = 'critical block'`,
  `CONTRAST_PROOF['critical_block_chance'] = LEARNED_CONTRAST`, and the metric joins `PARTNERED_CONTRASTS`.
- A learned verdict of it counts as behaviour only when the ledger row's conformant learned verdicts of the metric hold
  a non-zero expected gain (the effect arm) and, because the clause is conditional, a zero gain (the condition-off arm:
  here a Gavel that cannot crit, so no stack is consumed). `conditional_text` only recognises plain crit-strike
  sentences, so a critical block clause always asks for the zero arm.
- The review checks that the zero arm's fixture breaks the condition.

## Consequences

- Tests: `test_coverage.py` `CriticalBlockChancePartnerTest` (both arms, one arm, zero arm alone, condition contrast,
  a clause that does not promise critical block, a partner of another metric) with two mutants (gate removed, row
  removed).
- Templar, Necromancer and Witch Hunter use no entry of the metric; their audit is unchanged (checked before and after).
- Number provisional: shared ADRs are numbered at merge.
