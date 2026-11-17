# Reference character

`classes/<name>.json` holds `class_id`, `name`, `race`, `level`, `weapon` (`item`, equipment `slot`, 15 is the main
hand, `subclass` from `Item.dbc`: 10, a staff, for the Walking Stick), `skill_lines` (`class_skill_lines` of the class
spells and the weapon: Templar 70, 71, 72 and 136), `ratings` (fixture hit and expertise ratings, so that an aura or hit
is never lost to a miss; they do not change a tooltip value), `reference_stats`, `known_auras`, `probe_auras`, `procs`
(see [Proc rates](proc-rates.md#proc-rates)) and `talent_modifiers`, `rotation`, `stack`
(see [Talent stack](talent-stack.md#talent-stack-lever-map)), `alternate_weapons` and `extra_spells`
(see [Extra class spells](spell-sets.md#extra-class-spells)). The Templar reference is a human with the
Walking Stick (item 2495).

`weapon` also freezes the `item_template` row of the weapon: `min_damage` (`dmg_min1`), `max_damage` (`dmg_max1`),
`speed_ms` (`delay`), `inventory_type` and `normalized_speed`, the speed `Unit::GetAPMultiplier` uses for normalized
weapon damage (3.3 for a two-handed weapon, inventory type 17). Walking Stick, read on 2026-11-05 from `acore_world`
in the in-RAM test database with `SELECT dmg_min1, dmg_max1, delay, InventoryType FROM item_template WHERE entry =
2495`: 6.5625, 10.9375, 2500, 17. With 313 attack power, 6.5625 + 313 / 14 x 2.5 = 62.455 is the measured
`weapon_damage_min`. `reference_stats` holds the `base_steps` values measured on the naked reference character (Templar:
2026-11-05, `.cache/verify-all/20261105-181206`; the skills on 2026-11-06, `.cache/verify-all/20261106-122106` and
`20261106-122142`: `skill_value` 300 on lines 70, 71, 72 and 136 after `set_skill` 300/300); they size the scenarios,
and the comparison uses the values measured in the run.

`alternate_weapons` lists other reference weapons with the same fields plus `skill_line`, the `SkillLineAbility` line of
the weapon-skill spell of their subclass (owner answer Q9: a second, one-handed reference weapon). A rank whose
`EquippedItemClass` is 2 and whose `EquippedItemSubClassMask` or `EquippedItemInventoryTypeMask` excludes `weapon`
(`unfit_reason`, the checks of `Item::IsFitToSpellRequirements`) takes the first alternate weapon that fits:
`armed(class_file, requirement)` returns the class file with that weapon, its skill line added to `skill_lines` and
`skill <line>` added to `reference_stats` at 5 × level. The value scenario, its generated tokens, the hit scenario and
the comparison of that rank use it; the hit rule names it (`reference weapon 2259 (EquippedItemSubClassMask 41105
excludes the reference weapon subclass 10)`). Without a fitting weapon the hit is `unmodelled` with that reason. The
Templar one-hand weapon is the Frostmane Club (item 2259), a white one-handed mace of item level 6 and required level 3
like the Walking Stick, without stats or spells, read on 2026-11-06 from `acore_world` in the in-RAM test database with
`SELECT class, subclass, Quality, dmg_min1, dmg_max1, delay, InventoryType, RequiredLevel, ItemLevel FROM item_template
WHERE entry = 2259`: 2, 4, 1, 3.45, 5.75, 2000, 21, 3, 6; `Item.dbc` gives subclass 4, inside the mask 41105 of
Vindication 573324 and Righteous Upheaval 501562, its normalized speed is 2.4 (`Unit::GetAPMultiplier`, a one-hand
weapon that is not a dagger), and the Maces skill spell 198 is on line 54. One-Handed Maces (skill 54, spell 198) is a
Templar proficiency in `AscensionLiveBaselineData.h` (`Proficiencies`) and `AscensionCustomClassData.h`
(`ClassProficiencies`).

`base_steps` waits 5 s, adds and equips the weapon, sets each line of `skill_lines` to 5 × level with `set_skill`
(value and maximum: 300 at level 60, owner answer Q4) and measures it back with `skill_value` (label `skill
<line>`), then measures with the extreme bounds of an exploratory measurement (the judgement is made by the
comparison, never by the scenario): `attack_power`,
`ranged_attack_power`, `spell_power 1`..`6`, `stat 0`..`4`, `weapon_damage_min`, and one `aura` per entry of
`known_auras` (label `known_aura <id>`) and of `probe_auras` (label `probe_aura <id>`). `caster_stats_from(measured,
class_file)` rebuilds the `CasterStats` that `read_tooltip` needs from those labelled values, the class file's level,
race, class and weapon subclass, and the measured skills.

A naked level-60 Templar knows no class spell and carries one class aura: measured on 2026-11-05 on the worldserver of
the worktree, `knows_spell` is 0 for all 221 spell ids of the class and `aura` is 1 only for the class tuning aura
887007 (887043/887044/887045, the spec auras, and the passive Scourgebane 92111 read 0). `known_auras` therefore lists
887007 only; Scourgebane is in `probe_auras`, which is measured and reported but never explains a deviation.
