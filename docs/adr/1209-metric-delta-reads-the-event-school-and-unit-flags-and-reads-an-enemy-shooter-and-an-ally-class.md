# 1209. A metric delta reads the damage event school and unit flags, and drives an enemy shooter and an ally class

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Sun Cleric end-of-class round B (mentor D-199, D-209, D-211, D-212) left four open points with no existing read:

- Justice 572848, "Your main-hand strike will deal Physical damage and your off-hand strike will deal Fire damage":
  `SpellDamageEvent` (`CoAGameplayTest.cpp`) carried no school, though `ObserveSpellDamage` already parsed the school
  byte of `SMSG_SPELLNONMELEEDAMAGELOG` and dropped it (`Unit::SendSpellNonMeleeDamageLog` writes
  `log->schoolMask`, a mask, not an index).
- Calm 804057, "disarming their melee and ranged weapons" (mentor D-152): the DBC carries aura 67 and aura 254, no
  aura 278. The core handles 278 (`SpellAuraEffects.cpp:348`, case `SPELL_AURA_MOD_DISARM_RANGED` sets
  `UNIT_FLAG2_DISARM_RANGED`) and `Unit::CanUseAttackType(RANGED_ATTACK)` is its only consumer (`Unit.h:1004`). No read
  of a unit flag existed, and `metric_delta` hard-codes the enemy player's cast target to itself.
- Lights of Absolution 807343, "restores ... Energy, Focus, Runic Power, and Rage": `Spell::EffectEnergizePct` lands
  only on a power the player is active in (`Unit::CanReceivePowerFromSpell`), and the ally fixture is always the class
  under test.

## Options

- A new harness action or fixture for each point: C++ and the owner's to approve.
- Read-only metrics and filters in the harness, plus Python-only options that compose the existing steps (`cast` with a
  target, `learn`, `add_item`, `equip`, `set_skill`, `relocate`, `reset_cooldown`, the per-player `class` of the
  scenario schema).

## Decision

Read-only harness reads, default off (mentor D-175 conditions: no game state touched, no existing read changed):

- `school_mask` (1 to 127) filters `spell_damage_count` and `spell_damage_total` by the packet's school mask; absent, the
  read is unchanged. Periodic damage events carry no mask and never match.
- `unit_flag_set` (`target`, `field` 1 or 2, `mask`) reads 1 when every bit of `mask` is set in `UNIT_FIELD_FLAGS` or
  `UNIT_FIELD_FLAGS_2` of the unit, else 0. It is a state metric.

Python-only options in `metric_delta_options`, opt-in:

- `enemy_shooter` (`mode` `ranged` or `ability`): the enemy player of `enemy_player_race`, of a CoA class, learns the
  stated spells, equips the stated weapons, is skilled, and casts one spell at the caster in the uncast before phase
  (the control window); a cast ability is repeated once the trigger has landed. The trial is void when the control did
  nothing, the enemy stood outside the stated distance, the trigger aura is not on the enemy, or (ranged mode) a cast is
  refused that the entry does not state as native.
- `ally_class` in `ally_arm` (a CoA class, 12 to 32): the grouped allies are created with that class; the entry states
  the power type it needs with a precondition arm on `active_power`.

## Consequences

- Absent by default: no entry of an existing class writes any of them; the finished classes regenerate byte-identical.
- Seeded tests for each option; the C++ reads need the G-39 note in the PR.
- A cast refused by design (Calm on a player refuses its Effect[0] trigger 807778, reason 27) cannot use
  `void_on_cast_failure`; `enemy_shooter` states it in `native_refusals` instead.

## Addendum (2026-11-23): `enemy_shooter.attack_time_ms`

Context: the Sun Cleric Calm entry `shooter_ranged` plans exactly 3 Auto Shots in its 6000 ms control window, a count
that holds only for a ranged attack time of 2434.78 ms (2800 ms crossbow, Auto Shot 75's +15% ranged speed, owner
ruling O-21). A different shooter (another haste, another weapon) would change the count and make the entry read an
alert that is not a defect of the spell.

Decision: `enemy_shooter` takes an optional `attack_time_ms` `{hand, value, tolerance}`. The scenario reads
`attack_time_ms` of `hand` on the enemy before the control window; a read outside `value` +- `tolerance`, or no read,
makes the trial `unmeasured`. It is a void guard only: no counted label, never `ok` or `alert`. An entry without the key
generates the same scenario and model as before, so the finished classes regenerate byte-identical.

Consequences: a seeded test and a mutant (a different attack time or no read gives `unmeasured`, never `ok`) cover it.
