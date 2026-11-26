-- Shaman-family spells whose behaviour lived in an unhandled dummy effect (tools/dummy_census/fix-batches/shaman-*.md);
-- scripts and SpellInfo contracts in src/server/coa/AscensionDummyFixShaman.cpp.

-- ---------------------------------------------------------------- chunk 1
DELETE FROM `spell_script_names` WHERE `ScriptName` LIKE 'spell_dummyfix_shaman_%';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Mental Quickness: physical damage -> Magical Quickness 830822, magic damage -> Physical Quickness 840822 (s1%)
(30812, 'spell_dummyfix_shaman_mental_quickness'),
(30813, 'spell_dummyfix_shaman_mental_quickness'),
(30814, 'spell_dummyfix_shaman_mental_quickness'),
(830815, 'spell_dummyfix_shaman_mental_quickness'),
(830816, 'spell_dummyfix_shaman_mental_quickness'),
-- Totemic Shatter: the active Fire / Earth totem releases 92276 / 92277 and is destroyed
(92487, 'spell_dummyfix_shaman_totemic_shatter'),
(92488, 'spell_dummyfix_shaman_totemic_shatter'),
-- Raging Riptide: a Healing Rain cast heals every unit carrying the shaman's Riptide (278191)
(278190, 'spell_dummyfix_shaman_raging_riptide'),
(278191, 'spell_dummyfix_shaman_raging_riptide_heal'),
-- Rising Winds: the Windfury Attack hit clears the Windfury proc cooldown once
(274816, 'spell_dummyfix_shaman_rising_winds'),
-- Tidal Force 1505198: grants 1155166 at full stacks (a critical heal drops one: row below)
(1505198, 'spell_dummyfix_shaman_tidal_force');

