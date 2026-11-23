# 0018. Annihilan Strike is a guaranteed critical strike above 75% health

- Status: accepted (Felsworn mentor decision D-72, 2026-11-23)
- Date: 2026-11-23

## Context

Annihilan Strike, every rank (560759 to 560762, 572803, 572804, 801903), server Spell.dbc Description[enUS]:
"Unleash a devastating attack, dealing $s2% Weapon Damage to your target with both weapons. This ability is
guaranteed to critically strike against enemies above 75% health." Each rank's Effect[0] and Effect[1]
(`SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE`) trigger the main-hand strike 801913 and the off-hand strike 801914
(`SPELL_EFFECT_WEAPON_PERCENT_DAMAGE`, `SPELL_DAMAGE_CLASS_MELEE`), whose own descriptions carry the same sentence.
No talent grants the clause, and no aura, state or script handled 572804, 801913 or 801914.

Measured before the fix (Felsworn A-3 pair): 0 critical 801913 strikes of 288 at 90% target health in both runs,
while a forced critical rating read 288 of 288, so critical strikes of 801913 are counted by the read.

## Decision

`felsworn_casts::OnSpellCalculatedTarget` (`AscensionFelswornAbilities.cpp`) sets `hit.crit` on a landed 801913 or
801914 strike of a Felsworn caster when the target's health is strictly above 75% (`Unit::HealthAbovePct(75)`), the
strike is crit capable and has no `SPELL_ATTR2_CANT_CRIT`. The hook runs per target in
`Spell::DoAllEffectOnLaunchTarget`, right after the native roll, so the health is read when each strike resolves and
not at the cast start.

Precedent: the Runemaster sets `hit.crit` in the same hook for Fracture against a frozen target
(`AscensionRunemasterTalentEffects.cpp:128-136`). A `chance = 100` in `OnSpellCritChance` (Sun Cleric,
`AscensionSunClericAbilities.cpp:224-233`) was not used: `Unit::SpellTakenCritChance` still adds the victim's
defence and resilience terms after that hook, so the strike would not be guaranteed.

## Consequences

- Above 75% health every Annihilan Strike strike is critical; at exactly 75% and below, the normal roll applies.
- Keyed to the two strike ids, so every rank is covered; no other class, fixture or script names 801913 or 801914.
  No engine, SQL, DBC or client text change. A charge of 803904 is still spent by the strike as before.
- Procs that read these crits fire more often above 75%: Twin Fury 801892 (one more Felfury per critical Annihilan
  strike), and the generic critical-strike procs Dancing Blades 92087, Chaotic 574143, Oblivion 572889, Malice of
  Gul'dan 800214, Sculptor of Doom 801235 and Bane of Power 707902 charges.
- Regressions (`felsworn.json`, spell 572804), critical share of 801913: `crit_guarantee_76_74` (76% against 74%) and
  `crit_strict_76_75` (76% against exactly 75%), both with Cruelty 705109 set to -100 critical chance in both arms, so
  the normal roll reads 0 and only the guarantee reads 100; `crit_guarantee_offhand_76_74`, the same 76% against 74%
  arms read on the off-hand strike 801914 (the reference character dual-wields); and `crit_normal_74` (both arms at 74%,
  Cruelty set to 0 against 90): the normal roll keeps its 90-point difference, so it is neither forced nor suppressed
  below 75%. The two Reckless Assault 804610 Annihilan entries now set the dummy to 50% health, where non-critical hits
  remain.
- Without a critical aura the reference character's critical field read 0 in these scenarios (A-3 and the first runs of
  this fix), while Cruelty set to +90 read 92.8 and 95.2 in pair 2 (928 strikes per run) instead of 90, and with Cruelty
  set to 0 the control read 4.21% and 4.40% (pair 3, 2160 strikes per run): measured, the character's own chance appears
  once a critical aura is present. No code path was traced for it. The fixtures make the entries independent of it.
