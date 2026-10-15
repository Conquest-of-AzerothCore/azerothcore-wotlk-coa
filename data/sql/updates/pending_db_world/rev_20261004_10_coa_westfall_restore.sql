-- Westfall restore from Ascension captures: 17 missing quests (WDB 2026-09-07..10, Exiles DB 2026-09-13),
-- their givers, targets and objects, plus field differences in existing Westfall quests.
-- Positions are estimated; displays marked stand-in replace Ascension models the client lacks.

INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`,
  `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`,
  `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`,
  `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`,
  `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`,
  `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`,
  `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`,
  `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(776786, 0, 0, 0, 0, 0, 'Captain Olens', 'The People''s Militia', NULL, 9950100, 14, 14, 0, 12, 3, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.98, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(776787, 0, 0, 0, 0, 0, 'Protector Brenolt', 'The People''s Militia', NULL, 0, 14, 14, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 0.98, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(776790, 0, 0, 0, 0, 0, 'Archivist Selnor', NULL, NULL, 0, 11, 11, 0, 12, 2, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.98, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(255150, 0, 0, 0, 0, 0, 'Idona Wyther', 'Alchemy Trainer', NULL, 4110, 26, 26, 0, 12, 83, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1500, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.064, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(255151, 0, 0, 0, 0, 0, 'Tavin Wyther', 'Alchemy Supplies', NULL, 0, 23, 23, 0, 12, 128, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1500, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1.064, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(991515, 0, 0, 0, 0, 0, 'Lenore the Hoarder', '', NULL, 0, 15, 15, 0, 17, 0, 1, 1.14286, 1, 1, 18, 1, 0, 1, 2000, 2000, 1, 1, 1, 32768, 2048, 0, 0, 7, 0, 991515, 95, 0, 0, 0, 3, 24, 'SmartAI', 0, 1, 3, 1, 1, 1, 0, 0, 1, 0, 0, '', 0),
(255339, 0, 0, 0, 0, 0, 'Militia Recruit', 'The People''s Militia', NULL, 58274, 14, 16, 0, 12, 1, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1.448, 1, 1, 1, 0, 0, 1, 0, 0, '', 0),
(157002, 0, 0, 0, 0, 0, 'Farmer Demont', '', NULL, 0, 15, 15, 0, 35, 2, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1500, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.25, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(455339, 0, 0, 0, 0, 0, 'Slain Protector', 'The People''s Militia', NULL, 0, 15, 15, 0, 35, 2, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 768, 2048, 32, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 2.048, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(455343, 0, 0, 0, 0, 0, 'Half-Devoured Protector', 'The People''s Militia', NULL, 0, 15, 15, 0, 35, 2, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 768, 2048, 32, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 2.048, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(100467, 0, 0, 0, 0, 0, 'Path to Ascension Flightmaster Credit', '', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 0, 0, 1, 1, 1, 2, 0, 0, 0, 7, 2147483648, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, '', 0),
(255152, 0, 0, 0, 0, 0, 'Displaced Farmer', '', NULL, 0, 8, 8, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1500, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 0.96, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(449328, 0, 0, 0, 0, 0, 'Brother Alric', NULL, NULL, 9950101, 22, 22, 0, 12, 1, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1000, 2000, 1, 1, 1, 768, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1.328, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(776784, 0, 0, 0, 0, 0, 'Jane Foster', '', NULL, 9950102, 11, 11, 0, 12, 1, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1500, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.98, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(776785, 0, 0, 0, 0, 0, 'Hank Dullahan', 'Riding Trainer', NULL, 9950104, 11, 11, 0, 12, 83, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.98, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(255153, 0, 0, 0, 0, 0, 'Mayor Leighton', '', NULL, 0, 30, 30, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.064, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(776780, 0, 0, 0, 0, 0, 'Marianna Carson', '', NULL, 0, 5, 5, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1500, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 0.96, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(776791, 0, 0, 0, 0, 0, 'Scheming Protector', 'The People''s Militia', NULL, 9950103, 31, 31, 0, 11, 1, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 4096, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.98, 1, 1, 1, 0, 0, 1, 0, 0, '', 0),
(776792, 0, 0, 0, 0, 0, 'Scheming Protector', 'The People''s Militia', NULL, 9950103, 31, 31, 0, 11, 1, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 4096, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.98, 1, 1, 1, 0, 0, 1, 0, 0, '', 0),
(265154, 0, 0, 0, 0, 0, 'Bella', '', NULL, 0, 5, 5, 0, 190, 0, 1, 0.85714, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 0.0112, 1, 1, 0, 0, 100, 1, 0, 0, '', 0),
(256249, 0, 0, 0, 0, 0, 'Snuggles', 'Wyther''s Family Pet', NULL, 0, 15, 15, 0, 35, 0, 1, 0.85714, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 2.548, 1, 1, 0, 0, 100, 1, 0, 0, '', 0),
(776778, 0, 0, 0, 0, 0, 'Melissa Norman', NULL, NULL, 0, 10, 10, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1500, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.98, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(776779, 0, 0, 0, 0, 0, 'Ethan Norman', NULL, NULL, 0, 5, 5, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1500, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.98, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(776781, 0, 0, 0, 0, 0, 'Willow Brelor', NULL, NULL, 0, 10, 10, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1500, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.98, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(776782, 0, 0, 0, 0, 0, 'Sally Vernal', NULL, NULL, 0, 10, 10, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1500, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.98, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(776783, 0, 0, 0, 0, 0, 'Everard Handor', NULL, NULL, 0, 10, 10, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 1500, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.98, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(776788, 0, 0, 0, 0, 0, 'Protector Murphy', 'The People''s Militia', NULL, 0, 14, 14, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.98, 1, 1, 1, 0, 0, 1, 0, 2, '', 0)
ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`),
  `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`),
  `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`),
  `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`),
  `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`),
  `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`),
  `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`),
  `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`),
  `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`),
  `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`),
  `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`),
  `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`),
  `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`),
  `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`),
  `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`),
  `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`),
  `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`),
  `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`),
  `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`),
  `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`),
  `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`),
  `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`),
  `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- Stand-in displays: Olens 177231, Brenolt 177232, Selnor 177229, Idona 255150, Tavin 255151 and
-- Lenore 119854, Slain Protector 177256 and Half-Devoured Protector 177252 are not in the client.
-- Sentinel Hill residents from AscensionDB and the db.exil.es dump of 2026-10-04 (names, subnames, levels,
-- health; Snuggles, Marianna Carson and Bella added 2026-06-07, Mayor Leighton and the Scheming Protectors
-- 2026-07-13). Stand-in displays: Displaced Farmer 652361-652364, Brother Alric 449278, Jane Foster 177227,
-- Hank Dullahan 177228, Mayor Leighton 255153, Marianna Carson 177223 and the Scheming Protectors
-- 177242/177243 are not in the client. Bella and Snuggles use their Ascension displays.
-- Town hall residents Melissa Norman 177221, Ethan Norman 177222, Willow Brelor 177224, Sally Vernal 177225,
-- Everard Handor 177226 and Protector Murphy 177233 (Exiles DB export 2026-09-13; archive only) are matched
-- to the people the footage shows in the town hall; their levels are estimated and their displays are
-- stand-ins chosen by the clothes in the footage.
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (776786,776787,776790,255150,255151,991515,255339,157002,455339,455343,100467,255152,449328,776784,776785,255153,776780,776791,776792,265154,256249,776778,776779,776781,776782,776783,776788);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(776786, 0, 7310, 1, 1, 0),
(776787, 0, 7309, 1, 1, 0),
(776790, 0, 1840, 1, 1, 0),
(255150, 0, 1692, 1, 1, 0),
(255151, 0, 3649, 1, 1, 0),
(991515, 0, 4419, 1, 1, 0),
(255339, 0, 7308, 1, 1, 0),
(255339, 1, 7309, 1, 1, 0),
(255339, 2, 7310, 1, 1, 0),
(255339, 3, 7311, 1, 1, 0),
(157002, 0, 19354, 1, 1, 0),
(455339, 0, 2368, 1, 1, 0),
(455343, 0, 7308, 1, 1, 0),
(100467, 0, 11686, 1, 1, 0),
(255152, 0, 18616, 1, 1, 0),
(255152, 1, 18617, 1, 1, 0),
(255152, 2, 18618, 1, 1, 0),
(255152, 3, 18619, 1, 1, 0),
(449328, 0, 3283, 1, 1, 0),
(776784, 0, 1295, 1, 1, 0),
(776785, 0, 3274, 1, 1, 0),
(255153, 0, 3637, 1, 1, 0),
(776780, 0, 1691, 1, 1, 0),
(776791, 0, 2369, 1, 1, 0),
(776792, 0, 2371, 1, 1, 0),
(265154, 0, 1060, 1, 1, 0),
(265154, 1, 102275, 1, 1, 0),
(256249, 0, 30213, 1, 1, 0),
(776778, 0, 3486, 1, 1, 0),
(776779, 0, 251, 1, 1, 0),
(776781, 0, 3647, 1, 1, 0),
(776782, 0, 5552, 1, 1, 0),
(776783, 0, 18617, 1, 1, 0),
(776788, 0, 7308, 1, 1, 0);

-- Protector Murphy carries a sword in the footage; the militia protectors' sword is used.
DELETE FROM `creature_equip_template` WHERE `CreatureID`=776788;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(776788, 1, 1899, 0, 0, 0);

DELETE FROM `creature_template_addon` WHERE `entry` IN (455339,455343,256249);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`,
  `visibilityDistanceType`, `auras`) VALUES
(455339, 0, 0, 7, 1, 0, 0, NULL),
(455343, 0, 0, 7, 1, 0, 0, NULL),
(256249, 0, 0, 3, 1, 0, 0, NULL);

-- Hank Dullahan <Riding Trainer> teaches riding as Randal Hunter does; his greeting is from the Sentinel Hill
-- footage (YouTube F6vp8CJOTGk).
DELETE FROM `creature_default_trainer` WHERE `CreatureId`=776785;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES
(776785, 37);

-- Estimated: Idona Wyther teaches the same alchemy list as Alchemist Mallory.
DELETE FROM `creature_default_trainer` WHERE `CreatureId`=255150;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES
(255150, 67);

-- Tavin Wyther's first vendor page as seen in footage; the rest of his list is unknown.
DELETE FROM `npc_vendor` WHERE `entry`=255151;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(255151, 0, 3371, 0, 0, 0, 0),
(255151, 1, 3372, 0, 0, 0, 0),
(255151, 2, 8925, 0, 0, 0, 0),
(255151, 3, 18256, 0, 0, 0, 0),
(255151, 4, 40411, 0, 0, 0, 0),
(255151, 5, 858, 3, 3600, 0, 0),
(255151, 6, 929, 3, 3600, 0, 0),
(255151, 7, 3385, 3, 3600, 0, 0),
(255151, 8, 3827, 3, 3600, 0, 0),
(255151, 9, 3388, 2, 3600, 0, 0);

DELETE FROM `smart_scripts` WHERE `entryorguid`=255339 AND `source_type`=0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(255339, 0, 0, 0, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 42, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Reset - Set Invincibility Hp Level 1'),
(255339, 0, 1, 2, 2, 0, 100, 0, 0, 1, 1000, 1000, 0, 0, 33, 255339, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - Between 0-1% Health - Quest Credit ''Militia Training'''),
(255339, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Link - Evade'),
(255339, 0, 3, 4, 62, 0, 100, 0, 58274, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Gossip Option 0 Selected - Close Gossip'),
(255339, 0, 4, 5, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Link - Remove Npc Flag Gossip'),
(255339, 0, 5, 6, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 7, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Link - Set Faction 7'),
(255339, 0, 6, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Link - Start Attacking'),
(255339, 0, 7, 8, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Evade - Restore Faction'),
(255339, 0, 8, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruit - On Link - Add Npc Flag Gossip');

-- Path to Ascension: Westfall (100466): no capture names its ender; Dungar Longdrink grants the credit
-- on greeting and takes the quest, as an estimate.
DELETE FROM `smart_scripts` WHERE `entryorguid`=352 AND `source_type`=0 AND `id`=3;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(352, 0, 3, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 100467, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dungar Longdrink - On Gossip Hello - Quest Credit ''Path to Ascension: Westfall''');

DELETE FROM `creature_text` WHERE `CreatureID`=991515;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`,
  `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(991515, 0, 0, 'HEY! Get away from my stuff!!!', 12, 0, 100, 0, 0, 0, 0, 0, 'Lenore the Hoarder - Aggro');

-- Lenore the Hoarder spells: MobSpells capture (cachedata MobSpells.lua); timers are estimated.
DELETE FROM `smart_scripts` WHERE `entryorguid`=991515 AND `source_type`=0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(991515, 0, 0, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lenore the Hoarder - On Aggro - Say Line 0'),
(991515, 0, 1, 0, 0, 0, 100, 0, 5000, 8000, 15000, 20000, 0, 0, 11, 12024, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Lenore the Hoarder - In Combat - Cast ''Net'''),
(991515, 0, 2, 0, 0, 0, 100, 0, 3000, 6000, 7000, 10000, 0, 0, 11, 992957, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Lenore the Hoarder - In Combat - Cast ''Sinister Strike''');

-- Protector Brenolt and Captain Olens talk as seen in footage; the repeat interval is estimated.
DELETE FROM `creature_text` WHERE `CreatureID` IN (776787,776786);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`,
  `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(776787, 0, 0, 'Recruitment rates are high, the promise of revenge against the Defias and a hot meal are appealing to many.', 12, 0, 100, 1, 0, 0, 0, 0, 'Protector Brenolt - Militia talk 1'),
(776786, 0, 0, 'An army of farmers against an army of thieves. They may have the heart, but not the skill. We need more time.', 12, 0, 100, 1, 0, 0, 0, 0, 'Captain Olens - Militia talk 2'),
(776787, 1, 0, 'Any news about the reinforcements from Stormwind, sir?', 12, 0, 100, 1, 0, 0, 0, 0, 'Protector Brenolt - Militia talk 3'),
(776786, 1, 0, 'You know they''re not coming, Brenolt. We''re on our own out here.', 12, 0, 100, 1, 0, 0, 0, 0, 'Captain Olens - Militia talk 4');
DELETE FROM `smart_scripts` WHERE (`entryorguid`=776787 AND `source_type`=0) OR (`entryorguid`=77678700 AND `source_type`=9);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(776787, 0, 0, 0, 1, 0, 100, 0, 30000, 60000, 240000, 300000, 0, 0, 80, 77678700, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Protector Brenolt - Out of Combat - Run Militia talk'),
(77678700, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Protector Brenolt - Militia talk - Protector Brenolt Say Line 0'),
(77678700, 9, 1, 0, 0, 0, 100, 0, 6000, 6000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 19, 776786, 15, 0, 0, 0, 0, 0, 0, 'Protector Brenolt - Militia talk - Captain Olens Say Line 0'),
(77678700, 9, 2, 0, 0, 0, 100, 0, 6000, 6000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Protector Brenolt - Militia talk - Protector Brenolt Say Line 1'),
(77678700, 9, 3, 0, 0, 0, 100, 0, 6000, 6000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 19, 776786, 15, 0, 0, 0, 0, 0, 0, 'Protector Brenolt - Militia talk - Captain Olens Say Line 1');

DELETE FROM `npc_text` WHERE `ID`=9950100;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `em0_0`, `em0_1`,
  `em0_2`, `em0_3`, `em0_4`, `em0_5`, `text1_0`, `text1_1`, `BroadcastTextID1`, `lang1`, `Probability1`, `em1_0`,
  `em1_1`, `em1_2`, `em1_3`, `em1_4`, `em1_5`, `text2_0`, `text2_1`, `BroadcastTextID2`, `lang2`, `Probability2`,
  `em2_0`, `em2_1`, `em2_2`, `em2_3`, `em2_4`, `em2_5`, `text3_0`, `text3_1`, `BroadcastTextID3`, `lang3`,
  `Probability3`, `em3_0`, `em3_1`, `em3_2`, `em3_3`, `em3_4`, `em3_5`, `text4_0`, `text4_1`, `BroadcastTextID4`,
  `lang4`, `Probability4`, `em4_0`, `em4_1`, `em4_2`, `em4_3`, `em4_4`, `em4_5`, `text5_0`, `text5_1`,
  `BroadcastTextID5`, `lang5`, `Probability5`, `em5_0`, `em5_1`, `em5_2`, `em5_3`, `em5_4`, `em5_5`, `text6_0`,
  `text6_1`, `BroadcastTextID6`, `lang6`, `Probability6`, `em6_0`, `em6_1`, `em6_2`, `em6_3`, `em6_4`, `em6_5`,
  `text7_0`, `text7_1`, `BroadcastTextID7`, `lang7`, `Probability7`, `em7_0`, `em7_1`, `em7_2`, `em7_3`, `em7_4`,
  `em7_5`, `VerifiedBuild`) VALUES
(9950100, 'We must do what we can to press back the Defias. Most of us aren''t fighters, but I''ve spent enough time on both the farms and the front to teach a fool how to replace a pitchfork with a sword. If you want to help out the recruits, or get some practice of your own, feel free. Otherwise report to Captain Danuven, we need all the hands we can get - assuming they''re capable, of course.', '', 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
DELETE FROM `gossip_menu` WHERE `MenuID`=9950100;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(9950100, 9950100);

-- Militia Recruit greetings: npc_text 58274, Ascension npccache.wdb capture of 2026-09-05. The sparring
-- option text and the recruits' wander distance are estimated.
DELETE FROM `npc_text` WHERE `ID`=58274;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `em0_0`, `em0_1`,
  `em0_2`, `em0_3`, `em0_4`, `em0_5`, `text1_0`, `text1_1`, `BroadcastTextID1`, `lang1`, `Probability1`, `em1_0`,
  `em1_1`, `em1_2`, `em1_3`, `em1_4`, `em1_5`, `text2_0`, `text2_1`, `BroadcastTextID2`, `lang2`, `Probability2`,
  `em2_0`, `em2_1`, `em2_2`, `em2_3`, `em2_4`, `em2_5`, `text3_0`, `text3_1`, `BroadcastTextID3`, `lang3`,
  `Probability3`, `em3_0`, `em3_1`, `em3_2`, `em3_3`, `em3_4`, `em3_5`, `text4_0`, `text4_1`, `BroadcastTextID4`,
  `lang4`, `Probability4`, `em4_0`, `em4_1`, `em4_2`, `em4_3`, `em4_4`, `em4_5`, `text5_0`, `text5_1`,
  `BroadcastTextID5`, `lang5`, `Probability5`, `em5_0`, `em5_1`, `em5_2`, `em5_3`, `em5_4`, `em5_5`, `text6_0`,
  `text6_1`, `BroadcastTextID6`, `lang6`, `Probability6`, `em6_0`, `em6_1`, `em6_2`, `em6_3`, `em6_4`, `em6_5`,
  `text7_0`, `text7_1`, `BroadcastTextID7`, `lang7`, `Probability7`, `em7_0`, `em7_1`, `em7_2`, `em7_3`, `em7_4`,
  `em7_5`, `VerifiedBuild`) VALUES
(58274, 'Why am I wasting this time ''training''? I could be out there taking back my farm and putting all those Defias scum to the sword!', 'Why am I wasting this time ''training''? I could be out there taking back my farm and putting all those Defias scum to the sword!', 0, 0, 0.25, 0, 0, 0, 0, 0, 0, 'I don''t know about this… I''ve been practicing for so long but I still feel like its my first day. This is hopeless…', 'I don''t know about this… I''ve been practicing for so long but I still feel like its my first day. This is hopeless…', 0, 0, 0.25, 0, 0, 0, 0, 0, 0, 'Eugh, what do you want? Can''t you see I''m busy?', 'Eugh, what do you want? Can''t you see I''m busy?', 0, 0, 0.25, 0, 0, 0, 0, 0, 0, 'Hi there! Need some practice?', 'Hi there! Need some practice?', 0, 0, 0.25, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
DELETE FROM `gossip_menu` WHERE `MenuID`=58274;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(58274, 58274);
DELETE FROM `gossip_menu_option` WHERE `MenuID`=58274;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`,
  `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`,
  `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(58274, 0, 0, 'Let''s practice.', 0, 1, 1, 0, 0, 0, 0, '', 0, 0);

-- Greetings and Brother Alric's option: Sentinel Hill footage (YouTube F6vp8CJOTGk). Hank Dullahan's option
-- is Randal Hunter's (gossip menu 4018).
DELETE FROM `npc_text` WHERE `ID` IN (9950101,9950102,9950103,9950104);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `em0_0`, `em0_1`,
  `em0_2`, `em0_3`, `em0_4`, `em0_5`, `text1_0`, `text1_1`, `BroadcastTextID1`, `lang1`, `Probability1`, `em1_0`,
  `em1_1`, `em1_2`, `em1_3`, `em1_4`, `em1_5`, `text2_0`, `text2_1`, `BroadcastTextID2`, `lang2`, `Probability2`,
  `em2_0`, `em2_1`, `em2_2`, `em2_3`, `em2_4`, `em2_5`, `text3_0`, `text3_1`, `BroadcastTextID3`, `lang3`,
  `Probability3`, `em3_0`, `em3_1`, `em3_2`, `em3_3`, `em3_4`, `em3_5`, `text4_0`, `text4_1`, `BroadcastTextID4`,
  `lang4`, `Probability4`, `em4_0`, `em4_1`, `em4_2`, `em4_3`, `em4_4`, `em4_5`, `text5_0`, `text5_1`,
  `BroadcastTextID5`, `lang5`, `Probability5`, `em5_0`, `em5_1`, `em5_2`, `em5_3`, `em5_4`, `em5_5`, `text6_0`,
  `text6_1`, `BroadcastTextID6`, `lang6`, `Probability6`, `em6_0`, `em6_1`, `em6_2`, `em6_3`, `em6_4`, `em6_5`,
  `text7_0`, `text7_1`, `BroadcastTextID7`, `lang7`, `Probability7`, `em7_0`, `em7_1`, `em7_2`, `em7_3`, `em7_4`,
  `em7_5`, `VerifiedBuild`) VALUES
(9950101, 'I came to Westfall the moment I heard. I thought, perhaps I could be of use, offer some light in the dark. But this land... it swallows hope. Every wound I tend, more open. Every prayer feels hollow. Maybe I was foolish. Maybe I should just return to Stormwind. My bed is still warm there. My conscience... quieter.', '', 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9950102, 'This place is so different from Stormwind, don''t you think? I miss my studies, but this place lets me see the stars so clearly. When Thor asked me to come live with him I was hesitant, but now, I''m glad I came. Oh, and speaking of Thor... If you find a free moment to chat with him, tell him I''m borrowing his hammer to repair this ratty old shelf. I don''t know why he''s so protective over the thing, it''s not like he even uses it as a gryphon master...', '', 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9950103, 'Stormwind has abandoned us and the peasants are raising their pitchforks. It''s hopeless. We''re all going to die and I don''t know about you, but I plan to be on the winning side. I''ve lost enough already, I don''t want to lose my life too.', '', 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9950104, 'Hello! Ready for some training?', '', 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
DELETE FROM `gossip_menu` WHERE `MenuID` IN (9950101,9950102,9950103,9950104);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(9950101, 9950101),
(9950102, 9950102),
(9950103, 9950103),
(9950104, 9950104);
DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (9950101,9950102,9950103,9950104);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`,
  `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`,
  `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(9950101, 0, 0, 'Even a single spark can guide the lost, Brother. Westfall needs that light, and so do we.', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(9950104, 0, 3, 'I seek training to ride a steed.', 7548, 5, 16, 0, 0, 0, 0, '', 0, 0);

-- Sentinel Hill speech from the footage (YouTube F6vp8CJOTGk); how often each line repeats is estimated.
DELETE FROM `creature_text` WHERE `CreatureID` IN (255151,255152,265154,449328,776780);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`,
  `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(449328, 0, 0, 'The light burns like a flame within us all, even here. Though it may feel more like a... slightly warm breeze rather than a comforting fire.', 12, 0, 100, 1, 0, 0, 0, 0, 'Brother Alric - Out of Combat'),
(449328, 0, 1, 'We must all stay calm and be ready to assist those who need our help most. I''m here to help you all, even if I''m... starting to wish I wasn''t.', 12, 0, 100, 1, 0, 0, 0, 0, 'Brother Alric - Out of Combat'),
(449328, 1, 0, 'You''re right. Even a dying candle still pushes back the dark. I cannot heal the whole of Westfall, but I can heal someone. And that will be enough. Thank you, truly.', 12, 0, 100, 1, 0, 0, 0, 0, 'Brother Alric - Gossip Option Selected'),
(255152, 0, 0, 'We''re all going to die, aren''t we?', 12, 0, 100, 1, 0, 0, 0, 0, 'Displaced Farmer - Out of Combat'),
(255152, 0, 1, 'This isn''t helping!', 12, 0, 100, 1, 0, 0, 0, 0, 'Displaced Farmer - Out of Combat'),
(776780, 0, 0, 'Come on Bella, just one more bucket... our defenders are thirsty!', 12, 0, 100, 1, 0, 0, 0, 0, 'Marianna Carson - Milking'),
(265154, 0, 0, 'Moo.', 12, 0, 100, 0, 0, 0, 0, 0, 'Bella - Milking'),
(255151, 0, 0, 'Yes, Ma...', 12, 0, 100, 1, 0, 0, 0, 0, 'Tavin Wyther - Out of Combat');
DELETE FROM `smart_scripts` WHERE (`entryorguid` IN (449328,255152,776780,255151) AND `source_type`=0) OR
  (`entryorguid`=77678000 AND `source_type`=9);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(449328, 0, 0, 1, 62, 0, 100, 0, 9950101, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Brother Alric - On Gossip Option 0 Selected - Close Gossip'),
(449328, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Brother Alric - On Link - Say Line 1'),
(449328, 0, 2, 0, 1, 0, 100, 0, 60000, 120000, 240000, 360000, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Brother Alric - Out of Combat - Say Line 0'),
(255152, 0, 0, 0, 1, 0, 100, 0, 60000, 180000, 300000, 600000, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Displaced Farmer - Out of Combat - Say Line 0'),
(776780, 0, 0, 0, 1, 0, 100, 0, 30000, 60000, 180000, 240000, 0, 0, 80, 77678000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Marianna Carson - Out of Combat - Run Milking talk'),
(77678000, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Marianna Carson - Milking talk - Say Line 0'),
(77678000, 9, 1, 0, 0, 0, 100, 0, 3000, 3000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 19, 265154, 15, 0, 0, 0, 0, 0, 0, 'Marianna Carson - Milking talk - Bella Say Line 0'),
(255151, 0, 0, 0, 1, 0, 100, 0, 120000, 300000, 600000, 900000, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Tavin Wyther - Out of Combat - Say Line 0');

-- Gryan Stoutmantle and Captain Danuvin exchange their existing lines on the tower, as in the footage
-- (YouTube F6vp8CJOTGk); the repeat interval is estimated.
DELETE FROM `smart_scripts` WHERE (`entryorguid`=234 AND `source_type`=0 AND `id`=1) OR
  (`entryorguid`=23400 AND `source_type`=9);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(234, 0, 1, 0, 1, 0, 100, 0, 60000, 120000, 240000, 360000, 0, 0, 80, 23400, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gryan Stoutmantle - Out of Combat - Run Tower talk'),
(23400, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gryan Stoutmantle - Tower talk - Say Line 1'),
(23400, 9, 1, 0, 0, 0, 100, 0, 6000, 6000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 19, 821, 15, 0, 0, 0, 0, 0, 0, 'Gryan Stoutmantle - Tower talk - Captain Danuvin Say Line 0');

DELETE FROM `creature` WHERE `guid` BETWEEN 9950100 AND 9950116;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
  `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
  `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
  `CreateObject`, `Comment`) VALUES
(9950100, 776786, 0, 40, 108, 1, 1, 0, -10718.9, 980.03, 36.77, 3.1, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Captain Olens (client SuperTrack 21342, training yard; facing estimated)'),
(9950101, 255339, 0, 40, 108, 1, 1, 0, -10731.5, 978.0, 36.84, 2.7, 120, 3, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Militia Recruit (estimated position and wander distance, training yard)'),
(9950102, 255339, 0, 40, 108, 1, 1, 0, -10740.5, 971.5, 36.92, 2.71, 120, 3, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Militia Recruit (estimated position and wander distance, training yard)'),
(9950103, 255339, 0, 40, 108, 1, 1, 0, -10736.5, 975.5, 36.91, 3.43, 120, 3, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Militia Recruit (estimated position and wander distance, training yard)'),
(9950104, 255339, 0, 40, 108, 1, 1, 0, -10737.5, 989.5, 36.73, 2.46, 120, 3, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Militia Recruit (estimated position and wander distance, training yard)'),
(9950105, 255150, 0, 40, 108, 1, 1, 0, -10511.37, 1147.09, 40.0, 1.02, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Idona Wyther (estimated position, alchemist''s farmhouse)'),
(9950106, 776790, 0, 40, 108, 1, 1, 0, -10679.3, 957.9, 38.47, 2.64, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Archivist Selnor (Sentinel Hill library rug between the reading tables, as in the footage; client SuperTrack 21338 marks the library)'),
(9950107, 991515, 0, 40, 40, 1, 1, 0, -10265.7, 1782.1, 74.83, 5.82, 600, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Lenore the Hoarder (client SuperTrack 8525, Defias tower upper floor; facing estimated)'),
(9950108, 157002, 0, 40, 921, 1, 1, 0, -11137.8, 1817.78, 38.96, 5.05, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Farmer Demont (client SuperTrack 3308, Demont''s Place; facing estimated)'),
(9950109, 455339, 0, 40, 40, 1, 1, 0, -9976.29, 955.25, 31.96, 2.2, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Slain Protector (client SuperTrack 21334)'),
(9950110, 455343, 0, 40, 922, 1, 1, 0, -11030.0, 790.0, 37.55, 1, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Half-Devoured Protector (estimated position, Riverpaw camp)'),
(9950111, 255339, 0, 40, 108, 1, 1, 0, -10734.0, 985.0, 36.75, 3.5, 120, 3, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Militia Recruit (estimated position and wander distance, training yard)'),
(9950112, 255339, 0, 40, 108, 1, 1, 0, -10733.0, 994.5, 36.22, 2.74, 120, 3, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Militia Recruit (estimated position and wander distance, training yard)'),
(9950113, 255339, 0, 40, 108, 1, 1, 0, -10729.0, 990.0, 36.25, 2.46, 120, 3, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Militia Recruit (estimated position and wander distance, training yard)'),
(9950114, 255339, 0, 40, 108, 1, 1, 0, -10738.5, 981.5, 36.88, 2.78, 120, 3, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Militia Recruit (estimated position and wander distance, training yard)'),
(9950115, 255151, 0, 40, 108, 1, 1, 0, -10509.95, 1144.83, 40.0, 3.48, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Tavin Wyther (estimated position, alchemist''s farmhouse)'),
(9950116, 776787, 0, 40, 108, 1, 1, 0, -10724.26, 988.23, 36.25, 0.77, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Protector Brenolt (estimated position, training yard by Olens)');

-- Sentinel Hill residents placed where the footage shows them (YouTube F6vp8CJOTGk); positions and facings
-- are estimated, heights are the ground, WMO floor, town hall stage or wall bench.
DELETE FROM `creature` WHERE `guid` BETWEEN 9950130 AND 9950154;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
  `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
  `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
  `CreateObject`, `Comment`) VALUES
(9950130, 255153, 0, 40, 108, 1, 1, 0, -10705.0, 969.8, 39.83, 5.88, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Mayor Leighton (town hall, behind the stage podium); Sentinel Hill footage, position estimated'),
(9950131, 776784, 0, 40, 108, 1, 1, 0, -10606.8, 1044.6, 36.29, 3.71, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Jane Foster (Thor''s house); Sentinel Hill footage, position estimated'),
(9950132, 22816, 0, 40, 108, 1, 1, 0, -10604.5, 1047.0, 36.29, 4, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Black Cat (Thor''s house); Sentinel Hill footage, position estimated'),
(9950133, 776780, 0, 40, 108, 1, 1, 0, -10517.3, 1178.8, 36.8, 0.75, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Marianna Carson (barn, milking Bella); Sentinel Hill footage, position estimated'),
(9950134, 265154, 0, 40, 108, 1, 1, 0, -10515.8, 1180.2, 36.81, 3.89, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Bella (barn, clear of the barrels and the stall rail); Sentinel Hill footage, position estimated'),
(9950135, 256249, 0, 40, 108, 1, 1, 0, -10520.5, 1137.0, 39.7, 0.88, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Snuggles (asleep by the doghouse); Sentinel Hill footage, position estimated'),
(9950136, 449328, 0, 40, 108, 1, 1, 0, -10584.5, 1041.5, 35.06, 0.9, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Brother Alric (refugee camp, facing the campfire); Sentinel Hill footage, position estimated'),
(9950137, 255152, 0, 40, 108, 1, 1, 0, -10583.0, 1047.5, 35.31, 5.14, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Displaced Farmer (refugee camp); Sentinel Hill footage, position estimated'),
(9950138, 255152, 0, 40, 108, 1, 1, 0, -10579.0, 1042.0, 35.12, 2.34, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Displaced Farmer (refugee camp); Sentinel Hill footage, position estimated'),
(9950139, 255152, 0, 40, 108, 1, 1, 0, -10650.9, 971.0, 36.63, 1, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Displaced Farmer (market camp, beside the campfire); Sentinel Hill footage, position estimated'),
(9950140, 255152, 0, 40, 108, 1, 1, 0, -10688.24, 970.98, 39.36, 2.74, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Displaced Farmer (town hall, asleep on the right wall bench); Sentinel Hill footage, position estimated'),
(9950141, 255152, 0, 40, 108, 1, 1, 0, -10521.5, 1176.0, 36.76, 1.6, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Displaced Farmer (barn); Sentinel Hill footage, position estimated'),
(9950142, 776785, 0, 40, 108, 1, 1, 0, -10656.92, 1060.84, 33.96, 5.66, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Hank Dullahan (stable aisle entrance, left post); Sentinel Hill footage, position estimated'),
(9950143, 12375, 0, 40, 108, 1, 1, 0, -10658.28, 1058.98, 33.96, 5.66, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Chestnut Mare (by Hank Dullahan, left stall fence); Sentinel Hill footage, position estimated'),
(9950144, 12376, 0, 40, 108, 1, 1, 0, -10663.65, 1069.45, 34.09, 5.66, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Brown Horse (end of the stable aisle); Sentinel Hill footage, position estimated'),
(9950145, 12376, 0, 40, 108, 1, 1, 0, -10656.38, 1070.09, 34.02, 4.4, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Brown Horse (right stall); Sentinel Hill footage, position estimated'),
(9950146, 776791, 0, 40, 108, 1, 1, 0, -10683.0, 943.0, 37.12, 5.42, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Scheming Protector (alley behind the town hall); Sentinel Hill footage, position estimated'),
(9950147, 776792, 0, 40, 108, 1, 1, 0, -10681.8, 941.6, 37.13, 2.28, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Scheming Protector (alley behind the town hall); Sentinel Hill footage, position estimated'),
(9950148, 776788, 0, 40, 108, 1, 1, 1, -10704.5, 966.0, 39.83, 5.6, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Protector Murphy (town hall stage, left of the podium); Sentinel Hill footage, position estimated'),
(9950149, 776783, 0, 40, 108, 1, 1, 0, -10695.46, 956.71, 38.47, 1.16, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Everard Handor (town hall, seated on the left wall bench); Sentinel Hill footage, position estimated'),
(9950150, 776778, 0, 40, 108, 1, 1, 0, -10694.98, 958.09, 38.47, 4.38, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Melissa Norman (town hall, standing by Everard Handor); Sentinel Hill footage, position estimated'),
(9950151, 776779, 0, 40, 108, 1, 1, 0, -10694.42, 956.86, 38.47, 2, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Ethan Norman (town hall, beside Melissa Norman); Sentinel Hill footage, position estimated'),
(9950152, 776781, 0, 40, 108, 1, 1, 0, -10691.87, 972.65, 38.47, 4.31, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Willow Brelor (town hall, seated on the right wall bench); Sentinel Hill footage, position estimated'),
(9950153, 776782, 0, 40, 108, 1, 1, 0, -10699.5, 973.5, 38.47, 2.74, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Sally Vernal (town hall, right end of the third pew); Sentinel Hill footage, position estimated'),
(9950154, 255152, 0, 40, 108, 1, 1, 0, -10697.56, 973.35, 38.47, 2.74, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Displaced Farmer (town hall, right wall by the stage); Sentinel Hill footage, position estimated');

-- The seated and sleeping town hall residents, as in the footage.
DELETE FROM `creature_addon` WHERE `guid` BETWEEN 9950130 AND 9950154;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
  `auras`) VALUES
(9950140, 0, 0, 3, 1, 0, 0, NULL),
(9950149, 0, 0, 5, 1, 0, 0, NULL),
(9950152, 0, 0, 5, 1, 0, 0, NULL);

-- Lenore the Hoarder (991515) loot: Exiles DB export 2026-09-13, creature_loot entry 991515.
DELETE FROM `creature_loot_template` WHERE `Entry`=991515;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(991515, 9771, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 14127, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 14133, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 14165, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 14179, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 15117, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 15122, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 15124, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 15329, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 15330, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 15500, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 15511, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 15512, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 15513, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 15517, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 15526, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 15972, 0, 0.012, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 554126, 0, 0.417, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 1013664, 0, 0.417, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 1013673, 0, 0.417, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 1013677, 0, 0.417, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 1013679, 0, 0.417, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 1013977, 0, 0.417, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 2089832, 0, 3.125, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 2089833, 0, 3.125, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 2089834, 0, 3.125, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 2089835, 0, 3.125, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 2089836, 0, 3.125, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 2089837, 0, 3.125, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 2089838, 0, 3.125, 0, 1, 0, 1, 1, 'Lenore the Hoarder'),
(991515, 2089839, 0, 3.125, 0, 1, 0, 1, 1, 'Lenore the Hoarder');

-- Reef Shark (12123) spawns: Exiles DB export 2026-09-13, creature_spawn guids 60841-60844.
DELETE FROM `creature` WHERE `guid` BETWEEN 9950120 AND 9950123;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
  `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
  `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
  `CreateObject`, `Comment`) VALUES
(9950120, 12123, 0, 40, 40, 1, 1, 0, -11327.4, 2292.78, -48.1677, 0, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Reef Shark (Exiles DB export 2026-09-13)'),
(9950121, 12123, 0, 40, 40, 1, 1, 0, -10638.2, 2354.37, -49.2443, 0, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Reef Shark (Exiles DB export 2026-09-13)'),
(9950122, 12123, 0, 40, 40, 1, 1, 0, -9985.74, 2374.5, -49.2355, 0, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Reef Shark (Exiles DB export 2026-09-13)'),
(9950123, 12123, 0, 40, 40, 1, 1, 0, -9783.67, 2353.35, -49.3094, 0, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Reef Shark (Exiles DB export 2026-09-13)');

-- Westfall Hoard (480104): Ascension's object id for it is unknown. Loosely Packed Dirt, Waterlogged Trunk
-- and Wanted: Lenore the Hoarder: WDB gameobject cache 2026-09-09..10.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`,
  `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`,
  `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
(480101, 3, 6448, 'Pilfered Lesser Healing Potions', '', '', '', 1, 43, 480101, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(480102, 3, 6448, 'Pilfered Minor Healing Potions', '', '', '', 1, 43, 480102, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(480103, 3, 6448, 'Pilfered Elixirs', '', '', '', 1, 43, 480103, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(480104, 3, 36, 'Westfall Hoard', '', '', '', 1, 43, 480104, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(96004, 3, 20, 'Loosely Packed Dirt', '', '', '', 0.5, 43, 96004, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(96005, 2, 1, 'Waterlogged Trunk', '', '', '', 1.33, 43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(518551, 2, 2491, 'Wanted: Lenore the Hoarder', '', '', '', 1, 0, 93, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
  `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `unk1` = VALUES(`unk1`),
  `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`),
  `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`),
  `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`),
  `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`),
  `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`),
  `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`),
  `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`),
  `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `gameobject_template_addon` WHERE `entry` BETWEEN 480101 AND 480104;
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`, `mingold`, `maxgold`, `artkit0`, `artkit1`,
  `artkit2`, `artkit3`) VALUES
(480101, 0, 4, 0, 0, 0, 0, 0, 0),
(480102, 0, 4, 0, 0, 0, 0, 0, 0),
(480103, 0, 4, 0, 0, 0, 0, 0, 0),
(480104, 0, 4, 0, 0, 0, 0, 0, 0);

DELETE FROM `gameobject_loot_template` WHERE `Entry` BETWEEN 480101 AND 480104;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
  `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(480101, 480201, 0, 100, 1, 1, 0, 1, 1, 'Pilfered Lesser Healing Potions'),
(480102, 480202, 0, 100, 1, 1, 0, 1, 1, 'Pilfered Minor Healing Potions'),
(480103, 480203, 0, 100, 1, 1, 0, 1, 1, 'Pilfered Elixirs'),
(480104, 1252801, 0, 100, 1, 1, 0, 1, 1, 'Westfall Hoard');

-- Estimated: the map text says the treasure map lies buried under the dirt, so it always drops.
DELETE FROM `gameobject_loot_template` WHERE `Entry`=96004;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
  `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(96004, 157016, 0, 100, 0, 1, 0, 1, 1, 'Loosely Packed Dirt - Faded Treasure Map');

DELETE FROM `gameobject` WHERE `guid` BETWEEN 9001100 AND 9001106;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9001100, 480101, 0, 40, 919, 1, 1, -10723.1, 1391.13, 35.37, 1.2, 0, 0, 0.564642, 0.825336, 900, 100, 1, '', 0, 'Pilfered Lesser Healing Potions (client SuperTrack 21332; facing estimated)'),
(9001101, 480102, 0, 40, 111, 1, 1, -9999.35, 1469.87, 40.89, 2.5, 0, 0, 0.948985, 0.315322, 900, 100, 1, '', 0, 'Pilfered Minor Healing Potions (client SuperTrack 21330; facing estimated)'),
(9001102, 480103, 0, 40, 40, 1, 1, -9845.18, 1036.06, 33.41, 4, 0, 0, 0.909297, -0.416147, 900, 100, 1, '', 0, 'Pilfered Elixirs (client SuperTrack 21331; facing estimated)'),
(9001103, 480104, 0, 40, 40, 1, 1, -10258.8, 1767.37, 50.18, 5.82, 0, 0, 0.229528, -0.973302, 900, 100, 1, '', 0, 'Westfall Hoard (client SuperTrack 8526, Defias tower middle floor; facing estimated)'),
(9001104, 96004, 0, 40, 40, 1, 1, -10377.0, 2196.17, 20.431, 0, 0, 0, 0, 1, 900, 100, 1, '', 0, 'Loosely Packed Dirt (catalogue position, orientation unknown)'),
(9001105, 96005, 0, 40, 40, 1, 1, -9783.71, 1819.44, -8.025, 0, 0, 0, 0, 1, 900, 100, 1, '', 0, 'Waterlogged Trunk (catalogue position, orientation unknown)'),
(9001106, 518551, 0, 40, 108, 1, 1, -10646.1, 1157.59, 32.996, 0, 0, 0, 0, 1, 900, 100, 1, '', 0, 'Wanted: Lenore the Hoarder (catalogue position, orientation unknown)');

-- 999914 and 999933 are autocomplete (Method 0) in the WDB capture; QuestType 2 keeps them in the log
-- until the report reaches Archivist Selnor.
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`,
  `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`,
  `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`,
  `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`,
  `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`,
  `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`,
  `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`,
  `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`,
  `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`,
  `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`,
  `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`,
  `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`,
  `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`,
  `RewardFactionValue5`, `RewardFactionOverride5`, `TimeAllowed`, `AllowableRaces`, `LogTitle`, `LogDescription`,
  `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`,
  `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`,
  `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`,
  `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`,
  `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `Unknown0`, `ObjectiveText1`, `ObjectiveText2`,
  `ObjectiveText3`, `ObjectiveText4`, `VerifiedBuild`)
VALUES
(1313, 2, 12, 10, 40, 0, 0, 0, 0, 0, 0, 0, 5, 0, 270, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2457, 2, 2454, 2, 3383, 2, 2458, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Potions for Sentinel Hill', 'Recover the stolen potions from the Defias camps in Westfall.', 'I know the militia relies on my potions, but when those damned thieves steal half of my store - how can I ever hope to keep up?$B$BEarlier this week, the Defias stole three crates ready to distribute to the People''s Militia. Our defenders need those potions! Retrieve them, and I''ll give you a few to keep you safe as well.', '', 'Return the potions to Idona Wyther', 0, 0, 0, 0, 0, 0, 0, 0, 480201, 480202, 480203, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 'Pilfered Lesser Healing Potions', 'Pilfered Minor Healing Potions', 'Pilfered Elixirs', '', 0),
(17011, 2, 11, 10, 40, 0, 0, 0, 0, 0, 0, 0, 6, 500, 375, 0, 0, 0, 0, 0, 8, 0, 1397886, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Riverpaw Genocide', 'Slay 8 Riverpaw Brutes, 12 Riverpaw Mongrels, and 10 Riverpaw Herbalists.', 'Confoundit, $N, look at my farm! Not that there''s much to look at nowadays. It wasn''t much to begin with, but I had ambition! Now... now I have nothing, and it''s all because of those damn gnolls!$B$BListen $N, I don''t have much, but give a poor farmer what''s owed to him—revenge! I want you to go out there and slay every last gnoll you find. Every. Last. One.$B$BOnce you''ve dealt with at least 8 Riverpaw Brutes, 12 Riverpaw Mongrels, and 10 Riverpaw Herbalists then return here to me for your reward. You should be able to find these gnolls to the West and then more to the North, parallel to the coast. And $N, I wouldn''t mind if you lost count after a while, if you know what I mean.', '', 'Slay 8 Riverpaw Brutes, 12 Riverpaw Mongrels, and 10 Riverpaw Herbalists.', 124, 123, 501, 0, 10, 8, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(17012, 2, 13, 10, 40, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 375250, 125, 1397886, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 157018, 1, 157019, 1, 157020, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Riverpaw Genocide', 'Slay 12 Riverpaw Bandits, 10 Riverpaw Taskmasters, and 8 Riverpaw Mystics.', 'You''ve already done a poor farmer a great service, $N, but my revenge is not yet sated. Not while there are still gnolls alive a drawing breath.$B$BI know there''s another encampment of gnolls to the East. I want them dead! Slay at least 12 Riverpaw Bandits, 10 Riverpaw Taskmasters and 8 Riverpaw Mystics, and maybe then I can finally be at peace. At least as much peace as one can be with his hope and dreams laid bare before him.', '', 'Slay 12 Riverpaw Bandits, 10 Riverpaw Taskmasters, and 8 Riverpaw Mystics.', 452, 98, 453, 0, 12, 10, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(17014, 2, 17, 10, 40, 0, 0, 0, 0, 0, 0, 0, 5, 1000, 660, 0, 0, 0, 0, 0, 0, 0, 375250, 100, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Killing Fields', 'Farmer Saldean wants you to kill 15 Harvest Reapers.', '$N, after seeing what you''re capable of I think I have another offer to make. You see, the Harvest Watchers aren''t the only things that have claimed these once fertile farmlands.$B$BTo the Southeast of here is what they now call the Dead Acre. There you will find Harvest Reapers. They''re just like the Harvest Watchers only meaner, but I don''t think that will be a problem for you.$B$BCome back to me once you''ve slain 15 of ''em and I''ll make sure it''s worth your time.', '', 'Return to Farmer Saldean at Saldean''s Farm in Westfall.', 115, 0, 0, 0, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(26993, 2, -1, 10, 40, 0, 0, 0, 0, 0, 0, 26994, 5, 300, 223, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 0, 10000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Killing Fields', 'Slay 10 Rusty Harvest Golems and return to Farmer Furlbrow at The Jansen Stead.', 'Look at the state of these lands! Curse the Defias Brotherhood, with their goblins making mechanical terrors and sending them out on these fields! We farmers didn''t want any of this. How am I to feed my family and poor Old Blanchy if these golems are here?$B$BCan you help get rid of the golems nearby? You can find them just around here, and over west, by my pumpkin farm. Please help us! Stormwind has given up on us.', '', 'Return to Farmer Furlbrow in Westfall.', 480, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(26994, 2, -1, 10, 40, 0, 0, 0, 0, 0, 0, 26995, 2, 0, 52, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 0, 2500, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Killing Fields', 'Speak to Farmer Saldean at Saldean''s Farm.', 'You''ve made good work of the golems around here, but I''m not the only one dealing with this. My good friend, Saldean, also told me the golems are destroying his farm. Do you think you could assist him? You''ll find his farm just south of here.', '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(26995, 2, -1, 12, 40, 0, 0, 0, 0, 0, 0, 26996, 5, 400, 236, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 0, 10000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Killing Fields', 'Slay 10 Harvest Golems and return to Farmer Saldean at Saldean''s Farm.', 'I''m glad to see someone helping out around here. These golems are frightening off our citizens, and if we don''t get this sorted out soon, I fear Westfall will be overrun and taken by The Defias Brotherhood. Anyways, get out there and kill some golems! You can find some right on this farm, or at the Molsen Farm over to the west.', '', 'Return to Farmer Saldean in Westfall.', 36, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(26996, 2, 17, 12, 40, 0, 0, 0, 0, 0, 0, 26997, 5, 600, 450, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 0, 10000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Killing Fields', 'Slay 10 Harvest Watchers and return to Farmer Saldean at Saldean''s Farm.', 'Those golems you killed earlier aren''t the only ones damaging our lands! One of my farmers claims he saw some more out by The Alexston Farmstead, near the Gold Coast Quarry. If you wouldn''t mind killing some more golems, your assistance would be most appreciated.', '', 'Return to Farmer Saldean in Westfall.', 114, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(26997, 2, 17, 12, 40, 0, 0, 0, 0, 0, 0, 0, 6, 0, 585, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1561, 1, 3578, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 0, 10000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Killing Fields', 'Slay 10 Harvest Reapers and return to Farmer Saldean at Saldean''s Farm.', 'Most of our farms have been reclaimed, but there is one farm left to fight for. Far south of here, past Sentinel Hill, you will find The Dead Acre, where the most powerful golems roam and scorch the land. I tried to bring a few workers there, but the golems chased us away! I hope you''re up to the task $n, these golems are no joke!', '', 'Return to Farmer Saldean in Westfall.', 115, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(254042, 2, 12, 9, 40, 1, 3, 0, 0, 0, 0, 0, 5, 375, 202, 0, 0, 0, 0, 0, 0, 0, 375250, 100, 1397886, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Wanted: Lenore the Hoarder', 'Kill Lenore the Hoarder and return to Protector Gariel at Sentinel Hill.', 'Wanted: Lenore the Hoarder$B$BBy order of the People''s Militia, Lenore the Hoarder is hereby declared a threat to the stability of Westfall.$B$BThis individual is responsible for orchestrating repeated raids on supply caravans bound for militia outposts. Reports confirm she is stockpiling stolen goods and distributing them to Defias agents operating in the region.$B$BShe is clever, fast, and rarely seen twice in the same place. Do not underestimate her.', '', 'Report to Protector Gariel at Sentinel Hill in Westfall.', 991515, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(254043, 2, 12, 9, 40, 0, 0, 0, 0, 0, 0, 0, 5, 375, 202, 0, 0, 0, 0, 0, 0, 0, 375250, 100, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Take It Back', 'Protector Gariel wants you to gather Westfall Supplies, then return to her at Sentinel Hill.', 'We are stretched thin out here. Rations are low, morale is worse, and every night another crate goes missing. The Defias are relentless, picking us apart while we try to hold what little ground we have left.$B$BWord is they are stashing stolen goods somewhere nearby. Not just scraps either. Real supplies, food, bandages, tools, maybe even weapons. We have reason to believe they are hiding them in that old tower to the west.$B$BIf you can make your way in and recover anything useful, it could turn the tide out here. The militia is doing what it can, but we need every edge we can get.', '', 'Report to Protector Gariel at Sentinel Hill in Westfall', 0, 0, 0, 0, 0, 0, 0, 0, 1252801, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(255057, 2, -1, 10, 40, 0, 0, 0, 0, 0, 0, 0, 5, 500, 236, 0, 0, 0, 0, 0, 8, 0, 375250, 100, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Training', 'Practice your skills against the Militia Recruits.', 'You look like you can hold your own, against a cutthroat or two. $B$BSince you''re here, why don''t you test your skills against our recruits? It isn''t safe outside of Sentinel Hill and you should make sure your skills are sharp before heading off into Defias territory... not to mention this batch can certainly use the practice.$B$BI don''t like the thought of sending more fools out to their deaths, show me what you can do.', '', 'Return to Captain Olens at Sentinel Hill.', 255339, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Militia Recruits Defeated', '', '', '', 0),
(999913, 2, 11, 9, 40, 0, 0, 0, 0, 0, 0, 0, 4, 0, 270, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Missing Report', 'Find the report from the missing patroller.', 'Do you know how difficult it is to sort papers when I''m missing so many reports? $B$BI understand the tedious task of filing paperwork is unappreciated by some, but that doesn''t mean it isn''t important.$B$BI''m missing the field report from one of our patrollers, he walks the route from Sentinel Hill to the border of Elwynn. Find him for me, and bring me back his report since he can''t be bothered to do it himself.', '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(999914, 2, 11, 9, 40, 0, 0, 0, 0, 0, 0, 0, 4, 0, 270, 0, 0, 0, 0, 999920, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Half-Detailed Report', 'Return the Half-Detailed Report to Archivist Selnor.', 'Upon inspecting the body, you find the patroller''s half-completed report. $B$BThis should be delivered back to Sentinel Hill - the Archivist will want to know what happened.', '', '', 0, 0, 0, 0, 0, 0, 0, 0, 999920, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 'Deliver the Half-Detailed Report to Archivist Selnor.', '', '', '', 0),
(999933, 2, 16, 12, 40, 0, 0, 0, 0, 0, 0, 0, 4, 0, 270, 0, 0, 0, 0, 999923, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Spit-Soaked Report', 'Deliver the Spit-Soaked Report to Archivist Selnor.', 'The parchment is disgusting - covered in spit and gore. The author of these papers lay in pieces all around you, unrecognizable. $B$BArchivist Selnor will want to see this report, she will know who this is.', '', '', 0, 0, 0, 0, 0, 0, 0, 0, 999923, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 'Deliver the Spit-Soaked Report to Archivist Selnor.', '', '', '', 0),
(100466, 2, 12, 10, 40, 0, 0, 0, 0, 0, 0, 0, 4, 0, 225, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Path to Ascension: Westfall', 'Explore Stormwind to your heart''s content, then visit Flightmaster Dungar Longdrink to fly to Westfall to continue your adventure.', 'Hail, Hero.$B$BWelcome to Stormwind, capital of the Alliance. I assume you''ve arrived to rest and restock. You''ll find many things to aid you on your adventure, from personal banks and the Auction House to blacksmiths, enchanters, and of course other heroes. Explore as you like, but when you''re ready to return to your adventure, speak to Flightmaster Dungar Longdrink. There is trouble brewing in the western province that requires your aid.', '', '', 100467, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Explore Stormwind to your heart''s content, then visit Flightmaster Dungar Longdrink to fly to Westfall to continue your adventure', '', '', '', 0),
(17009, 2, 15, 13, 40, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 544, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Sunken Treasure', 'Find the Waterlogged Trunk off the coast of Westfall.', 'The map is i smudged with seaweed and dirt. Fortunately there seems to be some text scribbled towards the bottom which you can barely make out.$B$B"I can''t believe we managed to escape those horrendous fish ''things'' with our lives, but we somehow made it out with their treasure too! I''ve marked the map so as not to forget where I''ve hidden the booty. Would be a shame to come this far only to forget which ship I''ve thrown the chest in. I''ll be sure leave this map someplace safe where prying eye won''t think to look." There seems to be more scribbled down, but you can''t make it out.$B$BThere''s not much to go off of, but it would seem the treasure this map speaks of is hidden beneath the waves in one of the shipwrecks.', '', 'Find the Waterlogged Trunk off the coast of Westfall.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0)
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`),
  `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`),
  `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`),
  `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`),
  `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`),
  `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`),
  `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`),
  `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`),
  `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`),
  `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`),
  `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`),
  `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`),
  `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`),
  `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`),
  `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`),
  `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`),
  `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`),
  `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`),
  `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`),
  `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`),
  `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`),
  `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`),
  `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`),
  `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`),
  `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`),
  `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`),
  `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`),
  `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`),
  `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`),
  `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`),
  `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`),
  `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`),
  `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`),
  `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`),
  `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`),
  `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`),
  `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`),
  `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`),
  `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`),
  `TimeAllowed` = VALUES(`TimeAllowed`), `AllowableRaces` = VALUES(`AllowableRaces`),
  `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`),
  `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`),
  `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`),
  `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`),
  `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`),
  `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`),
  `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`),
  `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`),
  `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`),
  `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`),
  `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`),
  `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`),
  `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`),
  `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `Unknown0` = VALUES(`Unknown0`),
  `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`),
  `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`),
  `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (1313,17011,17012,17014,26993,26994,26995,26996,26997,254042,254043,255057,999913,999914,999933,100466,17009);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `SourceSpellID`, `PrevQuestID`,
  `NextQuestID`, `ExclusiveGroup`, `BreadcrumbForQuestId`, `RewardMailTemplateID`, `RewardMailDelay`,
  `RequiredSkillID`, `RequiredSkillPoints`, `RequiredMinRepFaction`, `RequiredMaxRepFaction`, `RequiredMinRepValue`,
  `RequiredMaxRepValue`, `ProvidedItemCount`, `SpecialFlags`) VALUES
(1313, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(17011, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(17012, 0, 0, 0, 17011, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(17014, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(26993, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(26994, 0, 0, 0, 26993, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(26995, 0, 0, 0, 26994, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(26996, 0, 0, 0, 26995, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(26997, 0, 0, 0, 26996, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(254042, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(254043, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255057, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(999913, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(999914, 0, 0, 0, 999913, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(999933, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(100466, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(17009, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

DELETE FROM `creature_queststarter` WHERE `quest` IN (1313,17011,17012,17014,26993,26994,26995,26996,26997,254042,254043,255057,999913,999914,999933,100466,17009);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(237, 26993),
(237, 26994),
(233, 26995),
(233, 26996),
(233, 26997),
(233, 17014),
(157002, 17011),
(157002, 17012),
(878, 254042),
(490, 254043),
(776786, 255057),
(776790, 999913),
(455339, 999914),
(455343, 999933),
(255150, 1313),
(466, 100466);

DELETE FROM `creature_questender` WHERE `quest` IN (1313,17011,17012,17014,26993,26994,26995,26996,26997,254042,254043,255057,999913,999914,999933,100466,17009);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(237, 26993),
(233, 26994),
(233, 26995),
(233, 26996),
(233, 26997),
(233, 17014),
(157002, 17011),
(157002, 17012),
(490, 254042),
(490, 254043),
(776786, 255057),
(455339, 999913),
(776790, 999914),
(776790, 999933),
(255150, 1313),
(234, 100466);

DELETE FROM `gameobject_queststarter` WHERE `quest` IN (1313,17011,17012,17014,26993,26994,26995,26996,26997,254042,254043,255057,999913,999914,999933,100466,17009);
INSERT INTO `gameobject_queststarter` (`id`, `quest`) VALUES
(518551, 254042);

DELETE FROM `gameobject_questender` WHERE `quest` IN (1313,17011,17012,17014,26993,26994,26995,26996,26997,254042,254043,255057,999913,999914,999933,100466,17009);
INSERT INTO `gameobject_questender` (`id`, `quest`) VALUES
(96005, 17009);

UPDATE `creature_template` SET `npcflag` = `npcflag` | 2 WHERE `entry` = 490;

-- Turn-in positions follow the client QuestSuperTrack/SuperTrack points: Path to Ascension: Westfall ends at
-- SuperTrack 310 (Gryan Stoutmantle), and 254042/254043 end at SuperTrack 8587/8588, where Protector Gariel
-- now stands (facing unchanged).
UPDATE `creature` SET `position_x` = -10633.9, `position_y` = 1181.08, `position_z` = 34.76 WHERE `guid` = 89531 AND `id` = 490;

UPDATE `quest_template` SET `QuestLevel` = -1 WHERE `ID` IN (22,36,38,64,65,151,153,184,208,214);
UPDATE `quest_template` SET `QuestLevel` = 15, `MinLevel` = 10 WHERE `ID` = 104;
UPDATE `quest_template` SET `MinLevel` = 35 WHERE `ID` = 50;
UPDATE `quest_template` SET `MinLevel` = 10 WHERE `ID` IN (166,214);
UPDATE `quest_template` SET `RequiredItemId1` = 1358, `RequiredItemCount1` = 1 WHERE `ID` = 138;
UPDATE `quest_template` SET `RequiredItemId1` = 1361, `RequiredItemCount1` = 1 WHERE `ID` = 139;
UPDATE `quest_template` SET `RequiredItemId1` = 1362, `RequiredItemCount1` = 1 WHERE `ID` = 140;

-- Westfall creature drops missing here: Exiles DB export 2026-09-13, creature_loot.
DELETE FROM `creature_loot_template` WHERE (`Entry`=36 AND `Item`=3595661) OR (`Entry`=121 AND `Item`=1013734) OR
  (`Entry`=122 AND `Item`=201450) OR (`Entry`=122 AND `Item`=1013661) OR (`Entry`=122 AND `Item`=1013841) OR
  (`Entry`=122 AND `Item`=1178874) OR (`Entry`=124 AND `Item`=1013642) OR (`Entry`=124 AND `Item`=1013649) OR
  (`Entry`=154 AND `Item`=79348) OR (`Entry`=157 AND `Item`=79349) OR (`Entry`=199 AND `Item`=79350) OR
  (`Entry`=391 AND `Item`=1180) OR (`Entry`=449 AND `Item`=1013734) OR (`Entry`=454 AND `Item`=79359) OR
  (`Entry`=456 AND `Item`=955) OR (`Entry`=462 AND `Item`=79360) OR (`Entry`=462 AND `Item`=103729) OR
  (`Entry`=501 AND `Item`=765) OR (`Entry`=501 AND `Item`=785) OR (`Entry`=501 AND `Item`=2447) OR
  (`Entry`=501 AND `Item`=2449) OR (`Entry`=501 AND `Item`=2450) OR (`Entry`=501 AND `Item`=2452) OR
  (`Entry`=506 AND `Item`=56925) OR (`Entry`=513 AND `Item`=835) OR (`Entry`=519 AND `Item`=56927) OR
  (`Entry`=547 AND `Item`=79367) OR (`Entry`=572 AND `Item`=56931) OR (`Entry`=573 AND `Item`=56932) OR
  (`Entry`=573 AND `Item`=450560) OR (`Entry`=589 AND `Item`=1175834) OR (`Entry`=589 AND `Item`=1178864) OR
  (`Entry`=589 AND `Item`=2005012) OR (`Entry`=830 AND `Item`=79393) OR (`Entry`=831 AND `Item`=79394) OR
  (`Entry`=833 AND `Item`=79395) OR (`Entry`=834 AND `Item`=79396) OR (`Entry`=1109 AND `Item`=79424) OR
  (`Entry`=1150 AND `Item`=79439) OR (`Entry`=1151 AND `Item`=79440) OR (`Entry`=1216 AND `Item`=79455);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(36, 3595661, 0, 2, 0, 1, 0, 1, 1, 'Harvest Golem - Handcrafted Crossbow'),
(121, 1013734, 0, 1.25, 0, 1, 0, 1, 1, 'Defias Pathstalker - Mystic Scroll: Impale'),
(122, 201450, 0, 3.75, 0, 1, 0, 1, 1, 'Defias Highwayman - Mystic Scroll: Bleeding Edge'),
(122, 1013661, 0, 0.625, 0, 1, 0, 1, 1, 'Defias Highwayman - Mystic Scroll: Dual Wield Specialization'),
(122, 1013841, 0, 0.625, 0, 1, 0, 1, 1, 'Defias Highwayman - Mystic Scroll: Dual Wield Specialization'),
(122, 1178874, 0, 5.5, 0, 1, 0, 1, 1, 'Defias Highwayman - Mystic Scroll: Retaliatory Justice'),
(124, 1013642, 0, 1.25, 0, 1, 0, 1, 1, 'Riverpaw Brute - Mystic Scroll: Booming Voice'),
(124, 1013649, 0, 1.25, 0, 1, 0, 1, 1, 'Riverpaw Brute - Mystic Scroll: Improved Demoralizing Shout'),
(154, 79348, 0, 1, 0, 1, 0, 1, 1, 'Greater Fleshripper - Beastmaster''s Whistle: Greater Fleshripper'),
(157, 79349, 0, 1, 0, 1, 0, 1, 1, 'Goretusk - Beastmaster''s Whistle: Goretusk'),
(199, 79350, 0, 1, 0, 1, 0, 1, 1, 'Young Fleshripper - Beastmaster''s Whistle: Young Fleshripper'),
(391, 1180, 0, 0.56, 0, 1, 0, 1, 1, 'Old Murk-Eye - Scroll of Stamina'),
(449, 1013734, 0, 2.5, 0, 1, 0, 1, 1, 'Defias Knuckleduster - Mystic Scroll: Impale'),
(454, 79359, 0, 1, 0, 1, 0, 1, 1, 'Young Goretusk - Beastmaster''s Whistle: Young Goretusk'),
(456, 955, 0, 0.5, 0, 1, 0, 1, 1, 'Murloc Minor Oracle - Scroll of Intellect'),
(462, 79360, 0, 1, 0, 1, 0, 1, 1, 'Vultros - Beastmaster''s Whistle: Vultros'),
(462, 103729, 0, 1, 0, 1, 0, 1, 1, 'Vultros - Sigil of Vultros'),
(501, 765, 0, 3.22, 0, 1, 0, 1, 1, 'Riverpaw Herbalist - Silverleaf'),
(501, 785, 0, 3.54, 0, 1, 0, 1, 1, 'Riverpaw Herbalist - Mageroyal'),
(501, 2447, 0, 3.38, 0, 1, 0, 1, 1, 'Riverpaw Herbalist - Peacebloom'),
(501, 2449, 0, 3.34, 0, 1, 0, 1, 1, 'Riverpaw Herbalist - Earthroot'),
(501, 2450, 0, 3.44, 0, 1, 0, 1, 1, 'Riverpaw Herbalist - Briarthorn'),
(501, 2452, 0, 1.6121, 0, 1, 0, 1, 1, 'Riverpaw Herbalist - Swiftthistle'),
(506, 56925, 0, 1, 0, 1, 0, 1, 1, 'Sergeant Brashclaw - Sigil of Sergeant Brashclaw'),
(513, 835, 0, 4.503, 0, 1, 0, 1, 1, 'Murloc Netter - Large Rope Net'),
(519, 56927, 0, 1, 0, 1, 0, 1, 1, 'Slark - Sigil of Slark'),
(547, 79367, 0, 1, 0, 1, 0, 1, 1, 'Great Goretusk - Beastmaster''s Whistle: Great Goretusk'),
(572, 56931, 0, 1, 0, 1, 0, 1, 1, 'Leprithus - Sigil of Leprithus'),
(573, 56932, 0, 1, 0, 1, 0, 1, 1, 'Foe Reaper 4000 - Sigil of Foe Reaper 4000'),
(573, 450560, 0, 100, 0, 1, 0, 1, 1, 'Foe Reaper 4000 - Harvest Golem Scythe'),
(589, 1175834, 0, 5.5, 0, 1, 0, 1, 1, 'Defias Pillager - Mystic Scroll: Blazing Speed'),
(589, 1178864, 0, 5.5, 0, 1, 0, 1, 1, 'Defias Pillager - Mystic Scroll: Flagellation'),
(589, 2005012, 0, 4, 0, 1, 0, 1, 1, 'Defias Pillager - Magic Stick'),
(830, 79393, 0, 1, 0, 1, 0, 1, 1, 'Sand Crawler - Beastmaster''s Whistle: Sand Crawler'),
(831, 79394, 0, 1, 0, 1, 0, 1, 1, 'Sea Crawler - Beastmaster''s Whistle: Sea Crawler'),
(833, 79395, 0, 1, 0, 1, 0, 1, 1, 'Coyote Packleader - Beastmaster''s Whistle: Coyote Packleader'),
(834, 79396, 0, 1, 0, 1, 0, 1, 1, 'Coyote - Beastmaster''s Whistle: Coyote'),
(1109, 79424, 0, 1, 0, 1, 0, 1, 1, 'Fleshripper - Beastmaster''s Whistle: Fleshripper'),
(1150, 79439, 0, 1, 0, 1, 0, 1, 1, 'River Crocolisk - Beastmaster''s Whistle: River Crocolisk'),
(1151, 79440, 0, 1, 0, 1, 0, 1, 1, 'Saltwater Crocolisk - Beastmaster''s Whistle: Saltwater Crocolisk'),
(1216, 79455, 0, 1, 0, 1, 0, 1, 1, 'Shore Crawler - Beastmaster''s Whistle: Shore Crawler');

UPDATE `creature_loot_template` SET `Chance` = 28.0247 WHERE `Entry` = 480 AND `Item` = 732;
UPDATE `creature_loot_template` SET `Chance` = 30 WHERE `Entry` = 573 AND `Item` = 732;

-- Westfall vendor goods missing here: Exiles DB export 2026-09-13, npc_vendor.
DELETE FROM `npc_vendor` WHERE (`entry`=491 AND `item` IN (417, 466, 469, 471, 473, 474, 475, 476, 477)) OR
  (`entry`=491 AND `item` IN (480, 352621, 421276, 3595665, 3595667)) OR
  (`entry`=843 AND `item` IN (2692, 3713, 6954)) OR (`entry`=8934 AND `item` IN (2692, 3713, 6954)) OR
  (`entry`=1668 AND `item` IN (3595665)) OR (`entry`=1670 AND `item` IN (772065, 772074)) OR
  (`entry`=8931 AND `item` IN (6948, 772061, 772062, 772063, 772064, 772065, 772066, 772067, 772068)) OR
  (`entry`=8931 AND `item` IN (772069, 772070, 772071, 772072, 772073, 772074, 772075, 772076));
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(491, 0, 417, 0, 0, 0, 0),
(491, 0, 466, 0, 0, 0, 0),
(491, 0, 469, 0, 0, 0, 0),
(491, 0, 471, 0, 0, 0, 0),
(491, 0, 473, 0, 0, 0, 0),
(491, 0, 474, 0, 0, 0, 0),
(491, 0, 475, 0, 0, 0, 0),
(491, 0, 476, 0, 0, 0, 0),
(491, 0, 477, 0, 0, 0, 0),
(491, 0, 480, 0, 0, 0, 0),
(491, 0, 352621, 0, 0, 0, 0),
(491, 0, 421276, 0, 0, 0, 0),
(491, 0, 3595665, 0, 0, 0, 0),
(491, 0, 3595667, 0, 0, 0, 0),
(843, 0, 2692, 0, 0, 0, 0),
(843, 0, 3713, 0, 0, 0, 0),
(843, 0, 6954, 0, 0, 0, 0),
(8934, 0, 2692, 0, 0, 0, 0),
(8934, 0, 3713, 0, 0, 0, 0),
(8934, 0, 6954, 0, 0, 0, 0),
(1668, 0, 3595665, 0, 0, 0, 0),
(1670, 0, 772065, 0, 0, 0, 0),
(1670, 0, 772074, 0, 0, 0, 0),
(8931, 0, 6948, 0, 0, 0, 0),
(8931, 0, 772061, 0, 0, 0, 0),
(8931, 0, 772062, 0, 0, 0, 0),
(8931, 0, 772063, 0, 0, 0, 0),
(8931, 0, 772064, 0, 0, 0, 0),
(8931, 0, 772065, 0, 0, 0, 0),
(8931, 0, 772066, 0, 0, 0, 0),
(8931, 0, 772067, 0, 0, 0, 0),
(8931, 0, 772068, 0, 0, 0, 0),
(8931, 0, 772069, 0, 0, 0, 0),
(8931, 0, 772070, 0, 0, 0, 0),
(8931, 0, 772071, 0, 0, 0, 0),
(8931, 0, 772072, 0, 0, 0, 0),
(8931, 0, 772073, 0, 0, 0, 0),
(8931, 0, 772074, 0, 0, 0, 0),
(8931, 0, 772075, 0, 0, 0, 0),
(8931, 0, 772076, 0, 0, 0, 0);

-- Westfall reputation and template values: Exiles DB export 2026-09-13.
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 25 WHERE `creature_id` IN (1094,1096,1097);
UPDATE `creature_template` SET `minlevel` = 15 WHERE `entry` = 121;
UPDATE `creature_template` SET `minlevel` = 13 WHERE `entry` IN (123,456);
UPDATE `creature_template` SET `maxlevel` = 60 WHERE `entry` = 25962;
UPDATE `creature_template` SET `mingold` = 0, `maxgold` = 0 WHERE `entry` = 7050;

-- Westfall creature cache values: Ascension creaturecache.wdb captures up to 2026-09-05, matching the
-- db.exil.es dump of 2026-10-04 (Foe Reaper 4000 reads rank 4 there; the WDB rank 2 wins).
UPDATE `creature_template` SET `rank` = 2 WHERE `entry` IN (462,506,519,520,572,573,1424);
UPDATE `creature_template` SET `name` = 'Ghoul' WHERE `entry` = 846;
UPDATE `creature_template` SET `subname` = 'General Trade Goods Vendor' WHERE `entry` = 8934;
DELETE FROM `creature_questitem` WHERE `CreatureEntry` IN (154,157,454,462,1109);
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`, `VerifiedBuild`) VALUES
(154, 0, 729, 0),
(157, 0, 723, 0),
(157, 1, 731, 0),
(454, 0, 723, 0),
(454, 1, 731, 0),
(462, 0, 729, 0),
(1109, 0, 729, 0);

-- Coyote Packleader 81744 was moved to Eversong coordinates on map 0 by 2021_12_16_06; db.exil.es dump
-- 2026-10-04 (creature_spawn 81744) places it in Westfall. Facing unchanged.
UPDATE `creature` SET `position_x` = -10012, `position_y` = 1577.74, `position_z` = 43.0575, `zoneId` = 40, `areaId` = 40
  WHERE `guid` = 81744 AND `id` = 833;

-- Sentinel Hill as rebuilt by the client's patch-WB1.MPQ (tiles Azeroth_29_51..30_52), whose terrain the
-- server maps match exactly. Spawns set on the vanilla ground stand on the WB1 ground, or on the WMO floor
-- above it: the barn for Mageroyal 207180 and the town hall for lantern 52072. The Midsummer mug keeps
-- its height above the camp table.
UPDATE `creature` SET `position_z` = 36.281 WHERE `guid` = 90391 AND `id` = 8096;
UPDATE `creature` SET `position_z` = 33.03 WHERE `guid` = 89532 AND `id` = 869;
UPDATE `creature` SET `position_z` = 33.879 WHERE `guid` = 94756 AND `id` = 26258;
UPDATE `creature` SET `position_z` = 33.947 WHERE `guid` = 245520 AND `id` = 16592;
UPDATE `creature` SET `position_z` = 33.769 WHERE `guid` = 86253 AND `id` = 26401;
UPDATE `creature` SET `position_z` = 38.25 WHERE `guid` = 90234 AND `id` = 154;
UPDATE `creature` SET `position_z` = 36.305 WHERE `guid` = 90384 AND `id` = 154;
UPDATE `creature` SET `position_z` = 37.505 WHERE `guid` = 89822 AND `id` = 547;
UPDATE `creature` SET `position_z` = 36.91 WHERE `guid` = 90359 AND `id` = 547;
UPDATE `creature` SET `position_z` = 38.235 WHERE `guid` = 89793 AND `id` = 157;
UPDATE `waypoint_data` SET `position_z` = 33.03 WHERE `id` = 895320 AND `point` IN (1);
UPDATE `waypoint_data` SET `position_z` = 32.472 WHERE `id` = 895320 AND `point` IN (2,52);
UPDATE `waypoint_data` SET `position_z` = 34.268 WHERE `id` = 895380 AND `point` IN (8,48);
UPDATE `waypoint_data` SET `position_z` = 34.212 WHERE `id` = 895380 AND `point` IN (9,47);
UPDATE `waypoint_data` SET `position_z` = 35.729 WHERE `id` = 898610 AND `point` IN (4);
UPDATE `waypoint_data` SET `position_z` = 35.372 WHERE `id` = 898610 AND `point` IN (15);
UPDATE `waypoint_data` SET `position_z` = 35.834 WHERE `id` = 898610 AND `point` IN (17);
UPDATE `waypoint_data` SET `position_z` = 34.668 WHERE `id` = 442960 AND `point` IN (2);
UPDATE `gameobject` SET `position_z` = 35.199 WHERE `guid` = 207183 AND `id` = 1620;
UPDATE `gameobject` SET `position_z` = 36.7 WHERE `guid` = 207180 AND `id` = 1620;
UPDATE `gameobject` SET `position_z` = 36.82 WHERE `guid` = 52072 AND `id` = 181355;
UPDATE `gameobject` SET `position_z` = 35.554 WHERE `guid` = 51967 AND `id` = 181355;
UPDATE `gameobject` SET `position_z` = 33.885 WHERE `guid` = 76304 AND `id` = 187564;
UPDATE `gameobject` SET `position_z` = 33.947 WHERE `guid` = 242629 AND `id` = 181371;
UPDATE `gameobject` SET `position_z` = 33.797 WHERE `guid` = 52510 AND `id` = 188021;
UPDATE `gameobject` SET `position_z` = 33.799 WHERE `guid` = 50821 AND `id` = 181305;
UPDATE `gameobject` SET `position_z` = 34.729 WHERE `guid` = 50930 AND `id` = 181307;

-- patch-WB1.MPQ moved the doodads these spawns stand on, without turning them: the signpost
-- WOODSIGNPOSTWORN01 (uid 120166) for the three arrows, two market barrels (uids 17852, 17837) for the
-- Midsummer lanterns and FLAGPOLE01 (uid 181171) for its lantern. Each spawn takes its doodad's offset.
-- William MacGregor and Mike Miller take the mean offset of their stall doodads within 3 yd.
UPDATE `gameobject` SET `position_x` = -10650.26, `position_y` = 1034.58, `position_z` = 33.39
  WHERE `guid` = 31939 AND `id` = 86;
UPDATE `gameobject` SET `position_x` = -10650.56, `position_y` = 1033.43, `position_z` = 32.363
  WHERE `guid` = 31940 AND `id` = 88;
UPDATE `gameobject` SET `position_x` = -10650.56, `position_y` = 1033.38, `position_z` = 34.194
  WHERE `guid` = 32331 AND `id` = 87;
UPDATE `gameobject` SET `position_x` = -10674.8, `position_y` = 986.85, `position_z` = 38.408
  WHERE `guid` = 52789 AND `id` = 181388;
UPDATE `gameobject` SET `position_x` = -10671.65, `position_y` = 987.64, `position_z` = 37.236
  WHERE `guid` = 53272 AND `id` = 181391;
UPDATE `gameobject` SET `position_x` = -10634.74, `position_y` = 1030.65, `position_z` = 35.162
  WHERE `guid` = 54893 AND `id` = 187576;
UPDATE `creature` SET `position_x` = -10669.979, `position_y` = 989.242, `position_z` = 36.176
  WHERE `guid` = 48881 AND `id` = 1668;
UPDATE `creature` SET `position_x` = -10659.08, `position_y` = 981.867, `position_z` = 35.617
  WHERE `guid` = 48876 AND `id` = 1670;

-- Sentinel Hill footage (YouTube F6vp8CJOTGk): Gina MacGregor, the campfire and the milk barrel stand in the
-- market by William MacGregor, and the Midsummer crates stand outside the stable instead of inside it.
-- Positions are estimated from the footage; facings are unchanged.
UPDATE `gameobject` SET `position_x` = -10659.0, `position_y` = 986.8, `position_z` = 35.653
  WHERE `guid` = 11020 AND `id` = 1843;
UPDATE `gameobject` SET `position_x` = -10670.0, `position_y` = 985.9, `position_z` = 36.177
  WHERE `guid` = 42737 AND `id` = 3705;
UPDATE `gameobject` SET `position_x` = -10645.13, `position_y` = 1067.61, `position_z` = 33.928
  WHERE `guid` = 50739 AND `id` = 181302;
UPDATE `gameobject` SET `position_x` = -10646.43, `position_y` = 1066.68, `position_z` = 34.064
  WHERE `guid` = 50801 AND `id` = 181302;
UPDATE `gameobject` SET `position_x` = -10644.93, `position_y` = 1066.11, `position_z` = 33.956
  WHERE `guid` = 50870 AND `id` = 181306;
UPDATE `creature` SET `position_x` = -10668.07, `position_y` = 986.01, `position_z` = 36.054
  WHERE `guid` = 48880 AND `id` = 843;
