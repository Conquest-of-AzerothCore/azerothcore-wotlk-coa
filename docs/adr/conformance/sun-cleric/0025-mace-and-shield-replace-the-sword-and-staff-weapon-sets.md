# 0025. Mace and shield replace the sword and staff reference weapon sets

- Status: accepted (owner ruling O-10, 2026-11-22, relayed by the mentor)
- Date: 2026-11-22
- Supersedes: the weapon table, the default-set rule and the shield consequence of [0001](0001-reference-weapon-sets-per-specialization.md).
  Its Valkyr row, its item criteria and its Valkyr's Grip section stand.

## Context

ADR 0001 gave Seraphim a sword and shield, Piety a staff and wand, and Blessings a sword and wand, and chose Seraphim
as the default set because it served the most active weapon requirements.

Footage of live players overrides the sources 0001 relied on (the Squidbots "caster" shape that made Piety a
two-hander, and "type not sourced, indifferent by data"):

- `1OP12-Y574g.csv`, character sheet at 4:48 to 4:52, a level 59 Piety Sun Cleric: the three bottom slots show a mace,
  a shield and a wand. The tooltips at 4:50 and 4:52 are a one-hand mace (61 - 97 damage, speed 2.70) and a shield.
- `0KkCcTyCzY0.csv` (Blessings, 12:37 and 13:04): "plate and shield", with the stat priority caption "Plate + Shield".

- `0KkCcTyCzY0.csv` (Blessings, 10:58): floating numbers on a dummy with "weapon: one-handed mace/hammer held, teal
  head, shield not seen" (confidence medium). It shows a one-hand mace in the Blessings video and supports the decision
  for Blessings; it does not show a shield.

Two spoken claims inside the cited videos point the other way and are weaker than the 4:50 tooltip: `1OP12-Y574g.csv`
at 4:48, "I test using staff and mason shield" (the speaker tests with a staff and a shield), and `0KkCcTyCzY0.csv` at
12:48, "if you do wear a two-hand weapon, it does mean that your gavel" (a two-hand weapon increases Gavel of Light
damage, a speaker claim). Neither shows the weapon and neither is used for the decision.

The mace is filmed in the Piety sheet (tooltip) and in the Blessings video (held weapon, medium confidence); no footage
shows the main hand of Seraphim.

The filmed mace, Hammer of Grace, carries stats and an equip spell. No clean one-hand mace near 61 - 97 at 2.70 exists:
installed Hammer of Grace 11923 carries stats and PvE Power (spell 101648), its Bloodforged twin 6011923 carries stats
and spell 101712, and every one-hand mace within 55-67 / 90-104 at 2600-2800 carries stats or an equip spell.

## Decision

`classes/sun_cleric.json` holds these `weapon_sets` (the item criteria of 0001 still apply to each item):

| Set | Main hand | Off hand | Ranged |
|---|---|---|---|
| Valkyr | 2529 Zweihander (unchanged) | 2529 Zweihander | none |
| Seraphim (default) | 2524 Truncheon (one-hand mace, skill 54) | 2129 Large Round Shield (skill 433) | none |
| Piety | 2524 Truncheon | 2129 Large Round Shield | 477 Torch Flinger (skill 228) |
| Blessings | 2524 Truncheon | 2129 Large Round Shield | 477 Torch Flinger |

- 2524 is Quality 1, 34.61 - 55.4 at 2.50, no binding, no stats, no equip spell. It was chosen because no clean mace
  near 61 - 97 / 2.70 exists; 2.50 is the nearest speed with a usable damage range.
- Piety and Blessings are item-identical but stay two named sets: `spell_weapon_sets` keeps mapping each spell to its
  specialization.
- The default set is still Seraphim, and `weapon` equals its main hand (`profile.check_weapon_sets`). With a mace and a
  shield Seraphim serves 9 of the 12 active requirements; Piety and Blessings, with the wand, serve 11. 0001's rule (the set that serves the
  most requirements) no longer selects Seraphim; it stays the default because the O-10 change keeps it and
  leaves `default_weapon_set` untouched. A change of default would need its own ruling.
- Skill 54 comes to the character as skill 43 did: `playercreateinfo_spell_custom` teaches spell 198 to class 27
  (`rev_20260903_01_live_class_baseline.sql`, next to 201), and `with_weapon_set` adds 54 to the skill lines. No SQL
  changes.
- `skill_lines` keeps 43; `reference_stats` is unchanged because a naked reading per set returned identical values.

## Consequences

- The shield is worn in Seraphim, Piety and Blessings; a shield claim may be proven from any of the three.
- Block (107) is known by the class, so the caster can block in Piety and Blessings. A block counts as a hit, not a
  miss, so the attacker-miss-share parts are not affected.
- Every scenario of the three changed sets is regenerated; Valkyr scenarios are byte-identical.
- The reference weapon type of Seraphim is an inference from the Piety sheet and the Blessings video; footage of its
  main hand would reopen it.
