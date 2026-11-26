# 0001. Cultist weapon sets

- Status: accepted (provisional number, numbered at merge)
- Date: 2026-11-24

## Context

The scaffold armed the Cultist (class 25) with item 49340 "Monster - Icecrown - 1H Sword", a placeholder, and the
alternate weapon 72038. Cultist conformance requires a researched weapon table per specialization before any counted
pair ([ADR 0681](../../0681-a-specialization-wears-its-own-weapon-set.md)). The class has four `CharacterAdvancement`
specialization tabs — 64 Godblade, 65 Corruption, 66 Influence and 88 Bulwark — plus tab 87 for class-wide spells.
`ChrSpecs.dbc` rows 40 `INFLUENCE`, 41 `CORRUPTION`, 42 `GODBLADE` and 96 `BULWARK` (class token `CULTIST`) display as
Heretic, Corruption, Godblade and Dreadnought.

## Options

- One reference weapon with alternates (the scaffold shape).
- One weapon set per specialization (`weapon_sets`, ADR 0681).

## Decision

`classes/cultist.json` holds four `weapon_sets` (controller table frozen 2026-11-24, D-4):

| Set | Main hand | Off hand | Ranged | `weapon_set_spells` |
|---|---|---|---|---|
| Godblade (default) | 2531 Great Axe (2H axe, skill 172) | none | none | none |
| Dreadnought | 2534 Rondel (1H dagger, skill 173) | 2129 Large Round Shield (shield, skill 433) | none | none |
| Heretic | 2535 War Staff (staff, skill 136) | none | none | none |
| Corruption | 2535 War Staff (staff, skill 136) | none | 5239 Blackbone Wand (wand, skill 228) | none |

Sources:

- Proficiencies: all five chosen item types (2H Axes 197, Staves 227, Daggers 1180, Shield 9116, Wands 5009) are granted
  in both `AscensionCustomClassData.h:1451-1460` (`ClassProficiencies`) and `AscensionLiveBaselineData.h:943-961`
  (`Proficiencies`). Class 25 has no Dual Wield (674) or Titan's Grip grant and no `TalentProficiencies` row, so
  `weapon_set_spells` is omitted ([ADR 1182](../../1182-a-weapon-set-can-learn-the-spells-it-needs-to-be-equipped.md)).
- Godblade: `Netherstrike` (806222, 578263, 806825–806828) requires a two-handed melee weapon (`EquippedItemClass` 2,
  `EquippedItemSubClassMask` 1378, `AttributesEx3` 0x400 main hand; includes 2H axe subclass 1) and `Veiled Knight`
  (706184) requires `EquippedItemInventoryTypeMask` 131072 (`INVTYPE_2HWEAPON`); Squidbots shape `"twoHand"`
  (`CoaSpecStatWeights.h:327`) and default spec (`CoaSpecStrategies.h:112`); combat logs (`Benskalle`, `Challe`) show
  single-weapon 2.5–3.5 s swings and 0 dual-wield swings.
- Dreadnought: `Twilight Shieldtoss` (524876, 804208, 503487–503488, 572140–572141, 572715) and `Doomcloak` (502134)
  require a shield (`EquippedItemClass` 4, `EquippedItemSubClassMask` 64), `Voidrider` (255281) requires
  `EquippedItemInventoryTypeMask` 16384 (`INVTYPE_SHIELD`), and baseline `Block` (107) requires `EquippedItemClass` 4,
  `EquippedItemSubClassMask` 96; Squidbots shape `"shield"` (`CoaSpecStatWeights.h:329`, blocking 2H in
  `ItemUsageValue.cpp:378`); combat logs (`Basharjj`, `Irenatorkos`, `Kidsabeast`) record `Twilight Shieldtoss` and
  `BLOCK` events.
- Heretic: `Malevolence` (500714, 502235–502243) requires any melee weapon (`EquippedItemClass` 2,
  `EquippedItemSubClassMask` 173555; includes staff subclass 10); `Void Power` (574147) scales bonus healing from
  average main-hand weapon damage (`AscensionCultist.cpp:291-292`); Squidbots shape `"twoHand"`
  (`CoaSpecStatWeights.h:330`); combat logs (`Jimjonescult`, `Minazuki`, `Slepcult`) show melee `SWING_DAMAGE` and
  `Malevolence`.
