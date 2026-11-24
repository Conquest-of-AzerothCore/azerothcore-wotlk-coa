# 0001. Felsworn weapon sets

- Status: accepted (provisional number, numbered at merge)
- Date: 2026-11-23

## Context

The scaffold armed the Felsworn (class 14) with item 49340 "Monster - Icecrown - 1H Sword", a placeholder, and the
alternate weapon 72038. Felsworn O-10 (2026-11-23) requires a researched weapon table per specialization before any counted
pair ([ADR 0681](../../0681-a-specialization-wears-its-own-weapon-set.md)). The class has three `CharacterAdvancement`
tabs, 18 Demonology, 37 Slaying and 38 Felblood, plus tab 87 for class spells. `ChrSpecs.dbc` rows 7 FELBLOOD,
8 SLAYING and 9 DEMONOLOGY (class token DEMONHUNTER) display as Infernal, Slayer and Tyrant. ChrSpecs 28-30 belong to
the Ranger (class 21), another class.

## Options

- One reference weapon with alternates (the scaffold shape).
- One weapon set per specialization (`weapon_sets`, ADR 0681), with the spells a set needs learned before its equip
  ([ADR 1182](../../1182-a-weapon-set-can-learn-the-spells-it-needs-to-be-equipped.md)).

## Decision

`classes/felsworn.json` holds three `weapon_sets` (controller table frozen 2026-11-23, mentor D-4 to D-6):

| Set | Main hand | Off hand | Ranged | `weapon_set_spells` |
|---|---|---|---|---|
| Slayer (default) | 2027 Scimitar (1H sword, skill 43) | 2027 Scimitar | none | 674 Dual Wield |
| Tyrant | 2529 Zweihander (2H sword, skill 55) | 2529 Zweihander | none | 674, 92089 Burning Commander |
| Infernal | 2027 Scimitar | empty | 5239 Blackbone Wand (wand, skill 228) | none |

Sources:

- Slayer: CoA Knowledge MCP `rules:coa:equipment` (`dualWield: oneHand`, `noOneHanded: Mace`); Squidbots shape
  dualWield; the August video SfwYtESDY_4 (2026-08-03, level 60) shows two one-handers; Azzinoth's Assault 801904,
  Annihilan Strike 801903 and Fury Unleashed 555738 read "Requires One-Handed Melee Weapon" (mask 41105 includes sword).
- Tyrant: Burning Commander 92089, server DBC tooltip "Allows you to wield a Two-Handed Axe, Mace, Polearm or Sword in
  each hand and grants you additional Armor and magic resistance based on your attack power" (the July video text
  names Mace and Sword; the sword fits both); MCP `dualWield: twoHand` and `twoHandDualWieldBlockedTypes: Staff`;
  `Player.cpp:14200-14218` (`CanTitanGrip` with `HasBurningCommander`, Staff refused) and `PlayerStorage.cpp:205` (a
  two-handed off hand needs `CanDualWield()` and `CanTitanGrip`, so 674 as well); Carve 800206 and Felrend 800210 read
  "Requires Two-Handed Melee Weapon" (mask 1378 includes the two-handed sword).
- Infernal: the July video (level 60) shows one one-hand weapon in the right hand and the left hand empty; the MCP
  class list; no Infernal weapon spell exists in the DBC. The item type is unsourced: the sword shares the Slayer item.
- Items: effective world database (RAM `acore_world.item_template`, read 2026-11-23): Quality 1, `spellid_1..5` all 0,
  not Monster, `AllowableClass` -1. 2027 and 2529 are the items of the Sun Cleric sets.
- Ranged: unsourced for Slayer and Tyrant, none set. Infernal takes 5239 Blackbone Wand by the amendment of 2026-11-23
  (mentor; VideoAgent kDdwUleXHk0, 2026-08-12, level 60 Infernal, "Wand" action button): Quality 1, inventory type 26,
  1600 ms, 39-74 damage, `spellid_1..5` all 0, `AllowableClass` -1 (effective database); class 14 is granted Wand 5019
  at level 1 (`AscensionCustomClassData.h:97`) and skill 228 is open to all races and classes (`SkillRaceClassInfo` 231).
  477 Torch Flinger is not taken (Quality 2). Wand 5019 maps to Infernal in `spell_weapon_sets`. Throw 2764 and Shoot
  3018 stay outside the sets.

Rejected: 30749 and 30750 (`spellid_4` 101648 and 101696, "PvE Power" equip spells, the Sun Cleric lesson); 2528
Falchion (inventory type 21, main hand only); the Monster placeholder 49340 and 72038 (removed from the class file).

`default_weapon_set` is Slayer. `weapon` equals the Slayer main hand. `alternate_weapons` is empty.

`spell_weapon_sets` maps every rank of the class spells of tab 37 to Slayer, tab 38 to Infernal and tab 18 to Tyrant
(180 ranks with Wand 5019); the class spells of tab 87 take the default set and are not listed. No spell needed a remap: every
"Requires ..." weapon line is met by the set of its specialization. Burning Commander 92089 is a tab 18 spell that
Tyrant learns as a set spell, so it leaves `spell_weapon_sets` and wears the default set (ADR 1182, as Valkyr's Grip in
the Sun Cleric).

## Consequences

- A behaviour, proc or trigger entry is measured with the weapons of its own specialization.
- If the owner overturns the Infernal one-hand type, only that item changes, and the naked run and the pair repeat.
- Reference stats are re-read by a naked run per set.
