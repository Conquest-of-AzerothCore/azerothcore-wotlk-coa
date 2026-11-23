# 0681. A specialization wears its own weapon set

- Status: accepted (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

The conformance tool armed a class with one reference `weapon` and a list of `alternate_weapons` taken when a rank's
DBC requirement excluded the first (`profile.armed`, `unfit_reason`), plus `off_hand_weapons` for an explicit
`off_hand_item`. The Witch Hunter (class 15) has four specializations that wear different weapons (owner ruling O-10,
mentor D-33 and D-44): Black Knight a two-hander, Inquisition two one-handers, Boltslinger a crossbow, Houndmaster a
melee pair and a gun. A spell without a DBC requirement (`EquippedItemClass` -1, for example Wide Swings 681098
and Grasp of the Undying 707064) still belongs to one specialization, and one prop weapon (49340, 72038, 72041, the
Worn Shortsword 25) made the weapon terms of the specialization claims too small or wrong. The server checks a spell
against every equipped weapon slot (`Player::HasItemFitToSpellRequirements`, `Player.cpp:13485-13499`), the main or off
hand named by `SPELL_ATTR3_REQUIRES_MAIN_HAND_WEAPON` / `SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON` (`Spell.cpp:8005-8031`,
only for `EquippedItemClass` >= 0), and rolls the weapon of the spell's attack type (`Spell.cpp:596-614`).

## Options

- More alternate weapons: a spell without a DBC requirement never leaves the first weapon, so the specialization is
  lost.
- One class file per specialization: duplicates every entry and splits the count of record.
- Optional named weapon sets in the class file, a set per spell from its specialization, the DBC requirement first.

## Decision

- A class file may hold `weapon_sets` {name: {`main_hand`, `off_hand`, `ranged`}} (each hand a weapon entry with
  `skill_line`, or `null`), `default_weapon_set` and `spell_weapon_sets` {rank id: set}.
- `profile.armed(class_file, requirement, spell_id)` takes the first set, in the order the rank's set, the default set,
  the other sets, where one hand fits the requirement and the hand an `AttributesEx3` requirement names fits; when none
  fits it keeps the rank's set. `weapon` is the hand of the rank's attack type; every hand's skill line joins
  `skill_lines` and `reference_stats` at 5 x level. A class file already armed with a set that fits keeps it, with the
  new rank's hand as `weapon`.
- An entry (behaviour, proc, trigger, target gate, learned hit) starts from the set of its own spell
  (`profile.for_entry` with the entry's `spell`, or `aura` for procs and triggers), so a talent's scenario wears its
  specialization's weapons even when the spell it casts has no requirement or another specialization.
- `values.armed_for` and `compare.read_tokens` pass the rank's equipment and attack fields
  (`WEAPON_REQUIREMENT_FIELDS`) and its id. `base_steps` equips every hand of the set (slots 15, 16, 17), the default
  set for a class file not yet armed; passive scenarios are armed for their rank.
- `reference_stats` stays one dict: the naked runs of the four sets (run 20261115-084207) measured the same attack
  power, ranged attack power, stats and spell power, only the set's skill line differing.
- The class file's `weapon` stays, equal to the default set's main hand (`check_weapon_sets`, at load).
- Witch Hunter: Black Knight 2529, Inquisition 2027 + 2027, Boltslinger 2027 + 2027 + crossbow 15809, Houndmaster
  2027 + 2027 + gun 3025, default Houndmaster (mentor D-47 and D-49: the `ChrSpecs.dbc` chooser text names guns for
  the Houndmaster, and live footage shows both ranged specializations carrying two one-hand swords besides their
  ranged weapon); `spell_weapon_sets` maps every rank of the class spells of the
  `CharacterAdvancement` tabs 39 Boltslinger, 40 Darkness (Houndmaster), 41 Inquisition and 94 WitchKnight (Black
  Knight). 49340, 72038, 72041 and 25 are removed.
- Classes without `weapon_sets` keep `weapon`, `alternate_weapons` and `off_hand_weapons` unchanged.

## Consequences

- Seeded tests in `test_profile.py`: the set order, the requirement over the spec set, the attack-type hand, the
  hand attributes, a kept set, base steps per set and for the default (the Houndmaster gun 3025 in the ranged
  hand), the class-file check refusing an unknown set, a hand in the wrong slot, a missing hand and another
  `weapon`, the item subclasses against `Item.dbc`, and `spell_weapon_sets` recomputed from the advancement tabs
  (any edit of the map that leaves the tab rule fails it).
- The finished classes (Templar 19, Necromancer 23) generate byte-identical scenarios.
- Not changed: `unfit_reason` reads the raw DBC `EquippedItemInventoryTypeMask`; the server widens a ranged-only mask
  of a custom class spell (`RepairedRangedInventoryMask`, `AscensionClassMechanics.cpp:1006-1020, 1225-1227`), so
  Damnation 520214-520216, Tormentor 501344-501355 and Heartseeking Bolt 807279-807283 (`EquippedItemInventoryTypeMask`
  32768) fit no set in the tool and keep their Boltslinger set.
