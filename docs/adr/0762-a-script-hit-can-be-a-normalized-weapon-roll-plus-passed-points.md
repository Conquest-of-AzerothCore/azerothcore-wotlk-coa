# 0762. A script hit can be a normalized weapon roll plus passed points

- Status: proposed (provisional number, numbered at merge); superseded in part by
  [0810](0810-a-mixed-mask-normalized-value-hit-is-judged-on-its-loaded-school.md) (a mixed mask strike is not
  physical)
- Date: 2026-11-16

## Context

Witch Hunter claim 319.0 (Purifier's Edge 802434, "dealing Weapon Damage plus ${$m1+0} with both weapons as Fire
damage") passes 277 to each hand's strike (803357 main, 803517 off) through SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE
(`SpellEffects.cpp:1847-1852`); each strike is one SPELL_EFFECT_NORMALIZED_WEAPON_DMG of school mask 5. The hit model
had no such part. Design H8 of c14-tool2; mentor D-240.

## Options

- A `normalized_value` part of `script_hit`, one entry per hand.
- A summed judge over both hands: not needed while each hand has its label.

## Decision

`script_hit` takes `normalized_value: true` with `value_spell` and `value_effect`. The model: the weapon of the
strike's hand (`attack_hand` of the strike's requirement) rolls between its minimum and maximum plus attack power / 14
x its normalized speed (`Unit::GetAPMultiplier`, `Unit.cpp:15077-15095`, the class file's `normalized_speed`), times
the off-hand factor 0.5 (`UNIT_MOD_DAMAGE_OFFHAND` TOTAL_PCT, `Unit.cpp:515`, applied by
`Player::CalculateMinMaxDamage`, `StatSystem.cpp:730-765`), truncated as `urand(uint32(min), uint32(max))`
(`Unit.cpp:3639`); plus the passed points, times the same factor and truncated for a physical strike
(`SpellEffects.cpp:4687-4706`); then the modifiers and the mitigation of the strike's school mask: armor for a mask
with the physical bit (`Unit.cpp:2422-2426`) and no resistance roll (`Unit.cpp:2672`). A non-physical off-hand strike
is unmodelled: the engine calls `CalculateDamage` without TOTAL_PCT there (`SpellEffects.cpp:4719`), so whether the
off-hand factor applies is not settled.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical.
- Seeded tests: tooltip means from the weapon numbers (348.34 main, 173.67 off); hits at the model pass. Mutant that
  must alert: an off-hand strike at main-hand damage, and a main-hand strike without the 277.
- Witch Hunter: 802434 `main_hand` and `off_hand`. Not built: Dusk Blade 321.0. Its main hand is 802258 itself
  (`script_hit` refuses a hit spell equal to the tooltip spell), its off hand 803502 is Shadow (non-physical), and
  its `$sps*0.15` term has a 0 coefficient in `spell_bonus_data` (`rev_20260908_07_witch_hunter_completion.sql`).
