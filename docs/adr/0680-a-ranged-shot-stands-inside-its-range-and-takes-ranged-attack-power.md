# 0680. A ranged shot stands inside its range and takes ranged attack power

- Status: accepted (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

The Witch Hunter (class 15) ranged shots (Shadowblast 804191, Damnation 520062-520217, Quickdraw 804193 and others) use
SpellRange 114 (`RangeMin[0]` 0, `RangeMax[0]` 35, `Flags` 2, `SPELL_RANGE_RANGED`, `Spell.h:106`). `Spell::CheckRange`
(`Spell.cpp:7353-7358`) refuses such a spell with `SPELL_FAILED_TOO_CLOSE` inside the spell's minimum plus the melee
range (`Unit::GetMeleeRange`, `Unit.cpp:929-933`, at least `NOMINAL_MELEE_RANGE` 5 yd), so the value and hit scenarios'
dummy at `values.DUMMY_DISTANCE` 3 yd made every cast fail. The hit model `hits.weapon_hit` added the melee attack power
to every weapon roll, while the server takes the ranged attack power for a ranged weapon attack: `Spell.cpp:605-606`
sets `RANGED_ATTACK` for `DmgClass` 3 when `SpellInfo::IsRangedWeaponSpell` (`SpellInfo.cpp:1442-1447`) holds, and
`Unit::GetTotalAttackPowerValue(RANGED_ATTACK)` (`Unit.cpp:13672-13683`) reads `UNIT_FIELD_RANGED_ATTACK_POWER`. Owner
rulings O-5 (the ranged path) and O-11 (the distance from the spell's own range data, per scenario, melee scenarios keep
their melee distance, no single guessed constant).

## Options

- One ranged constant (for example 20 yd) for every hostile scenario: refused by O-11, and it moves melee scenarios.
- The spell's minimum plus a margin: the margin is a guessed constant.
- The midpoint of the spell's hostile `RangeMin[0]`..`RangeMax[0]` for a `SPELL_RANGE_RANGED` range, the melee distance
  otherwise, with a check that the midpoint clears the minimum plus the nominal melee range.

## Decision

- `values.cast_distance(records, spell)` returns `DUMMY_DISTANCE` unless the spell's range has `Flags` ==
  `SPELL_RANGE_RANGED` (the equality `Spell::CheckRange` and `Unit::IgnoresSpellMinRange` use); then it returns
  `(RangeMin[0] + RangeMax[0]) / 2` and raises when that is not past `RangeMin[0] + NOMINAL_MELEE_RANGE_YD`.
- The value scenario's dummy (`values.value_scenario`) and the hit scenario's dummy (`hits.hit_parts`, through
  `hits.creature_fixture(class_file, distance)`) take `cast_distance` of the scenario's own rank. Other builders keep
  `DUMMY_DISTANCE` until a ranged entry needs them (a `metric_delta` entry already has its own `dummy_distance`).
- A missile cast from that distance lands later: `Spell.cpp:2468-2476` delays the hit by
  `floor(max(dist, 5) / Speed x 1000)` ms. `values.missile_wait_ms` adds a `missile travel` wait of
  `ceil(max(distance, 5) / Speed x 1000) + CAST_MARGIN_MS` after a hostile cast of the value scenario, before its
  aura reads, only at a ranged distance (a melee-distance scenario keeps its steps); `compare.elapsed_bound` counts the
  wait's elapsed time in the duration window. Tormentor 800162 (Speed 60, 17.5 yd) waits 792 ms.
- `hits.ranged_weapon_attack(records, spell)` mirrors `IsRangedWeaponSpell` for `DmgClass` 3 (hunter family without the
  melee flag, a bow/gun/crossbow/thrown subclass mask, or `SPELL_ATTR0_USES_RANGED_SLOT`); `hits.rank_hit` passes
  `weapon_attacker` (the caster with `ap` = `rap`) to the weapon parts of the hit spell (the triggered spell for a
  triggered weapon hit). School parts never read the attack power, so they are unchanged.

## Consequences

- Seeded tests in `test_hits.py` (`RangedWeaponPathTest`): the midpoint for range 114, the melee distance for a melee
  range, the missile wait at the ranged distance and none at the melee distance, the ranged attack test, a weapon hit
  that follows the ranged and not the melee attack power, and the Damnation hit scenario with the crossbow equipped in
  the ranged slot and the dummy inside the shot range.
- No new check, so no mutant: the change moves a fixture and the attack power a weapon roll reads.
- The finished classes (Templar 19, Necromancer 23) generate byte-identical scenarios (no ranged-flag rank among them).
- Not changed: `tooltip.rank_spell` still ranks a weapon spell on the equipped weapon's skill spell (owner ruling O-6,
  held), so a lower rank read with a ranged weapon equipped uses level 60, not the rank's `MaxLevel`.
