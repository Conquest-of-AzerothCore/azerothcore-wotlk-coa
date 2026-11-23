# 0039. Calm disarms ranged weapons through the class contract

- Status: accepted (owner ruling O-28, 2026-11-23: "Calm disarms ranged (server fix)")
- Date: 2026-11-23

## Context

Calm 804057, Spell.dbc text: "Calm an enemy, disarming their melee and ranged weapons for $d. If your target is an
Undead or Demon, they are also unable to attack or move for $807778d. Enemies that are immune to silence effects cannot
be affected by this."

Spell.dbc 804057 uses all three effect slots: Effect[0] 64 `SPELL_EFFECT_TRIGGER_SPELL` 807778 (mechanic 0),
Effect[1] aura 67 `SPELL_AURA_MOD_DISARM` and Effect[2] aura 254 `SPELL_AURA_MOD_DISARM_OFFHAND` (mechanic 3 each);
the spell's own Mechanic is 0. It has no aura 278 `SPELL_AURA_MOD_DISARM_RANGED`, which the core handles
(`SpellAuraEffects.cpp:348`, `:3302-3304`, flag `UNIT_FLAG2_DISARM_RANGED` 0x400, read by
`Unit::CanUseAttackType(RANGED_ATTACK)`, `Unit.h:1004`). 807778 is the Undead and Demon part: aura 25
`SPELL_AURA_MOD_PACIFY` (mechanic 9) and aura 26 `SPELL_AURA_MOD_ROOT`, TargetCreatureType 36.

Pre-fix counted pair 20261123-075212 / 20261123-075514, build 09562e0306eb, 12 Calm entries: `flag_ranged` reads the
0x400 flag 0 after Calm (expected 1) and `shooter_ranged` reads an enemy Witch Hunter's Auto Shot 75 at 3 in the
control window and 5 under Calm (expected +0), both runs; the main-hand (0x00200000) and off-hand (0x80) flags read 1
and Justice 572848 is refused under Calm. The round B pair 20261122-213945 / -214041 (build d0e42dc9) read the same.

## Options

1. Turn Effect[0] into aura 278 in the class contract and cast 807778 from the class at the stage where the trigger
   effect cast it.
2. Set `UNIT_FLAG2_DISARM_RANGED` from an aura script on Calm. Rejected: it copies the core's disarm handler (flag order,
   weapon damage and item-dependent auras) instead of using it.
3. Move aura 278 into 807778. Rejected: 807778's TargetCreatureType 36 keeps it off every other target.

## Decision

Option 1. `AscensionSunClericContracts.cpp` gives 804057 Effect[0] `SPELL_EFFECT_APPLY_AURA` aura 278 on
`TARGET_UNIT_TARGET_ENEMY` with `MECHANIC_DISARM`, like Effect[1] and Effect[2], and clears its trigger spell. The class's
`OnSpellCalculatedTarget` (`AscensionSunClericAbilities.cpp`) casts 807778 on each unit Calm hits, at launch, with the
flags of `Spell::EffectTriggerSpell` (`TRIGGERED_FULL_MASK & ~TRIGGERED_NO_PERIODIC_RESET`) and Calm's original caster.
The spell Mechanic stays 0, so the "unarmed player" check of `SpellInfo::CheckTarget` (`Mechanic == MECHANIC_DISARM`)
does not start to apply.

## Consequences

- Calm sets `UNIT_FLAG2_DISARM_RANGED` with the two melee flags, for the same duration and on the same aura, and a
  ranged attacker stops shooting under it. Post-fix pair 20261123-075703 / 20261123-075808, build 4025f8e56181:
  `flag_ranged` 1 and `flag_main`, `flag_offhand`, `shooter_ability`, `disarm_duration`, `undead_duration`,
  `demon_effect`, `humanoid_unaffected`, `disarm_humanoid`, `silence_immune` and `silence_immune_pacify` ok in both
  runs; `shooter_ranged` reads 3 and +0, but the trial is void on a refusal its entry does not state, Auto Shot 75
  reason 40 `SPELL_FAILED_INTERRUPTED` (open, with the controller). The Calm gameplay scenarios (`--spell 804057`,
  `--spell 807778`) pass (verify stamps 20261123-075844, 20261123-075935).
- 807778 lands as before on an Undead or Demon and is refused as before on any other unit (reason 27, recorded in the
  post-fix runs).
- A target immune to the disarm mechanic is now immune to every effect of Calm (`Unit::IsImmunedToSpell` returns immune
  when every effect is immune), so the class does not cast 807778 on it. Before, the trigger slot had mechanic 0 and
  807778 was still cast on such a target.
- Readers: 804057 and 807778 are named only in `AscensionSunClericAbilities.cpp` (the silence-immunity refusal, Sun
  Cleric ADR 0005, and this trigger) and in mod-spellbook data. No other class lists either spell. Aura 278 is read by
  the core's disarm handler; `UNIT_FLAG2_DISARM_RANGED` by `Unit::CanUseAttackType`, the Faction Champions script
  (`boss_faction_champions.cpp:1243`) and the training dummy immunities (`TrainingDummyImmunities.h:45`).
- Client text unchanged: the tooltip already says "melee and ranged weapons".
