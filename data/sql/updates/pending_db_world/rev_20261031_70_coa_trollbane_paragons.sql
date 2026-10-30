-- Hardcore - Trollbane (challenge 214, Prestige 428) requires killing the troll Paragons before set levels, but
-- none of them existed, so the trial could not be completed.
-- Names, subtitles, rank, type, models and mana modifiers: Ascension client creature cache
-- (boxcoa/ascension-data, every CoA mode). Levels and positions: Ascension footage and in-game .gps.
-- Health: the cached modifiers hold at level 45: Zazera took 13480 damage to kill on Ascension (with overkill),
-- and 9.0 gives her 13302; a level 35 Elite Witherbark Headhunter has exactly 4624. At level 59 they do not: on
-- Ascension Yahola has 68290 base health and each Hand of Yahola 24935, so those are set exactly. Vazul and her
-- Headhunters keep their cached modifiers.
-- Damage modifiers are estimates in line with nearby elite bosses (Mogh the Undying 2.4, Kazkaz the Unholy 2.8).
-- Loot: of their Ascension drops only Vazul's three Whispershade greens are her own; the rest (Ephemeral Key,
-- recipes, world greens) are shared world drops. Their chances were not recorded, so they use a common rare-elite
-- rate: 20% each in one group, at most one per kill (as Geomancer Flintdagger's own greens).

-- Vazul <Witherbark Paragon> (254168): level 40 elite in the Witherbark Village cave, Arathi Highlands,
-- guarded by two Elite Witherbark Headhunters (254176, level 34-35). Objective: kill before level 40.
-- Zazera <Sandfury Paragon> (254170): level 45 elite on top of the Sandsorrow Watch tower, Tanaris, in place of
-- the Sandfury Firecaller spawn there (guid 21812). Objective: kill before level 45.
-- Yahola <Mossflayer Paragon> (254169): level 59 elite on the Mazra'Alor temple steps, Eastern Plaguelands, in place
-- of the Mossflayer Shadowhunter spawn there (guid 53743), flanked by the Left and Right Hand of Yahola (254172,
-- 254173, level 59 elites), all facing the wall. Objective: kill before level 59.
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(254168,0,0,0,0,0,'Vazul','Witherbark Paragon',NULL,0,40,40,0,654,0,1,1.14286,1,1,20,1,0,2.5,2000,2000,1,1,2,32768,2048,0,0,7,0,254168,0,0,0,0,200,300,'',0,1,9,2,1,1,0,0,1,0,0,'',12340),
(254170,0,0,0,0,0,'Zazera','Sandfury Paragon',NULL,0,45,45,0,37,0,1,1.14286,1,1,20,1,0,2.5,2000,2000,1,1,2,32768,2048,0,0,7,0,0,0,0,0,0,300,450,'',0,1,9,3,1,1,0,0,1,0,0,'',12340),
(254169,0,0,0,0,0,'Yahola','Mossflayer Paragon',NULL,0,59,59,0,37,0,1,1.14286,1,1,20,1,0,2.5,2000,2000,1,1,2,32768,2048,0,0,7,0,0,0,0,0,0,600,900,'',0,1,28.8265,3.6,1,1,0,0,1,0,0,'',12340),
(254172,0,0,0,0,0,'Left Hand of Yahola',NULL,NULL,0,59,59,0,37,0,1,1.14286,1,1,20,1,0,1.5,2000,2000,1,1,1,32768,2048,0,0,7,0,0,0,0,0,0,200,400,'',0,1,8.4211,1,1,1,0,0,1,0,0,'',12340),
(254173,0,0,0,0,0,'Right Hand of Yahola',NULL,NULL,0,59,59,0,37,0,1,1.14286,1,1,20,1,0,1.5,2000,2000,1,1,1,32768,2048,0,0,7,0,0,0,0,0,0,200,400,'',0,1,8.4211,1,1,1,0,0,1,0,0,'',12340),
(254176,0,0,0,0,0,'Elite Witherbark Headhunter',NULL,NULL,0,34,35,0,654,0,1,1.14286,1,1,18,1,0,1.5,2000,2000,1,1,1,32768,2048,0,0,7,0,0,0,0,0,0,74,490,'',0,1,3.79,1,1,1,0,0,1,0,0,'',12340) ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (254168, 254169, 254170, 254172, 254173, 254176);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(254168,0,254026,1,1,12340),
(254169,0,254027,1,1,12340),
(254170,0,254028,1,1,12340),
(254172,0,945433,1,1,12340),
(254173,0,945433,1,1,12340),
(254176,0,3998,1,1,12340),
(254176,1,28226,1,1,12340);

DELETE FROM `creature_addon` WHERE `guid` = 53743;
DELETE FROM `creature` WHERE `guid` IN (21812, 53743, 2541680, 2541681, 2541682, 2541683, 2541684, 2541685, 2541686);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(2541680,254168,0,45,317,1,1,0,-2065.27,-3271.685,50.2637,4.71239,300,0,0,1,0,0,0,0,0,'',NULL,0,'Vazul <Witherbark Paragon>'),
(2541681,254176,0,45,317,1,1,0,-2062.27,-3271.685,50.2637,4.71239,300,0,0,1,0,0,0,0,0,'',NULL,0,'Elite Witherbark Headhunter (Vazul)'),
(2541682,254176,0,45,317,1,1,0,-2068.27,-3271.685,50.2637,4.71239,300,0,0,1,0,0,0,0,0,'',NULL,0,'Elite Witherbark Headhunter (Vazul)'),
(2541683,254170,1,440,979,1,1,0,-7189.39,-3008.6824,31.232,5.2691,300,0,0,1,0,0,0,0,0,'',NULL,0,'Zazera <Sandfury Paragon>'),
(2541684,254169,0,139,2274,1,1,0,3432.53,-5036.13,183.602,0.750492,300,0,0,1,0,0,0,0,0,'',NULL,0,'Yahola <Mossflayer Paragon>'),
(2541685,254172,0,139,2274,1,1,0,3430.48,-5033.94,183.602,0.750492,300,0,0,1,0,0,0,0,0,'',NULL,0,'Left Hand of Yahola'),
(2541686,254173,0,139,2274,1,1,0,3434.58,-5038.32,183.602,0.750492,300,0,0,1,0,0,0,0,0,'',NULL,0,'Right Hand of Yahola');

DELETE FROM `creature_formations` WHERE `memberGUID` IN (2541680, 2541681, 2541682, 2541684, 2541685, 2541686);
INSERT INTO `creature_formations` (`leaderGUID`, `memberGUID`, `dist`, `angle`, `groupAI`, `point_1`, `point_2`) VALUES
(2541680, 2541680, 0, 0, 7, 0, 0),
(2541680, 2541681, 3, 90, 7, 0, 0),
(2541680, 2541682, 3, 270, 7, 0, 0),
(2541684, 2541684, 0, 0, 7, 0, 0),
(2541684, 2541685, 3, 90, 7, 0, 0),
(2541684, 2541686, 3, 270, 7, 0, 0);

DELETE FROM `creature_loot_template` WHERE `Entry` = 254168;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(254168, 2061076, 0, 20, 0, 1, 1, 1, 1, 'Vazul - Vazul''s Whispershade Blindfold'),
(254168, 2067258, 0, 20, 0, 1, 1, 1, 1, 'Vazul - Mystic Whispershade Belt'),
(254168, 2072023, 0, 20, 0, 1, 1, 1, 1, 'Vazul - Spiritbound Whispershade Bindings');
