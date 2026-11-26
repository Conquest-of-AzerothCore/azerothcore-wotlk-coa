# 0001. Bloodmage weapon sets

- Status: accepted (provisional number, numbered at merge)
- Date: 2026-11-26

## Context

The scaffold armed the Bloodmage (class 20, `SONOFARUGAL`, `powerType` 1 Rage, `SpellFamilyName` 26) with item `49340`
"Monster - Icecrown - 1H Sword", a placeholder, and the alternate weapon `2000265` (Bow, subclass 2, skill 45).
Bloodmage conformance requires a researched weapon table per specialization before any counted pair
([ADR 0681](../../0681-a-specialization-wears-its-own-weapon-set.md)), with equip-prerequisite spells learned per set
via `weapon_set_spells` ([ADR 1182](../../1182-a-weapon-set-can-learn-the-spells-it-needs-to-be-equipped.md)). The class
has four `CharacterAdvancement.dbc` (`ClassType` 22) specialization tabs — `26` Blood (`Sanguine`), `52` Ferocity
(`Accursed`), `53` Packleader (`Eternal`) and `93` Fleshweaver (`Fleshweaver`) — plus tab `87` (`Class`) for class-wide
spells. `ChrSpecs.dbc` rows `25` `FLESHWEAVER`, `26` `BLOOD`, `27` `FEROCITY` and `99` `PACKLEADER` (class token
`SONOFARUGAL`) display as Fleshweaver, Sanguine, Accursed and Eternal.

## Options

- One reference weapon with alternates (the scaffold shape).
- One weapon set per specialization (`weapon_sets`, ADR 0681), with set-required equip spells in `weapon_set_spells`
  (ADR 1182).

## Decision

`classes/bloodmage.json` holds four `weapon_sets` (frozen 2026-11-26, D-5):

| Set | Spec (`ChrSpecs`) | Main hand | Off hand | Ranged | `weapon_set_spells` |
|---|---|---|---|---|---|
| Accursed (default) | 27 (`FEROCITY`) | 2535 War Staff (2H staff, skill 136) | none | none | none |
| Eternal | 99 (`PACKLEADER`) | 2534 Rondel (1H dagger, skill 173) | 2534 Rondel (1H dagger, skill 173) | none | `674` Dual Wield |
| Sanguine | 26 (`BLOOD`) | 2535 War Staff (2H staff, skill 136) | none | 5239 Blackbone Wand (wand, skill 228) | none |
| Fleshweaver | 25 (`FLESHWEAVER`) | 2535 War Staff (2H staff, skill 136) | none | none | none |

Sources:

- Proficiencies: all three chosen weapon types (Staves `227` skill `136`, Daggers `1180` skill `173`, Wands `5009` skill
  `228`) are granted in both `AscensionCustomClassData.h:1431-1436` (`ClassProficiencies`) and
  `AscensionLiveBaselineData.h:906-918` (`Proficiencies`). Class 20 has no Shield (`9116`) or Titan's Grip (`155`) grant
  and no `TalentProficiencies` row (`AscensionCustomClassData.h:1520-1536`).
- Dual Wield (`Eternal` only): `Eternal Curse` (`92114`, tab `53` Packleader, `"Teaches you Eternal Curse and allows you
  to dual wield."`) teaches `800157` Eternal Curse and `674` Dual Wield (`AscensionTaughtAbilityData.h:32-33`).
  `AscensionCompat.cpp:1132-1141` synchronizes `SetCanDualWield(HasSpell(674))` for `CLASS_SON_OF_ARUGAL` and unequips
  off-hand weapons when `674` is absent, so `weapon_set_spells` is `{"Eternal": [674]}` (ADR 1182).
