# 0002. Night King's bonus applies once, through Shadow Brand

- Status: accepted
- Date: 2026-11-15

## Context

Night King 707067 states "Noctis Blade now consumes Shadow Brand to deal $s1% increased damage." ($s1 = 50). The
bonus reached the hit twice:

- natively: 707067 Effect[0] (aura 107 SPELL_AURA_ADD_FLAT_MODIFIER, SPELLMOD_EFFECT1, class mask (0, 0x10000000, 0),
  Shadow Brand 680517's SpellFamilyFlags[1]) adds 50 to 680517 Effect[0] (aura 271 SPELL_AURA_MOD_DAMAGE_FROM_CASTER,
  class mask (0, 64, 0), Noctis Blade), so a Branded target takes +50% from the caster's Noctis Blade;
- in the class script: `OnSpellCalculatedTarget` in `AscensionWitchHunterAbilities.cpp` multiplied a Noctis Blade hit
  on a Branded target by a literal 1.5 when the caster held 707067.

The c7 Black Knight pair read `707067 behaviour_hit_ratio noctis_blade` 2.2463 / 2.2478 (1.5 x 1.5). The mentor
approved the fix note (D-83, D-89); no owner ruling was needed: the tooltip states one bonus and `$s1` is the native
effect's points.

## Options

- Remove the script's x1.5 and keep the native effect.
- Neutralise 707067 Effect[0] at load, as for Wide Swings 681098, and keep the script's hit-time x1.5.

## Decision

Remove the script's x1.5. The description's `$s1` is 707067 Effect[0], whose native result is the stated bonus; the
script's 1.5 is tied to no DBC field. The consume after a dealing Noctis Blade hit
(`RemoveAurasDueToSpell(680517, ...)` in the same file) stays: it is the "consumes" clause, which no DBC effect does.

## Consequences

- Regressions, counted pair 20261115-151706 / 20261115-151912 (worldserver eed3753e97e3, built from the fix):
  `707067 behaviour_hit_ratio noctis_blade` ok 1.4979 / 1.5011 (was 2.246 / 2.248); `noctis_blade_no_brand` ok
  1.0010 / 1.0013; `consumes_brand` ok; `707067 effect_value e0 #0` ok 50 / 50. Neighbours on the same hook: Wide
  Swings `681098 behaviour_hit_ratio noctis_blade` ok 1.2037 / 1.1917, Guardbreaker
  `681493 behaviour_hit_ratio noctis_blade_control` ok 0.9969 / 1.0004, `680615 effect_value e0 #1` ok 264.2 / 266.0.
- Behaviour difference, recorded as an observation and not a claim: the native bonus is fixed in the Brand's amount
  when the Brand is applied, so a Brand applied before Night King is learned keeps +0% until it is applied again (the
  passive recalculation of SPELLMOD_EFFECT1 in `SpellAuraEffects.cpp` covers only passive or permanent auras). The
  entries `707067 behaviour_metric_delta brand_before_learn` (the Brand's Effect[0] amount, 0 before and 0 after the
  learn) and `brand_before_learn_held` (the Brand still present, 1 and 1) read it, ok in both runs of the pair; they use
  the `metric_delta` option `before_auras` (ADR 0690).
- Gameplay change: Night King's Noctis Blade hit on a Branded target drops from x2.25 to the stated x1.5. Witch Hunter
  code only.
