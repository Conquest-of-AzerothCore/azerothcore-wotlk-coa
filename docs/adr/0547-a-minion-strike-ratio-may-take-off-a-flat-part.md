# 0547. A minion strike ratio may take off its flat part

- Status: accepted
- Date: 2026-11-13

## Context

Fix note FN-c1t-1 (Command: Skeletal Warriors 570042 reads one swing where the live logs read about two) has its
regression stated by the controller: damage equals 2.0 times the Warrior's swing read plus the flat part of Effect[1]
computed from spell power, in the 5% band, with the plain swing as the control. The `minion_swing_ratio` judge
(ADR 0541) compared the whole strike with the swing.

## Decision

- `minion_swing_ratio` takes `strike_flat`: that amount is taken off every strike hit before the per-hit mean is
  divided by the per-swing mean (model `treatment_flat`, applied by the hit ratio judge to the treatment totals only).
- 504901 weapon_ratio now expects 2.0 with `strike_flat` 1: Effect[1] BasePoints 0 + DieSides 1, plus 0.1365 x SP
  (AscensionNecromancerData.h:52) at the reference spell power 0.
- The approved server change for this regression, a `SetScriptWeaponDamageMultiplier(2.0f)` in the 570042 spell
  script, is not built: `Spell::SetScriptWeaponDamageMultiplier` refuses a spell without
  SPELL_EFFECT_WEAPON_PERCENT_DAMAGE (Spell.cpp:8737-8747), and the multiplier only scales that effect's percent
  (SpellEffects.cpp:4722 and the WEAPON_PERCENT_DAMAGE case below it); 570042 has none, so the call would change
  nothing. The change that acts is a contract turning 570042 Effect[2] into SPELL_EFFECT_WEAPON_PERCENT_DAMAGE 200;
  it waits for approval.
- Entries without `strike_flat` judge as before (Templar `generate --class 19` and `--stack` byte-identical).

## Consequences

- Until a change that acts is approved and built, weapon_ratio reads about 1.0 and alerts.
- Tests: `MinionSwingRatioTests` (test_behaviours.py) with the flat part.
