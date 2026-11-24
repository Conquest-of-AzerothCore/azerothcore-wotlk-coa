# 0013. Stand Against Darkness reduces periodic damage taken from any caster

- Status: accepted
- Date: 2026-11-22

## Context

Stand Against Darkness 707078, Spell.dbc text: "During the day you now deal $707768s2% more Holy damage and take
$707768s2% reduced periodic damage." The class code keeps the helper 707768 on the player in daytime while 707078 is
known (`AscensionSunCleric.cpp`, `KeepHelper(player, 707768, day && player->HasAura(707078))`). 707768 Effect[1] is
aura 214 `SPELL_AURA_214`, target caster, MiscValue 127 (all schools), MiscValueB 0, BasePoints -11 + 1 = -10.

The only engine reader of aura 214 on a periodic tick, `Unit::SpellDamageBonusTaken`, applies it only when the
effect's MiscValueB is 1 and its caster is the DoT's caster. 707768 Effect[1] matches neither, and the class's
periodic hook `sun_cleric_scaling::ModifyPeriodicDamageAurasTick` only scaled the Sun Cleric's own family 33 spells.
Measured on batch 5t (pair 20261122-031110 / 20261122-031311, build 1a61a435cece): an enemy Shadow Flame 22682 dealt
4000 to the Sun Cleric with and without the helper, against 3600 expected; a direct hit of the same school read 605 /
606 in both phases.

## Options

- Apply 707768 Effect[1] in the class's existing `ModifyPeriodicDamageAurasTick`, keyed to the helper on the target,
  as Templar 301283 and Venomancer 804687 do in their own files.
- Change the engine reader in `Unit.cpp` to accept MiscValueB 0: a shared engine edit that reaches every class
  carrying aura 214.

## Decision

The first option (mentor decision D-77, 2026-11-22, fix note F-5). A periodic damage, damage percent or leech tick
taken by a target carrying 707768 Effect[1] is multiplied by `max(0, 1 + amount / 100)` when the effect's MiscValue
matches the spell's school mask and the spell lacks `SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS`. The amount is read
from the live aura effect.

"From any caster" is a reading of the tooltip's "take ... reduced periodic damage", which names no source, together
with MiscValueB 0 on a self-targeted effect. It is an inference from the tooltip, not a documented meaning of the
data.

## Consequences

- During the day an enemy's DoT on the Sun Cleric deals 10% less per tick (500 to 450 for Shadow Flame); at night,
  when the helper is absent, it is unchanged. Direct damage and periodic heals are unchanged.
- The engine reader still rejects 707768 (MiscValueB 0), so nothing is applied twice.
- 707768 is read by id only in `AscensionSunCleric.cpp` and `AscensionSunClericContracts.cpp`; no other class reads
  it. No engine file changes.
- Regression: the 707078 class-file entries `taken_dot` (day, 4000 then 3600), `taken_dot_night` (night, 4000 in
  both phases, helper absent) and `taken_direct` (direct hit unchanged).