- Accursed: `Reave` rank 1 (`800490`, tab `52` Ferocity) requires any melee weapon (`EquippedItemClass` 2,
  `EquippedItemSubClassMask` 173555; includes staff subclass 10); `Ravenous Strike` (`500123` chain, `extra_spells`) sets
  `AttributesEx3` `0x400` (`SPELL_ATTR3_REQUIRES_MAIN_HAND_WEAPON`, satisfied by any main-hand weapon); Squidbots shape
  `"twoHand"` (`CoaSpecStatWeights.h:312`); combat logs (`Alkazar` log 17/171, `Graf` logs 86/1078 and 152/1655,
  `Buttblood` log 164/1771) show single-weapon 2.5–4.45 s swings and 0 half-damage off-hand bands.
- Eternal: `Eternal Curse` (`92114`) grants `674` Dual Wield; combat logs (`Redfury` log 41/437 and `Fairgraves` log
  71/878) record dual-wield main-hand and off-hand swing damage bands (`99–127` vs `36–40`, `105–126` vs `19–21`);
  `2534` Rondel fits the Dagger proficiency in both `ClassProficiencies` and `Proficiencies` and matches `cultist.json`.
- Sanguine: 0 `EquippedItemClass >= 0` weapon-gated spells in tab `26`; Squidbots shape `"caster"`
  (`CoaSpecStatWeights.h:311`) with a `Wand` (`5019`) rotation filler (`playerbots_coa_rotations.sql:7210-7216`); combat
  logs (`Graf` log 97/1345, `Catamenia` log 49/502) show 0 melee swings; `Wand` (`5019`) is granted at level 1
  (`AscensionCustomClassData.h:341`) and `5009` Wands is in `ClassProficiencies`.
- Fleshweaver: 0 `EquippedItemClass >= 0` weapon-gated spells in tab `93`; Squidbots role `Heal` / `CASTER`
  (`CoaSpecialization.cpp:75,167`), shape `"any"` (`CoaSpecStatWeights.h:314`); combat logs (`Buttblood` log 150/1625,
  `Bloodyfaye` log 84/1045) show 0 swings in boss fights; ranged slot stays empty (0 `Wand`/`Shoot`/`Throw` events
  across all 63 Bloodmage player-log pairs).
- Forms: `Cursed Form` (`SpellShapeshiftForm.dbc` ID `57`, `attackSpeed = 0`) leaves `IsAttackSpeedOverridenShapeShift()`
  and `IsInFeralForm()` false, so equipped weapon damage and speed apply normally; `HasWeaponHidingForm`
  (`AscensionBloodmageTalents.cpp:591-606`) hides equipped weapons visually only.
- Video observation (`coa-video-evidence`, archive `q742IyqxrV0`, 2026-09-01, slide `s0004_6` at `0:06`): level 10
  Bloodmage character sheet shows Rage (`0/100`), no pet, main-hand dagger and off-hand book icons with an empty ranged
  slot — consistent with Daggers (`Eternal`), Staff/caster (`Accursed`/`Sanguine`/`Fleshweaver`) and no conflicting
  shield or physical ranged weapon class.
- Items (effective world database, RAM `acore_world.item_template`, queried 2026-11-26; `Item.dbc` subclasses verified):
  all three rows have `Quality` 1, `stat_type1..10` all 0, `stat_value1..10` all 0, `spellid_1..5` all 0,
  `AllowableClass` -1, `Flags` 0, `FlagsExtra` 0, non-Monster:
  - `2535` War Staff (`Item.dbc` 2/10, inv 17, ilvl 45, req 40): `84.53–119.41` physical, `3300` ms, norm `3.3`, skill
    `136` (matches `cultist.json`).
  - `2534` Rondel (`Item.dbc` 2/15, inv 13, ilvl 44, req 39): `28.46–45.46` physical, `1600` ms, norm `1.7`, skill `173`
    (matches `cultist.json`).
  - `5239` Blackbone Wand (`Item.dbc` 2/19, inv 26, ilvl 46, req 41): `39–74` shadow (`dmg_type1` 5), `1600` ms, norm
    `2.8`, skill `228` (matches `felsworn.json` and `cultist.json`).
- Unsourced: exact level-60 item IDs for all four specializations and slots; Sanguine/Fleshweaver Staff vs
  Dagger+Holdable preference; Eternal Dagger vs Fist preference; ranged slot for Accursed, Eternal and Fleshweaver (0
  `Wand`/`Shoot`/`Throw` events across all 63 Bloodmage combat-log player-log pairs).

