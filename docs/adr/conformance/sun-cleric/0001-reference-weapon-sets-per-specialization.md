# 0001. Reference weapon sets per specialization

- Status: superseded by [0025](0025-mace-and-shield-replace-the-sword-and-staff-weapon-sets.md) for the weapon table, the default-set rule and the shield consequence
- Date: 2026-11-20

## Context

The scaffold gave the Sun Cleric (class 27) item 49340 "Monster - Icecrown - 1H Sword", a placeholder that is not a
real weapon (`apps/coa-gameplay-test/conformance/docs/scaffolding.md`, the documented weapon gap). Owner ruling O-10
of the Witch Hunter pass requires a researched weapon table per specialization before any counted pair. The class
has four `CharacterAdvancement` tabs: 70 Piety, 71 Blessings, 72 Seraphim and 90 Valkyr, plus tab 87 for class spells
(`CharacterAdvancementTabTypes.dbc`). `ChrSpecs.dbc` rows 46, 47, 48 and 98 hold only their tokens.

Sources read on 2026-11-20:

- Spell.dbc requirements of the 260 class spells: 20 carry one, 12 of them with an active `EquippedItemClass`.
  - Gavels 800611, 800614 and 800617, Glorious Execution 800626 and Parry 3124 use mask 173555, which accepts axe,
    mace, polearm, sword and staff.
  - Justice 520359 uses mask 1378, which accepts two-handers only.
  - Sunstorm 760379 accepts any weapon.
  - Seraphic Bulwark 560095 and Dawnbreak 800654 need a shield (class 4, mask 64), and Block 107 uses class 4, mask 96.
  - Shoot 3018 and Wand 5019 need a ranged weapon and a wand.
- Valkyr's Grip 707072: "Allows you to dual wield and to wield a Two-Handed Mace, Sword, or Polearm in each hand".
- CoA Knowledge MCP entry `rules:coa:equipment` (BisBeard realm data, trust "derived", 2026-11-01):
  - Seraphim: `preferShield`, no dual wield;
  - Valkyr: `dualWield: twoHand`, Staff blocked;
  - Piety and Blessings: no dual wield.
- Squidbots `CoaSpecStatWeights.h:336-337` and `StatsWeightCalculator.cpp:776-801` (mod-playerbots):
  - shape "shield" for Seraphim;
  - shape "caster" for Piety, which sets `wantsTwoHand`;
  - shape "any" for Blessings.
- No source names the one-hand type. The class list (axe, mace, sword) is the only constraint, and no mask, tooltip,
  MCP rule or weight separates the three.

## Options

- One reference weapon with alternates (the scaffold shape).
- One weapon set per specialization (`weapon_sets`, ADR 0681), as the Witch Hunter has.

## Decision

`classes/sun_cleric.json` holds four `weapon_sets` (mentor rulings D-13 to D-26):

| Set | Main hand | Off hand | Ranged |
|---|---|---|---|
| Valkyr | 2529 Zweihander (2H sword, skill 55) | 2529 Zweihander | none |
| Seraphim (default) | 2027 Scimitar (1H sword, skill 43) | 2129 Large Round Shield (skill 433) | none |
| Piety | 2030 Gnarled Staff (staff, skill 136) | none | 477 Torch Flinger (wand, skill 228) |
| Blessings | 2027 Scimitar | none | 477 Torch Flinger |

- Valkyr follows the 707072 tooltip. The two-hand sword is the Witch Hunter precedent.
- Piety takes a staff from the Squidbots "caster" shape: Staff is in the MCP class list and in mask 173555.
- The one-hand type, sword, is the mentor's decision (D-23), recorded as "type not sourced, indifferent by data".
- Valkyr and Seraphim have no ranged item: no source gives one.
- Each item was checked in the live `acore_world` `item_template` on 2026-11-20:
  - Quality 1 or 2, `ItemLevel` > 0;
  - `stat_value1..10` all 0 and `spellid_1..5` all 0;
  - no `Monster - `, `Placeholder` or `RPGITEM` name.

  The first picks 3192, 15210 and 16993 were rejected because their `spellid_4` carries a "PvE Power" equip spell
  (101696, 101648 and 101645).
- `default_weapon_set` is Seraphim. It serves 9 of the 12 active requirements, against 8 for Piety and 7 for Valkyr and
  Blessings. The count follows the Player slot scan: class 2 on the weapon hands, class 4 on the off-hand shield.
- `spell_weapon_sets` maps every rank of the spells of tabs 70, 71, 72 and 90 to their set. Tab 87 class spells take
  the default set. A spell whose mask its set does not meet (Justice 520359 on a one-hand set) takes the first set that
  fits (ADR 0681).
- The skill lines 55, 136, 228 and 433 come in through the sets (`profile.with_weapon_set`).
- Reference stats are re-measured by a new naked run with the default set.

## Consequences

- A behaviour, proc or trigger entry is measured with the weapons of its own specialization.
- If the owner overturns the one-hand type, only the Scimitar item changes, and the naked run and the pair repeat.
- The conformance tool does not judge class 4 requirements (`profile.unfit_reason` passes them). The shield is
  therefore worn only in the Seraphim set, and a shield claim is proven from that set.

## Valkyr's Grip (2026-11-20, mentor D-27 to D-29)

- The first base pair (20261120-201337 / -201547) could not equip the Valkyr set: the second 2529 was refused with
  `EQUIP_ERR_ITEM_CANT_BE_EQUIPPED` (`Item.h:67`) because the reference character does not know Valkyr's Grip 707072.
- `weapon_set_spells` is `{"Valkyr": [707072]}`. The set learns the spell for real before its equip steps
  ([ADR 1182](../../1182-a-weapon-set-can-learn-the-spells-it-needs-to-be-equipped.md)).
- 707072 leaves `spell_weapon_sets`: its own value and passive scenarios measure before and after learning it, so they
  wear the default set.
- Effects of 707072 (Spell.dbc), and how each one is declared:
  - effect 155, Titan Grip: it can cast the penalty aura 49152 (-10% physical damage done), which
    `UpdateTitansGrip` removes when the player has Valkyr's Grip. 49152 is in `probe_auras`: every run reads
    whether it is on the character without judging it, and the Valkyr reading shows it absent. A first try listed it
    in `known_auras`, which expects the aura present, and raised 288 false alerts (pair 20261120-203619 / -203828).
  - effect 40, Dual Wield: it allows the off-hand attacks of the set.
  - aura 333, hit chance (`StatSystem.cpp:1031-1043`): the reference ratings already cap hit (10000 rating), so it
    changes no measured value.
- Valkyr-set naked reading 20261120-203401: both 2529 equipped, attack power 70, ranged attack power 25, stats
  40/35/56/119/128, skill 55 300, aura 49152 read 0 (absent). The stats are those of the default set, so
  `reference_stats` is unchanged.
