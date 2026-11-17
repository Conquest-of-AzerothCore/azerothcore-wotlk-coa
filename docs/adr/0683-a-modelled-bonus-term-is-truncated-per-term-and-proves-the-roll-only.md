# 0683. A modelled spell_bonus_data term is truncated per term and proves the roll only

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15
- Builds on: ADR 0679, ADR 0145 (G-27)

## Context

ADR 0679 adds the `spell_bonus_data` terms to each `spell_effect_value` read of a rolled effect. The terms were added
untruncated, while the verdict text said the engine truncates each term to int32. `Unit::SpellDamageBonusDone`
adds the AP term as `int32(apCoeff * stack * ApCoeffMod * APbonus)` (`Unit.cpp:9885`) and the SP term as
`int32(DoneAdvertisedBenefit * coeff * factorMod)` after `coeff *= 100.0f`, the `SPELLMOD_BONUS_MULTIPLIER` spell mod
and `coeff /= 100.0f` (`Unit.cpp:9909-9914`), so the engine amount is the roll plus two separately truncated terms and
can lie up to 2 below the tooltip formula (review I-1, mentor D-57 O-7). The terms are never observed: the read is the
CalcValue roll only.

## Options

- Keep the untruncated terms: the verdict reports an engine reproduction that did not happen.
- Send every read with a term to `not_measured`: loses the measured roll.
- Model each term in float32 and truncate it to int32 as the engine does, accept the truncation per term (G-27
  extension), and count the claim only with a hit-based label.

## Decision

- `bonus_data.engine_ap_term` and `engine_sp_term` compute each term in float32 and truncate it toward zero.
  `BonusTerms` keeps both the formula value and the int32 term, and counts the terms that lose a fraction
  (`truncated`).
- `compare.judge_roll` widens the band and the below-range allowance by 1 per truncated term, on top of the 1 of the
  CalcValue truncation (G-27 extension, mentor D-57, 2026-11-15). The explanation shows each term, its formula value,
  its int32 value and its `Unit.cpp` line, and says "CalcValue observed; terms modelled from spell_bonus_data, not
  observed".
- Proof condition (G-27 extension): a modelled `effect_value` proves the base roll only. A claim whose stated value
  includes an AP or SP term also lists a hit-based label of the same claim (`hit_mean` or an equivalent hit entry, with
  a spell power arm where the claim states a spell power term). The Witch Hunter ledger lists `503662 hit_mean` and
  `805365 hit_mean` beside their modelled reads; Fiery Judgement 803369 already counts on its hit entries.

## Consequences

- Seeded tests: `test_bonus_data.py` (each term truncated, the formula values and the `Unit.cpp` lines in the text,
  an integral term not counted, a negative term truncated toward zero) and `test_compare.py` (reads at the engine
  value ok with the explanation, a mutant 2 below the bare roll alerts, 1 below stays ok).
- Templar (19) and Necromancer (23) generate byte-identical scenarios: the change is in the judge, and none of their
  `effect_value` owners has a non-zero row (ADR 0679).
- Not enforced by a tool: a ledger claim that holds only a modelled read. The shared check would be in
  `coverage.claim_evidence`: a claim whose matched verdicts carry `bonus_data` detail counts only when another matched
  label of a hit check is conformant, and one with a spell power coefficient only when a hit label ran at a non-zero
  spell power. Torchlight 503662 has no spell power arm yet, so its claim must not be counted on `503662 hit_mean`
  alone.
