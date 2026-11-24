# 0039. Calm disarms ranged weapons through the class contract

- Status: accepted (owner ruling O-28, 2026-11-23: "Calm disarms ranged (server fix)"; mentor D-306, 2026-11-23:
  Effect[0] keeps mechanic 0)
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
2. Set `UNIT_FLAG2_DISARM_RANGED` from an aura script on Calm. Rejected: it copies the core's disarm handler (flag
   order, weapon damage and item-dependent auras) instead of using it.
3. Move aura 278 into 807778. Rejected: 807778's TargetCreatureType 36 keeps it off every other target.

## Decision

Option 1. `AscensionSunClericContracts.cpp` gives 804057 Effect[0] `SPELL_EFFECT_APPLY_AURA` aura 278 on
`TARGET_UNIT_TARGET_ENEMY` and clears its trigger spell. Effect[0] keeps the DBC's mechanic 0 (mentor D-306): the ruling
adds the ranged disarm and nothing else, so a target immune to the disarm mechanic is still hit by Calm and still
receives 807778, as before the fix. The class's `OnSpellCalculatedTarget` (`AscensionSunClericAbilities.cpp`) casts
807778 on each unit Calm hits, at launch, with the flags of `Spell::EffectTriggerSpell`
(`TRIGGERED_FULL_MASK & ~TRIGGERED_NO_PERIODIC_RESET`) and Calm's original caster. The spell Mechanic stays 0, so the
"unarmed player" check of `SpellInfo::CheckTarget` (`Mechanic == MECHANIC_DISARM`) does not start to apply. The
silence-immunity refusal (owner ruling O-6, Sun Cleric ADR 0005) is unchanged.

Rejected: `MECHANIC_DISARM` on Effect[0], like Effect[1] and Effect[2]. A disarm-immune target would then be immune to
every effect of Calm (`Unit::IsImmunedToSpell` returns immune only when every effect is immune, `Unit.cpp:11353-11372`),
so the class would no longer cast 807778 on it: a change the ruling does not make.

## Consequences

- Calm sets `UNIT_FLAG2_DISARM_RANGED` with the two melee flags, for the same duration and on the same aura, and a
  ranged attacker stops shooting under it. Post-fix pair 20261123-081645 / 20261123-081736, worldserver f72b31ae094b,
  13 Calm entries ok in both runs, no flip: `flag_ranged` reads 0x400 at 0 before the cast and 1 after it;
  `shooter_ranged` reads an enemy Witch Hunter's Auto Shot 75 at 3 in the control and +0 under Calm (pre-fix +2);
  `flag_main`, `flag_offhand`, `shooter_ability`, `disarm_duration`, `disarm_humanoid`, `undead_duration`,
  `demon_effect`, `humanoid_unaffected`, `silence_immune` and `silence_immune_pacify` ok. The Calm gameplay scenarios
  (`--spell 804057`, `--spell 807778`) pass (verify stamps 20261123-081833, 20261123-081910).
- The ranged disarm interrupts an Auto Shot in progress: `AuraEffect::HandleAuraModDisarm` calls
  `Player::ApplyItemDependentAuras(item, false)`, and `Player::RemoveItemDependentAurasAndCasts` interrupts the current
  spell whose weapon requirement no other useable item meets (`Player::HasItemFitToSpellRequirements` through
  `Player::GetUseableItemByPos`, which reads `Unit::CanUseAttackType(RANGED_ATTACK)`, `Unit.h:1004`). The enemy's
  Auto Shot is refused once with reason 40 `SPELL_FAILED_INTERRUPTED` in the post-fix runs and in none of the pre-fix
  runs, whose control window is the same; `shooter_ranged` states it as native next to 807778 reason 27 and is judged on
  the shot count.
- A target immune to the disarm mechanic keeps the ranged disarm and still receives 807778. `disarm_immune`: Nissa
  Agamand 1655 (Undead, creature_immunities -113: DISARM, FEAR, SLEEP, KNOCKOUT, HORROR) carries 807778 1000 ms after
  Calm, 0 before it, in both post-fix runs. No pre-fix reading exists for this target; by the code, the pre-fix trigger
  slot had mechanic 0 and cast 807778 the same way.
- 807778 lands as before on an Undead or Demon and is refused as before on any other unit (reason 27, recorded in the
  post-fix runs).
- Readers: 804057 and 807778 are named only in `AscensionSunClericAbilities.cpp` (the silence-immunity refusal, Sun
  Cleric ADR 0005, and this trigger) and in mod-spellbook data. No other class lists either spell. Aura 278 is read by
  the core's disarm handler; `UNIT_FLAG2_DISARM_RANGED` by `Unit::CanUseAttackType`, the Faction Champions script
  (`boss_faction_champions.cpp:1243`) and the training dummy immunities (`TrainingDummyImmunities.h:45`).
- Client text unchanged: the tooltip already says "melee and ranged weapons".