- Corruption: 0 weapon-gated spells in tab 65; Squidbots shape `"caster"` (`CoaSpecStatWeights.h:328`) with a `Wand`
  (5019) rotation filler (`playerbots_coa_rotations.sql:10498`); combat logs (`Xarathun`, `Nastylol`) show 0
  `SWING_DAMAGE`; `Wand` 5019 (`EquippedItemClass` 2, `EquippedItemSubClassMask` 524288) is granted at level 1
  (`AscensionCustomClassData.h:534`).
- Items: effective world database (RAM `acore_world.item_template`, read 2026-11-24): all five rows are Quality 1,
  `stat_type1..10` all 0, `spellid_1..5` all 0, `AllowableClass` -1, `Flags` 0, not Monster. Effective DB values used in
  `classes/cultist.json`: 2531 Great Axe (90.86–127.3, 3600 ms, inv 17, norm 3.3; base SQL had 90–135), 2534 Rondel
  (28.46–45.46, 1600 ms, inv 13, norm 1.7; base SQL had 27–50), 2129 Large Round Shield (ilvl 4, 41 armor, 1 block,
  inv 14; base SQL had ilvl 5, 55 armor, 0 block; matches `sun_cleric.json`), 2535 War Staff (84.53–119.41, 3300 ms,
  inv 17, norm 3.3; base SQL had 85–129), 5239 Blackbone Wand (39–74 shadow, 1600 ms, inv 26, norm 2.8; matches
  `felsworn.json`).
- Unsourced: exact item IDs for all four specializations and slots; ranged slot for Godblade, Dreadnought and Heretic
  (0 `Wand`/`Shoot`/`Throw` events across all 70 Cultist player-log pairs); Heretic Staff vs 2H Axe preference;
  Corruption main-hand/off-hand preference. No Cultist video observations exist in `coa-video-evidence`.

Rejected items:

- 2524 Truncheon (1H mace) for the Dreadnought main hand: valid only under `AscensionLiveBaselineData.h`
  (`Proficiencies`), not `AscensionCustomClassData.h` (`ClassProficiencies`); 2534 Rondel works under both.
- A wand for Heretic: unsourced (0 wand events in logs, no Heretic wand spell).
- 30752 Mag'hari Battleaxe: TBC-era 30749–30759 rows carried PvE Power `spellid_4` in `acore_world` (Sun Cleric and
  Felsworn lesson).
- 13823 Stout War Staff (Quality 0) and 2451 Crested Heater Shield (2129 Large Round Shield matches `sun_cleric.json`).
- Scaffold placeholders 49340 ("Monster - Icecrown - 1H Sword") and 72038 (removed; `alternate_weapons` is empty).

`default_weapon_set` is Godblade. `weapon` equals the Godblade main hand. `alternate_weapons` is empty. `skill_lines` is
`[88, 89, 90, 172, 497]` (Cultist's four class lines plus 172 Two-Handed Axes; 43 Swords from the placeholder is
removed, and `with_weapon_set` adds 173/433, 136 and 228 for the other sets).

`spell_weapon_sets` maps every rank of the class spells of tab 64 to Godblade (46), tab 65 to Corruption (62), tab 66 to
Heretic (64) and tab 88 to Dreadnought (47) — 219 ranks total. The 56 class-wide ranks of tab 87 stay on the default set
(Godblade) and are not listed. No spell needed a remap: every equipped-item requirement among class spells
(`Netherstrike`, `Malevolence`, `Twilight Shieldtoss`) is met by its specialization's set.

Data observation (no server change): `Voidrider` (255281, skill line 497, not in `CharacterAdvancement.dbc`) requires a
shield (`EquippedItemClass` 4, `EquippedItemInventoryTypeMask` 16384), and while active `AscensionCultist.cpp:314-321`
replaces `Twilight Shieldtoss` with `Voidcleave` (255282, skill line 497, not in `CharacterAdvancement.dbc`), whose
`Spell.dbc` row requires a two-handed melee weapon (`EquippedItemClass` 2, `EquippedItemSubClassMask` 1378). Neither
spell is in `class_spells(25)` or `cultist_clauses.json`; server code is left untouched.

## Consequences

- A behaviour, proc or trigger entry is measured with the weapons of its own specialization.
- Reference stats are re-read by a naked run per set.
- If the owner changes any unsourced item choice later, only that item changes and the naked run and pair repeat.