Rejected items:

- Scaffold placeholders `49340` ("Monster - Icecrown - 1H Sword") and `2000265` (Bow, subclass 2, skill 45 — granted
  only in `AscensionLiveBaselineData.h`, not in `ClassProficiencies`); both removed and `alternate_weapons` is empty.

`default_weapon_set` is `Accursed`. `weapon` equals the `Accursed` main hand (`2535` War Staff). `alternate_weapons` is
empty. `skill_lines` is `[48, 73, 74, 75, 136, 500]` (`48` Voodoo, `73` Sanguine, `74` Accursed, `75` Eternal, `136`
Staves, `500` Fleshweaver; `43` Swords from placeholder `49340` is removed, `with_weapon_set` adds `173` Daggers for
`Eternal` and `228` Wands for `Sanguine`, and `118` Dual Wield is granted natively by `674`).

`spell_weapon_sets` maps 257 specialization ranks across the four `CharacterAdvancement` tabs: tab `26` (`Blood`) to
`Sanguine` (63), tab `52` (`Ferocity`) to `Accursed` (66), tab `53` (`Packleader`) to `Eternal` (57 — all 58 ranks
except `92114` Eternal Curse), and tab `93` (`Fleshweaver`) to `Fleshweaver` (71). `92114` Eternal Curse leaves
`spell_weapon_sets` and wears the default set (`Accursed`, without `674` pre-learned) so its own scenarios measure
learning `92114` and receiving `674` cleanly without `674` already known in the control phase (ADR 1182, as Felsworn
`92089` Burning Commander and Sun Cleric `707072` Valkyr's Grip). The 50 class-wide ranks of tab `87` and the 126 ranks
of the 32 `extra_spells` baseline spells stay on the default set (`Accursed`) and are not listed. Zero spells required a
DBC-requirement remap (`Reave` `800490` fits `Accursed`'s Staff; `Ravenous Strike` `500123` fits any main hand).

### Live 4-set naked verification

Verified in one batched `coa-verify --ram --stages gameplay --fresh-databases` run (stamp `20261126-113347`, 4 passed /
0 failed, 31.7 s, 0 `EQUIP_ERR` messages across all 4 sets; level 60 Human Bloodmage):

| Set | AP | RAP | SP (1–6) | Stats (STR/AGI/STA/INT/SPI) | Skills at 300 | `weapon_damage_min` |
|---|---:|---:|---:|---|---|---:|
| `Accursed` (default) | 223.0 | 50.0 | 0.0 | 63 / 60 / 78 / 98 / 114 | `48, 73, 74, 75, 136, 500` | `137.094284` |
| `Eternal` (`+[674]`) | 223.0 | 50.0 | 0.0 | 63 / 60 / 78 / 98 / 114 | `48, 73, 74, 75, 136, 500, 173` | `53.945717` |
| `Sanguine` | 223.0 | 50.0 | 0.0 | 63 / 60 / 78 / 98 / 114 | `48, 73, 74, 75, 136, 500, 228` | `137.094284` |
| `Fleshweaver` | 223.0 | 50.0 | 0.0 | 63 / 60 / 78 / 98 / 114 | `48, 73, 74, 75, 136, 500` | `137.094284` |

`reference_stats` in `classes/bloodmage.json` is recorded from the live `Accursed` run (`AP 223.0`, `RAP 50.0`,
`SP 1..6 = 0.0`, `stat 0..4 = 63/60/78/98/114`, `skill 48/73/74/75/136/500 = 300.0`).

## Consequences

- A behaviour, proc or trigger entry is measured with the weapons of its own specialization.
- `Eternal` scenarios learn `674` Dual Wield before equipping dual `2534` Rondels; `92114` Eternal Curse scenarios run
  on `Accursed` so `674` is not pre-learned before `92114` is tested.
- If the owner changes any unsourced item choice later, only that item changes and the naked run and pair repeat.
