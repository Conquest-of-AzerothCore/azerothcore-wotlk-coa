# 0243. Blade of Faith's ticks can critically strike

- Status: accepted
- Date: 2026-11-12
- Fix note: FN-r2b-2 (claim 363), approved by the mentor on the script route, with conditions
  (method-study/owner-rulings-2026-11-10.md, "Blade of Faith, claim 363, script route")

## Context

Blade of Faith's tooltip: "This ability can critically strike." Its ranks 803872-803880 have no direct-damage part:
Effect[0] is aura 3 (periodic damage), Effect[1] aura 271, Effect[2] none, and no script deals Blade damage. Stock
AuraEffect::CalcPeriodicCritChance (SpellAuraEffects.cpp:1180-1210) gives a periodic aura a crit chance only through a
SPELL_AURA_ABILITY_PERIODIC_CRIT (286) aura of the caster whose class mask names the spell (or Rupture). On build
861e0e1e6bee no tick crit: 0 of 13 at about 7045% crit chance (diagnostic 20261112-014720).

No carrier aura exists for the aura-286 pattern of AscensionVenomancerContracts.cpp:245-246:
- an aura-286 effect on the Blade ranks themselves reaches the caster too late: the DoT's crit chance is fixed when its
  aura effect is created (AuraEffect constructor, CalculatePeriodicData, SpellAuraEffects.cpp:446 and 663-676), and the
  enemy target is processed before the caster (Spell.cpp:2521, push_back order), so a first cast would never crit;
- the Templar class aura 887007 has SpellFamilyName 0, and SpellInfo::IsAffected matches every spell for family 0;
- Oath Chain 704576 is not held at every Blade cast;
- the always-learned Templar passives are stock (family 0), Resilient Constitution 552011 (family 3) and Sacred Strikes
  800518 (family 25, but a spec-4 row, AscensionCustomClassData.h:958); Blade is learned as an Ability with no passive
  rank.

## Decision

`templar_scaling::OnAuraApply` (UnitScript::OnAuraApply, UnitScript.h:125; called after the aura's effects exist, on a
new aura at Unit.cpp:5563 and on a refresh at Unit.cpp:5422) sets the crit chance of Effect[0] of an aura whose id is
one of 803872-803880, by explicit id. The chance is the aura-286 path's: `caster->SpellDoneCritChance(nullptr, info,
info->GetSchoolMask(), BASE_ATTACK, true)`, then, when above 0, `target->SpellTakenCritChance(caster, info,
info->GetSchoolMask(), chance, BASE_ATTACK, true)`, clamped at 0, set with `AuraEffect::SetCritChance`
(SpellAuraEffects.h:116). The multiplier is the engine's: the tick applies `Unit::SpellCriticalDamageBonus`
(SpellAuraEffects.cpp:6669), +100% for a melee-class spell (Blade's DmgClass is 2). 803154, another "Blade of Faith"
record sharing Blade's word-1 family bit, is not in the list.

## Consequences

- On build b617a5b10b67: the first Blade cast under forced melee crit gives 3 critical ticks of 3 (`crit`, all ticks
  `crit_ticks`); with Reduce Critical Strike Chance -100% 64481 and no crit rating, 0 of 3 (`crit_zero`,
  `crit_zero_ticks`). Information: the critical ticks' sum against the non-critical ticks' sum gives the multiplier
  recorded in the progress file (`crit_damage`, `crit_zero_damage`).
- The Blade tick-value scenarios (claim 364's four hit ratios) now set 64481 in both arms, forcing a 0 crit chance;
  side a's Focused 300524 `blade_of_faith` hit ratio needs the same at integration (noted for the integrator).
- The video tables show the tooltip sentence (dzhum7IIw9g 1:02, 2QVjZeKQauQ 0:46) and no crit reading; support only.

## Addendum (review fixes, 2026-11-12)

- 803880 in Spell.dbc: DmgClass 2 (SPELL_DAMAGE_CLASS_MELEE), SchoolMask 2 (Holy); the same for 803872-803879. The
  script passes the spell's own SpellInfo and school mask; the engine selects the class path: Unit::SpellDoneCritChance
  takes PLAYER_CRIT_PERCENTAGE for a melee-class spell (plus SPELL_AURA_MOD_SPELL_CRIT_CHANCE_SCHOOL for Holy), and
  Unit::SpellCriticalDamageBonus takes +100% for DmgClass melee. BASE_ATTACK is the attack type the stock aura-286 path
  passes for a non-ranged class (SpellAuraEffects.cpp:1192). The script chooses neither the chance nor the multiplier.
- Measured multiplier on build b617a5b10b67: 1146 / 573 = 2.000 (crit_damage against crit_zero_damage, beeg spellpen
  823764 in both), the +100% of DmgClass melee.