DELETE FROM `spell_proc` WHERE `SpellId` IN (30812, 30813, 30814, 830815, 830816, 1590425, 278190, 274816, 1155166);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Mental Quickness: direct damage done (melee / ranged / spell; no periodic)
(30812, 0, 0, 0x0, 0x0, 0x0, 0x11154, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
(30813, 0, 0, 0x0, 0x0, 0x0, 0x11154, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
(30814, 0, 0, 0x0, 0x0, 0x0, 0x11154, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
(830815, 0, 0, 0x0, 0x0, 0x0, 0x11154, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
(830816, 0, 0, 0x0, 0x0, 0x0, 0x11154, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Stoneclaw (wcr): main-hand hits (auto attacks and abilities); the DBC charges count them
(1590425, 0, 0, 0x0, 0x0, 0x0, 0x400000, 0x1, 0x2, 0x3, 0x0, 0, 0, 100, 0, 0),
-- Raging Riptide: Healing Rain (SpellFamilyFlags[2] 0x4000000) cast; the script keeps the cast that places the rain
(278190, 0, 11, 0x0, 0x0, 0x4000000, 0x4400, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Rising Winds: the (triggered) Windfury Attack hit
(274816, 0, 11, 0x800000, 0x0, 0x0, 0x10, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Tidal Force 1155166: a critical Healing Wave / Lesser Healing Wave / Chain Heal drops one stack (the DBC's one
-- charge took the whole aura on any heal)
(1155166, 0, 11, 0x1C0, 0x0, 0x0, 0x4400, 0x2, 0x2, 0x2, 0x10, 0, 0, 100, 0, 0);

-- ---------------------------------------------------------------- chunk 2
-- (Sacred Rites 81395 and Down For The Count 81263 are damage hooks in the C++ file: no rows)
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((81100, 'spell_dummyfix_shaman_by_fire_be_purged'), (281347, 'spell_dummyfix_shaman_by_fire_be_purged'), (276578, 'spell_dummyfix_shaman_elemental_lord'), (282093, 'spell_dummyfix_shaman_frugal_disposition'), (81513, 'spell_dummyfix_shaman_frugal_disposition'), (281402, 'spell_dummyfix_shaman_pack_alpha'), (81139, 'spell_dummyfix_shaman_pack_alpha'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- By Fire Be Purged: a Fire Nova blast purges (370) every enemy it damages; 30 sec (enchant) / 15 sec (talent) lockout
(81100, 'spell_dummyfix_shaman_by_fire_be_purged'),
(281347, 'spell_dummyfix_shaman_by_fire_be_purged'),
-- Elemental Lord: Elemental Blast / Lava Burst damage grants Elemental Earth, Frost or Fire at random
(276578, 'spell_dummyfix_shaman_elemental_lord'),
-- Frugal Disposition: Lesser Healing Wave overhealing -> 282095 (75% / half), not topped off -> 282096
(282093, 'spell_dummyfix_shaman_frugal_disposition'),
(81513, 'spell_dummyfix_shaman_frugal_disposition'),
-- Pack Alpha: Feral Spirit grants the haste buff; Stormstrike / Lava Lash extend it and shorten Feral Spirit
(281402, 'spell_dummyfix_shaman_pack_alpha'),
(81139, 'spell_dummyfix_shaman_pack_alpha');

DELETE FROM `spell_proc` WHERE `SpellId` IN (81100, 281347, 276578, 282093, 81513, 282096, 281402, 81139);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- By Fire Be Purged: Fire Nova damage (the shaman's triggered cast at the totem)
(81100, 0, 11, 0x0, 0x40000, 0x0, 0x11000, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
(281347, 0, 11, 0x0, 0x40000, 0x0, 0x11000, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Elemental Lord: Lava Burst (0x1000) / Elemental Blast (0x20000000) damage
(276578, 0, 11, 0x0, 0x1000, 0x20000000, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Frugal Disposition: Lesser Healing Wave heals
(282093, 0, 11, 0x80, 0x0, 0x0, 0x4000, 0x2, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(81513, 0, 11, 0x80, 0x0, 0x0, 0x4000, 0x2, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Indulgent Disposition 282096: the next Lesser Healing Wave it affects uses it up
(282096, 0, 11, 0x80, 0x0, 0x0, 0x4000, 0x2, 0x1, 0x0, 0x8, 0, 0, 100, 0, 1),
-- Pack Alpha: Feral Spirit / Zulian Guardian cast (0x10000), Stormstrike (0x10) / Lava Lash ([2] 0x4) damage
(281402, 0, 11, 0x0, 0x10010, 0x4, 0x14410, 0x7, 0x3, 0x0, 0x2, 0, 0, 100, 0, 0),
(81139, 0, 11, 0x0, 0x10010, 0x4, 0x14410, 0x7, 0x3, 0x0, 0x2, 0, 0, 100, 0, 0);

-- ---------------------------------------------------------------- chunk 3
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((281411, 'spell_dummyfix_shaman_lightning_mastery'), (81140, 'spell_dummyfix_shaman_lightning_mastery'), (283338, 'spell_dummyfix_shaman_weapon_command'), (954057, 'spell_dummyfix_shaman_weapon_command'), (271813, 'spell_dummyfix_shaman_tidecallers_boon'), (1181221, 'spell_dummyfix_shaman_converging_elements'), (278040, 'spell_dummyfix_shaman_flame_nova'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Overload Mastery / Lightning Mastery: Lightning Bolt / Chain Lightning hits recast as Lightning Overload for half
(281411, 'spell_dummyfix_shaman_lightning_mastery'),
(81140, 'spell_dummyfix_shaman_lightning_mastery'),
-- Weapon Command: single two-hander -> 954058 (1 sec check)
(283338, 'spell_dummyfix_shaman_weapon_command'),
(954057, 'spell_dummyfix_shaman_weapon_command'),
-- Tidecaller's Boon: the talent grants its passive 271821
(271813, 'spell_dummyfix_shaman_tidecallers_boon'),
-- Converging Elements (wcr): the buff 1181221 makes the next Stormstrike leave no cooldown
(1181221, 'spell_dummyfix_shaman_converging_elements'),
-- Flame Nova: Fire Nova also explodes (at 50%) from up to 4 enemies with the shaman's Flame Shock
(278040, 'spell_dummyfix_shaman_flame_nova');

DELETE FROM `spell_proc` WHERE `SpellId` IN (278033, 281411, 81140, 1181221, 278040);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Elemental Burst: Elemental Blast ([2] 0x20000000) damage
(278033, 0, 11, 0x0, 0x0, 0x20000000, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Overload / Lightning Mastery: Lightning Bolt / Chain Lightning damage, Overload bolts (triggered) included; DBC chance
(281411, 0, 11, 0x3, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x2, 0, 0, 0, 0, 0),
(81140, 0, 11, 0x3, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x2, 0, 0, 0, 0, 0),
-- Converging Elements buff: the Stormstrike ([1] 0x10) hit
(1181221, 0, 11, 0x0, 0x10, 0x0, 0x10, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Flame Nova: the (triggered) Fire Nova damage ([1] 0x40000)
(278040, 0, 11, 0x0, 0x40000, 0x0, 0x11000, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0);

-- ---------------------------------------------------------------- chunk 4 (+ chunk 5/6 strikes and learn-with)
-- (Totem Master: Fire 81445 / 281999 is a creature hook in the C++ file: no rows)
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((1588516, 'spell_dummyfix_shaman_totemic_shatter'), (273561, 'spell_dummyfix_shaman_imbue_strike'), (860103, 'spell_dummyfix_shaman_imbue_strike'), (1572175, 'spell_dummyfix_shaman_imbue_strike'), (271579, 'spell_dummyfix_shaman_imbue_strike'), (417699, 'spell_dummyfix_shaman_imbue_strike'), (276116, 'spell_dummyfix_shaman_imbue_strike'), (984202, 'spell_dummyfix_shaman_imbue_strike'), (1576497, 'spell_dummyfix_shaman_imbue_strike'), (907120, 'spell_dummyfix_shaman_imbue_strike'), (907870, 'spell_dummyfix_shaman_imbue_strike'), (907080, 'spell_dummyfix_shaman_imbue_strike'), (907862, 'spell_dummyfix_shaman_imbue_strike'), (907100, 'spell_dummyfix_shaman_imbue_strike'), (300452, 'spell_dummyfix_shaman_imbue_strike'), (983523, 'spell_dummyfix_shaman_learn_with'), (417700, 'spell_dummyfix_shaman_learn_with'), (982650, 'spell_dummyfix_shaman_learn_with'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Fire Nova 1588516 (end of Ragefire Nova): the Fire totem emits 1588517
(1588516, 'spell_dummyfix_shaman_totemic_shatter'),
-- weapon-imbue strikes: +s2% with the named imbue on the weapon
(273561, 'spell_dummyfix_shaman_imbue_strike'),
(860103, 'spell_dummyfix_shaman_imbue_strike'),
(1572175, 'spell_dummyfix_shaman_imbue_strike'),
(271579, 'spell_dummyfix_shaman_imbue_strike'),
(417699, 'spell_dummyfix_shaman_imbue_strike'),
(276116, 'spell_dummyfix_shaman_imbue_strike'),
(984202, 'spell_dummyfix_shaman_imbue_strike'),
(1576497, 'spell_dummyfix_shaman_imbue_strike'),
(907120, 'spell_dummyfix_shaman_imbue_strike'),
(907870, 'spell_dummyfix_shaman_imbue_strike'),
(907080, 'spell_dummyfix_shaman_imbue_strike'),
(907862, 'spell_dummyfix_shaman_imbue_strike'),
(907100, 'spell_dummyfix_shaman_imbue_strike'),
(300452, 'spell_dummyfix_shaman_imbue_strike'),
-- "if you know X you also learn Y": Downpour, Lava Sweep, Herod's Legacy
(983523, 'spell_dummyfix_shaman_learn_with'),
(417700, 'spell_dummyfix_shaman_learn_with'),
(982650, 'spell_dummyfix_shaman_learn_with');

-- ---------------------------------------------------------------- chunk 5
DELETE FROM `spell_script_names` WHERE `spell_id` = 263374 AND `ScriptName` = 'spell_sha_frozen_power';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Frozen Power 263374: the stock Frozen Power proc (effect 1 chance, 15+ yd, Freeze 63685)
(263374, 'spell_sha_frozen_power'),
-- Echoing Power: each Shock grants its boon; the AP debuff stays on Frost Shock
(285510, 'spell_dummyfix_shaman_echoing_power'),
-- Low Tide Riptide trigger: the healed ally gets the shaman's Riptide
(270392, 'spell_dummyfix_shaman_low_tide'),
(301044, 'spell_dummyfix_shaman_low_tide'),
-- Mechanical Arm: grants a Maelstrom Weapon stack
(1590326, 'spell_dummyfix_shaman_mechanical_arm');

DELETE FROM `spell_proc` WHERE `SpellId` IN (263374, 285510, 271813);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Frozen Power: Frost Shock (0x80000000) / Elemental Blast ([2] 0x20000000) hits; "only every 10 seconds"
(263374, 0, 11, 0x80000000, 0x0, 0x20000000, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 10000, 0),
-- Tidecaller's Boon (chunk 3): Healing Wave (0x40) heals
(271813, 0, 11, 0x40, 0x0, 0x0, 0x4000, 0x2, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Echoing Power: Earth (0x100000) / Frost (0x80000000) / Flame (0x10000000) Shock hits
(285510, 0, 11, 0x90100000, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);

-- ---------------------------------------------------------------- chunk 6
-- (Herod's Legacy 982650 is in the learn-with rows above)
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((1181190, 'spell_dummyfix_shaman_electric_surge'), (978220, 'spell_dummyfix_shaman_fire_watch'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Electric Surge (wcr): Lightning Bolt / Chain Lightning casts trigger the highest known Flurry talent rank
(1181190, 'spell_dummyfix_shaman_electric_surge'),
-- Fire Watch: Stormstrike / Lava Lash -> Exploding Storm 978613, trap damage -> Fire Watch 978615
(978220, 'spell_dummyfix_shaman_fire_watch');

DELETE FROM `spell_proc` WHERE `SpellId` IN (1181190, 978220);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Electric Surge: Lightning Bolt (0x1) / Chain Lightning (0x2) cast
(1181190, 0, 11, 0x3, 0x0, 0x0, 0x10000, 0x1, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Fire Watch: damage from abilities, spells, triggered strikes and trap periodics; the script picks the spells
(978220, 0, 0, 0x0, 0x0, 0x0, 0x51010, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0);

-- Froststorm Focus (979677): Frost spells cast while Elemental Clearcasting is up (the script checks both); its buff
-- (979678) has one charge, spent by the Lightning Bolt (0x1) or Chain Lightning (0x2) whose school it changes
DELETE FROM `spell_script_names` WHERE `spell_id` = 979677 AND `ScriptName` = 'spell_dummyfix_shaman_froststorm_focus';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(979677, 'spell_dummyfix_shaman_froststorm_focus');

DELETE FROM `spell_proc` WHERE `SpellId` IN (979677, 979678);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(979677, 0, 0, 0x0, 0x0, 0x0, 0x10000, 0x1, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(979678, 0, 11, 0x3, 0x0, 0x0, 0x10000, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 1);
