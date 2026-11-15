-- Kill targets of the trials Hardcore - Oh, the Places You'll Go (611, Prestige 612) and Nightmare - Duo Delirium
-- (613, 614). 611/612 require Blackfathom Ascendant 774803 (before 21), Son of Arugal 772529 (22), Cahooey the Big
-- 610896 (29), Myrrkora Wavebind 449327 (43), Thar'zul 107028 (57) and Construct Surgeon 918530 (57); 613/614
-- require Yil'da 255146 (44), whose template exists but who was never spawned. None of the six had a template.
-- Name, rank, type, family, display, health and mana modifiers: Ascension client creature
-- cache (AscensionDB WDB captures, 2026-07 to 2026-09; SUB creature table, dump of 2026-10-04). All displays exist in
-- the client CreatureDisplayInfo. No source (AscensionDB, Exiles DB, SUB creature_spawn, CoA Tavern, pfQuest and
-- Questie addons, Descension) has a level, faction, spawn point, ability or loot for any of them, so ESTIMATED:
-- - level: the base creature's level within the trial's level limit;
-- - faction, unit class, gold, abilities (SmartAI copied) and loot table (lootid shared): from the base creature
--   whose entry the id ends in (4803 Blackfathom Oracle, 2529 Son of Arugal, 10896 Arnak Grimtotem, 5337 Hatecrest
--   Siren, 7028 Blackrock Warlock, 8530 Cannibal Ghoul); the Construct Surgeon does not copy the ghoul's Darrowshire
--   spirit summon;
-- - spawn point: one fixed spawn each, 3 yards in front of a base creature spawn at its height (Thar'zul in the
--   middle of the Altar of Storms warlocks, Yil'da beside the Lost One Chieftain in Fallow Sanctuary); the Construct
--   Surgeon is placed in Plaguewood after quest 550000 Sutures of the Damned (pfQuest), which sights it near the
--   Plaguewood ziggurats. Heights still need an in-game check;
-- - respawn: 10 minutes for elites, 30 minutes for the rare elites Cahooey and Thar'zul;
-- - damage modifier: the base elite's 1.7, otherwise 2.5 in line with the Trollbane Paragons.
-- Health: as for the Trollbane Paragons and Yil'da, the cached modifier is divided by the open-world health scaling
-- at the creature's level (1.17 + 0.013 * level), which trial targets do not receive on Ascension.
-- Thar'zul's cached kill credit 1005012 has no template here and is left out. Cahooey's display 321657 (TaurenMale)
-- has no model info; it takes the tauren male values of Arnak Grimtotem's display 10243.
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(774803,0,0,0,0,0,'Blackfathom Ascendant',NULL,NULL,0,21,21,0,128,0,1,1.14286,1,1,20,1,0,1.7,2000,2000,1,1,2,32768,2048,0,0,7,0,4803,4803,0,0,0,55,185,'',0,1,2.772003,1,1,1,0,0,1,0,0,'',12340),
(772529,0,0,0,0,0,'Son of Arugal',NULL,NULL,0,20,20,0,24,0,1,1.14286,1,1,20,1,0,1.7,2000,2000,1,1,1,64,2048,0,0,7,0,2529,0,100005,0,0,63,328,'SmartAI',0,1,2.237762,1,1,1,0,0,1,0,0,'',12340),
(610896,0,0,0,0,0,'Cahooey the Big',NULL,NULL,0,29,29,0,16,0,1,1.14286,1,1,18,2,0,2.5,2000,2000,1,1,1,0,2048,0,0,7,0,10896,10896,0,0,0,43,159,'SmartAI',0,1,1.939237,1,1,1,0,0,1,0,0,'',12340),
(449327,0,0,0,0,0,'Myrrkora Wavebind',NULL,NULL,0,43,43,0,74,0,1.1,1.14286,1,1,18,1,0,2.5,2000,2000,1,1,2,32768,2048,0,0,7,0,5337,5337,0,0,0,67,92,'SmartAI',0,1,2.024291,6,1,1,0,0,1,0,0,'',12340),
(107028,0,0,0,0,0,'Thar''zul',NULL,NULL,0,57,57,0,40,0,1,1.14286,1,1,18,2,0,2.5,2000,2000,1,1,8,32768,2048,0,0,7,0,7028,7028,0,0,0,100,792,'SmartAI',0,1,2.616431,1,1,1,0,0,1,0,0,'',12340),
(918530,0,0,0,0,0,'Construct Surgeon',NULL,NULL,0,55,55,0,21,0,0.77778,1.14286,1,1,18,1,0,2.5,2000,2000,1,1,1,0,2048,0,230,6,1,8530,8530,0,0,0,116,393,'',0,1,1.32626,1,1,1,0,0,1,-93,0,'',12340) ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (774803,772529,610896,449327,107028,918530);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(774803,0,4976,1,1,12340),
(772529,0,1098,1,1,12340),
(610896,0,321657,1,1,12340),
(449327,0,18396,1,1,12340),
(107028,0,17137,1,1,12340),
(918530,0,30881,1,1,12340);

DELETE FROM `creature_model_info` WHERE `DisplayID` = 321657;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`, `VerifiedBuild`) VALUES
(321657,0.9747,4.05,0,0,12340);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (774803,610896,449327,107028);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(774803,1,5276,0,0,12340),
(610896,1,9659,0,0,12340),
(449327,1,6334,0,0,12340),
(107028,1,2559,0,0,12340);

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (107028,449327,610896,772529) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(772529,0,0,0,0,0,100,0,5000,12000,15000,23000,0,0,11,7124,32,0,0,0,0,5,20,0,0,7124,0,0,0,0,'Son of Arugal - In Combat - Cast Arugal''s Gift'),
(610896,0,0,0,0,0,100,0,2500,3000,18000,18500,0,0,11,11977,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Cahooey the Big - In Combat - Cast ''11977'''),
(610896,0,1,0,2,0,100,1,30,60,0,0,0,0,11,10966,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Cahooey the Big - Between 30-60% Health - Cast ''10966'' (No Repeat)'),
(449327,0,0,0,0,0,100,0,2000,3000,3000,4000,0,0,11,9532,64,0,0,0,0,2,0,0,0,0,0,0,0,0,'Myrrkora Wavebind - In Combat - Cast ''Lightning Bolt'''),
(107028,0,0,0,0,0,100,0,0,0,3300,5200,0,0,11,20825,64,0,0,0,0,2,0,0,0,0,0,0,0,0,'Thar''zul - In Combat CMC - Cast ''Shadow Bolt'''),
(107028,0,1,0,0,0,100,0,2600,7300,29100,31300,0,0,11,13338,33,0,0,0,0,5,0,0,0,13338,0,0,0,0,'Thar''zul - In Combat - Cast ''Curse of Tongues'''),
(107028,0,2,0,0,0,100,0,6200,8700,5100,11000,0,0,11,20826,33,0,0,0,0,2,0,0,0,0,0,0,0,0,'Thar''zul - In Combat - Cast ''Immolate''');

DELETE FROM `creature` WHERE `guid` IN (7748030,7725290,6108960,4493270,1070280,9185300,2551460);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(7748030,774803,1,148,2078,1,1,1,4308.92,939.59,-18.58,2.3295,600,0,0,1,0,0,0,0,0,'',NULL,0,'Blackfathom Ascendant'),
(7725290,772529,0,130,130,1,1,0,-564.9,1561.65,11.84,3.1348,600,0,0,1,0,0,0,0,0,'',NULL,0,'Son of Arugal'),
(6108960,610896,1,400,2097,1,1,1,-4753.78,-2105.99,83.34,1.4709,1800,0,0,1,0,0,0,0,0,'',NULL,0,'Cahooey the Big'),
(4493270,449327,1,357,1117,1,1,1,-4995.89,3346.01,0.85,3.2286,600,0,0,1,0,0,0,0,0,'',NULL,0,'Myrrkora Wavebind'),
(1070280,107028,0,46,255,1,1,1,-7608.3,-778,190.9,1.8675,1800,0,0,1,0,0,0,0,0,'',NULL,0,'Thar''zul'),
(9185300,918530,0,139,2277,1,1,0,3190.18,-3622.89,164.38,5.4161,600,0,0,1,0,0,0,0,0,'',NULL,0,'Construct Surgeon'),
(2551460,255146,0,8,76,1,1,0,-9946.72,-3642.25,23.61,2.426,600,0,0,1,0,0,0,0,0,'',NULL,0,'Yil''da <Witch of the Swamp>');
