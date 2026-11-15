# 0029. Command: Skeletal Warriors doubles the weapon roll, not the flat part

- Status: accepted
- Date: 2026-11-13
- Split from ADR 0547 before publication (mentor ruling 2, 2026-11-13): this ADR keeps the class fix; the
  `minion_swing_ratio` fields its regression uses are
  [ADR 0547](../../0547-a-minion-strike-ratio-may-take-off-a-flat-part.md) (shared).

## Context

Fix note FN-c1t-1 (Command: Skeletal Warriors 570042 reads one swing where the live logs read about two) has its
regression stated by the controller: damage equals 2.0 times the Warrior's swing read plus the flat part of Effect[1]
computed from spell power, in the 5% band, with the plain swing as the control.

## Decision

- Fix FN-c1t-1 (b), approved by the controller: a Necromancer contract sets 570042 Effect[2] to
  SPELL_EFFECT_WEAPON_PERCENT_DAMAGE with BasePoints 199 (200%), one spell, the engine untouched
  (AscensionNecromancerContracts.cpp). The script-multiplier option (a) could not act:
  `Spell::SetScriptWeaponDamageMultiplier` refuses a spell without a WEAPON_PERCENT_DAMAGE effect
  (Spell.cpp:8737-8747). Effect[1] is SPELL_EFFECT_SCHOOL_DAMAGE, which `Spell::EffectWeaponDmg` does not collect as
  a weapon bonus, so the 200% doubles the weapon roll only and the flat part stays single, as the live fit (a flat
  21.2 next to 2.03 x the swing) shows. The NORMALIZED_WEAPON_DMG effect's own +1 goes with it.
- Regression entries (class file, `minion_swing_ratio` with `strike_flat` and `player_spell_power` of shared ADR
  0547): 504901 weapon_ratio expects 2.0 with `strike_flat` 1: Effect[1] BasePoints 0 + DieSides 1, plus 0.1365 x SP
  (AscensionNecromancerData.h:52) at the reference spell power 0. weapon_ratio_sp holds 1000 spell power, a flat part
  of 137.5, so a doubled flat part would read about 2.70 (swing about 197) instead of 2.0.

## Consequences

- 311.1 counts: pair 20261113-110216 / -110253 reads weapon_ratio 1.993 / 2.018 and weapon_ratio_sp 1.953 / 1.951
  (90 Commands per part, 3 and 2 parts pooled).
- Observation: the SP arm sits about 2.4% under 2.0 (99% interval about 1.91..1.99, which excludes 2.0, inside the
  band). Likely cause, NOT measured: the judge takes off the unmitigated 137.5 from an armor-reduced Physical hit.
  The judge is not changed (shared ADR 0547).
