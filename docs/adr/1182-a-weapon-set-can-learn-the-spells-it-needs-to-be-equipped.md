# 1182. A weapon set can learn the spells it needs to be equipped

- Status: accepted (provisional number, numbered at merge)
- Date: 2026-11-20

## Context

The Sun Cleric (class 27) Valkyr set wears the 2529 Zweihander in both hands. The reference character does not know
Valkyr's Grip 707072, so every scenario of that set stopped at its first off-hand equip with `Equipment change
rejected: equip error 20` (`EQUIP_ERR_ITEM_CANT_BE_EQUIPPED`, `Item.h:67`; `Player::CanEquipItem` refuses a two-hander
in the off hand without `CanTitanGrip`, `PlayerStorage.cpp:2090-2096`, and `Player::HasValkyrGrip` needs the spell,
`Player.cpp:14203-14216`). `profile.base_steps` only equipped the set and set its skills, and `check_weapon_sets` closes
a set to its three hand keys ([ADR 0681](0681-a-specialization-wears-its-own-weapon-set.md)).

## Options

- A harness aura on the caster: not the server path a player takes, and the equip check reads the learned spell, not
  an aura.
- Learning the spell for every scenario of the class: the other sets would measure a spell their specialization does
  not hold (Valkyr's Grip also raises hit chance).
- An optional class-file field naming the spells each set needs, learned with the harness `learn` action only in the
  scenarios that wear that set (mentor D-28).

## Decision

- A class file may hold `weapon_set_spells` {set name: [spell ids]}. `check_weapon_set_spells` refuses a key that is
  not a `weapon_sets` name and a value that is not a non-empty list of distinct positive integers; it runs on every
  class file load.
- `base_steps` adds a `learn` step per spell of the scenario's current set (`weapon_set`) after the settle wait and
  before the set's `add_item` and `equip` steps. Every scenario equips its set through `base_steps` (the default set,
  `for_entry`, `armed`), so each starts with exactly its own set's spells.
- The proc control arm (`procs.control_weapon`,
  [ADR 0751](0751-a-proc-on-a-two-handed-attack-can-swing-a-one-handed-control.md)) switches the main hand to
  another set mid-scenario; it refuses a control set whose spells the scenario's own set does not learn, so no set
  spell leaks across sets.
- `ManifestWriter.add` refuses a scenario that learns a `weapon_set_spells` spell again while it is still learned
  (`profile.check_weapon_set_relearns`): such a scenario measures its "before" with the spell already known. The class
  file then maps that spell in `spell_weapon_sets` to a set that does not need it.
- Without the field nothing changes: no step is added and no check refuses, so the finished-class digests stay
  identical.

## Consequences

- The spells' own effects are present in every scenario of their set; the class file declares them like any other
  known spell. For 707072 the effects are Titan Grip (155), the aura 333 `SPELL_AURA_ASCENSION_MOD_HIT_CHANCE_ALL_PCT`
  and Dual Wield (40).
- A set spell with its own learned scenario (passive, value) cannot wear the set that needs it; generation stops until
  the class file maps it elsewhere.
