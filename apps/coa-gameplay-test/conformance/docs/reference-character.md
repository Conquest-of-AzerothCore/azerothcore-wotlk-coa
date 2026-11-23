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

### Weapon sets

A class whose specializations wear different weapons lists them in `weapon_sets` {name: {`main_hand`, `off_hand`,
`ranged`}}, each hand a weapon entry with `skill_line` (or `null`), `default_weapon_set` and `spell_weapon_sets`
{rank id: set} ([ADR 0681](../../../../docs/adr/0681-a-specialization-wears-its-own-weapon-set.md)). `armed(class_file,
requirement, spell_id)` (`values.armed_for` passes the rank's `EQUIP_FIELDS` and attack fields) takes the first set,
in the order the rank's set, the default set, the others, where one hand passes `unfit_reason` (the
`Player::HasItemFitToSpellRequirements` slot scan, `Player.cpp:13494-13499`) and the hand an `AttributesEx3` main-hand
or off-hand requirement names fits (`Spell.cpp:8005-8031`); without a fitting set it keeps the rank's set. The result
has `weapon_set`, `weapon` = the hand of the rank's attack type (`Spell.cpp:596-614`: off hand for a melee rank with
the off-hand requirement, the ranged hand for a ranged weapon rank or an auto-repeat rank, else the main hand), and
every hand's skill line in `skill_lines` and `reference_stats`. `base_steps` equips every hand of the set (slots 15,
16, 17), the default set for a class file not yet armed. A behaviour, proc, trigger, target-gate or learned-hit
entry starts from the set of its own spell (`for_entry`, the `spell` or `aura` of the entry); a spell it casts keeps
that set when the set fits it and otherwise takes the first fitting set in the order above. The class file's `weapon` stays the default set's main hand
(`check_weapon_sets` refuses another, an unknown set name or a hand in the wrong slot). Classes without `weapon_sets`
keep `weapon` and `alternate_weapons`. The Witch Hunter (class 15) sets, from `item_template` on 2026-11-15:
Black Knight 2529 Zweihander (two-hand sword, 73.62-103.34, 2800 ms), Inquisition two 2027 Scimitar (one-hand sword,
17.25-28.75, 2300 ms), Boltslinger 15809 Heavy Crossbow (49-50, 2800 ms, main hand empty), Houndmaster (default) two
2027 Scimitar and 15809. `spell_weapon_sets` holds every rank of the class spells of the `CharacterAdvancement` tabs
39 Boltslinger, 40 Darkness (Houndmaster), 41 Inquisition and 94 WitchKnight (Black Knight); the tab 87 Class spells
take the default set.

`weapon_set_spells` {set name: [spell ids]} names the spells a set needs before it can be equipped (Valkyr's Grip
707072 for two two-handers, `Player::CanTitanGrip`, `PlayerStorage.cpp:2090-2091`; ADR
[1012](../../../../docs/adr/1182-a-weapon-set-can-learn-the-spells-it-needs-to-be-equipped.md)). `base_steps` learns
them with real `learn` steps after the settle wait and before the set's equip steps, only in the scenarios that wear
that set. `check_weapon_set_spells` refuses a key that is not a set name or a value that is not a non-empty list of
distinct positive ids; `procs.control_weapon` refuses a control set whose spells the scenario's own set does not learn;
`ManifestWriter.add` refuses a scenario that learns a set spell again while it is learned (map that spell in
`spell_weapon_sets` to a set without it). Without the field no step is added.

`server_inventory_masks` {rank id: {`mask`, `source`}} states a rank's `EquippedItemInventoryTypeMask` as the server
loads it, when the server repairs the DBC mask (`source` names the server code; ADR
[0890](../../../../docs/adr/0890-a-class-file-can-state-the-server-repaired-equip-mask.md)). Every weapon requirement
read (`values.equip_requirement`, `values.weapon_requirement`, `compare.read_tokens`) then uses `mask`; ranks without an
entry keep the DBC mask. `check_server_inventory_masks` refuses an entry without a source, and `server_requirement` a
mask that drops a DBC bit. Witch Hunter: 501349 = 71335936 (`AscensionClassMechanics.cpp:1006-1019`, `:1225-1227`).

`rank_hit_effects` {rank id: {`hit_mean`, `periodic_total`, `source`}} names the effect each hit label of a rank
models when its tooltip states a direct hit and a periodic total that both own tokens (`hits.hit_kind` otherwise
refuses the rank as several hit models; ADR [0920](../../../../docs/adr/0920-a-rank-can-split-its-direct-hit-from-its-periodic-total.md)).
`hits.rank_hit` then reads only the named effect's tooltip values and refuses an effect whose model is not the label's
(a periodic model for `periodic_total`, any other for `hit_mean`); the hit scenario's damage reads carry `periodic`
false or true, so each label judges only its own events, and the comparison models each label with its own role
(`hits.measured_hit_model`, ADR 1141). Ranks without an entry are unchanged. Witch Hunter: 501349
(direct Effect[2], periodic Effect[0]).

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
