# 1240. An aura 227 carrier amount is judged without its power term

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: mentor D-292 (Sun Cleric 27, Sunslam 805629 and ranks 807970-807974)

## Context

Sunslam's tooltip reads "dealing ${$m1+0+$AP*0.159426} Holy damage". Its effect 0 is aura 227
PERIODIC_TRIGGER_SPELL_WITH_VALUE: each tick `AuraEffect::HandlePeriodicTriggerSpellWithValueAuraTick`
(`SpellAuraEffects.cpp:6566`) casts 805639 with `SPELLVALUE_BASE_POINT0` set to the aura amount, and the attack power
term enters at 805639's CalcValue (`AscensionSunClericData.h:117`). The carrier's `effect_value` and `aura_amount`
read m1 (28 to 113); the value check expected the whole token, m1 + 11.16 at 70 attack power, and alerted on 12
labels while the hit labels that carry the term pass.

## Options

- Mark the 12 labels uncited: they claim nothing the ledger needs, but the carrier amount stays unproved.
- A class-file override per spell: repeats a rule that follows from the aura type.
- Judge a fixed-roll aura 227 carrier's `effect_value` and `aura_amount` on the token read with the power stats set
  to 0.

## Decision

`compare.judge_token` (`compare.py:913`) hands a fixed-roll `effect_value` or `aura_amount` whose effect has
`EffectApplyAuraName` 227 to `judge_trigger_with_value` (`compare.py:940`, defined at `:972`), which judges it
against the token read with attack, ranged attack and spell power at 0 (`unpowered`, as `base_roll_only` does). The
power term stays claimed on the triggered spell's hit labels. A token that reads differently without power alerts;
a token without a power term at the measured stats keeps its previous judgement and text. Rolled carriers
(`judge_roll`) and auras 231 / effect 133 are out of scope until a class needs them. Python only; generation is
unchanged.

## Consequences

- Tests in `test_compare.py`: the carrier judged on m1, the carrier holding the term alerts, the mutant judged on the
  full token alerts, another aura keeps the full token, a token without power term keeps its plain judgement.
- Finished classes: generation is byte-identical; the archived audits of Templar 19 and Necromancer 23 are
  byte-identical. Witch Hunter 15 carriers roll 17 die sides and do not reach the rule; Necromancer 23 carriers read
  0 spell power in their value scenarios, so the rule returns the previous verdict. The Templar label
  `527023 effect_value 527270e2 #1` stays `not_measured` (DoEffectCalcAmount hook); its read-alone sub-status can
  change at its next counted pair.
- Documented in `apps/coa-gameplay-test/conformance/docs/generate-and-compare.md` (deterministic values).
