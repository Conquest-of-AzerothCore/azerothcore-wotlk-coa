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
- Fix FN-c1t-1 (b), approved by the controller: a Necromancer contract sets 570042 Effect[2] to
  SPELL_EFFECT_WEAPON_PERCENT_DAMAGE with BasePoints 199 (200%), one spell, the engine untouched
  (AscensionNecromancerContracts.cpp). The script-multiplier option (a) could not act:
  `Spell::SetScriptWeaponDamageMultiplier` refuses a spell without a WEAPON_PERCENT_DAMAGE effect
  (Spell.cpp:8737-8747). Effect[1] is SPELL_EFFECT_SCHOOL_DAMAGE, which `Spell::EffectWeaponDmg` does not collect as
  a weapon bonus, so the 200% doubles the weapon roll only and the flat part stays single, as the live fit (a flat
  21.2 next to 2.03 x the swing) shows. The NORMALIZED_WEAPON_DMG effect's own +1 goes with it.
- `minion_swing_ratio` takes `player_spell_power` (the harness spell-power fixture); weapon_ratio_sp holds 1000 spell
  power, a flat part of 137.5, so a doubled flat part would read about 2.70 (swing about 197) instead of 2.0.
- Entries without `strike_flat` judge as before (Templar `generate --class 19` and `--stack` byte-identical).

## Consequences

- 311.1 counts: pair 20261113-110216 / -110253 reads weapon_ratio 1.993 / 2.018 and weapon_ratio_sp 1.953 / 1.951
  (90 Commands per part, 3 and 2 parts pooled). The SP arm sits about 2.4% under 2.0; the judge takes off the
  unmitigated flat part of a Physical, armor-reduced hit, which explains part of that gap.
- Tests: `MinionSwingRatioTests` (test_behaviours.py) with the flat part.
