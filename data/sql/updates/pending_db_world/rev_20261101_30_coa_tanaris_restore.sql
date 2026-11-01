-- Tanaris restore from Ascension captures: the 15 Tanaris quests this server lacks (WDB questcache captures up to
-- 2026-09-07), their givers, enders and credit NPCs (WDB creaturecache), the Bloodsail Logbook and Zeppelin Battery
-- quest objects (WDB gameobjectcache), the quest item drops, the Steamwheedle Port vendor and engineering trainer,
-- the rare elites Mordok Charstone, Thaladorius Rex and Ze'bulba, the vendor Rektha Gruff, and the Giant Surf
-- Glider, Raging Dune Smasher and Great Shark spawns of the SUB creature_spawn table (db.exil.es dump 2026-10-04)
-- this server lacks. Legacy of Lei'shen 25004 is left out: its giver and objectives are not captured. Positions
-- follow the client QuestSuperTrack/SuperTrack points where one exists. The Cerulis camp, Rektha Gruff and the three
-- rogue elites follow the spawns of Project Descension (descension-server b18d7ee7) at their corrected heights;
-- those come from that realm, not live CoA. Renthar and two Apprentice Engineers stand at Henry Crabgrass's rocket
-- scaffold, and the Stormborn Cloud Serpent and Zeppelin Battery at the zeppelin wreck, where a live stream (YouTube
-- rEaTnfr2Ke4) shows them. The levels of Zebel Shplit, Snazzy Boomsprocket, Renthar, the Apprentice Engineers,
-- Franchesca, Gabriel Smokestacks, Barnabas, the serpent and Cerulis are the stream's. Every other spot, every
-- facing and respawn time, and every other level and every faction, NPC and unit flag of the new NPCs is estimated,
-- since the captures carry none. Type, family, rank, type flags and health modifiers follow each creaturecache row;
-- the Bronze Whelp's kill credit 100323 is not on this server and is left out.

INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`,
  `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`,
  `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`,
  `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`,
  `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`,
  `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`,
  `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`,
  `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(449390, 0, 0, 0, 0, 0, 'Zebel Shplit', 'Steamwheedle Porter', NULL, 9975003, 57, 57, 0, 474, 3, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.328, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(749258, 0, 0, 0, 0, 0, 'Snazzy Boomsprocket', NULL, NULL, 9975005, 50, 50, 0, 474, 3, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 304, 4, 1, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 2.0, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(713002, 0, 0, 0, 0, 0, 'Renthar', NULL, NULL, 9975006, 23, 23, 0, 474, 3, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.328, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(46996, 0, 0, 0, 0, 0, 'Apprentice Engineer', NULL, NULL, 0, 57, 57, 0, 474, 0, 1, 1.14286, 1, 1, 18, 1, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 34.0, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(449295, 0, 0, 0, 0, 0, 'Marie', 'Pirate Enthusiast', NULL, 0, 53, 53, 0, 474, 2, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.328, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(449391, 0, 0, 0, 0, 0, 'Franchesca', NULL, NULL, 9975004, 60, 60, 0, 474, 3, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.328, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(41676, 0, 0, 0, 0, 0, 'Importer Sprocketspring', 'Food & Drink', NULL, 9975001, 45, 45, 0, 474, 129, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1.048, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(46252, 0, 0, 0, 0, 0, 'Henry Crabgrass', 'Engineering Trainer', NULL, 9975000, 45, 45, 0, 474, 81, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1.312, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(255331, 0, 0, 0, 0, 0, 'Arvon', 'Deep South Tannery', NULL, 0, 40, 40, 0, 120, 2, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1.248, 1, 1, 1, 0, 999, 1, 0, 0, '', 0),
(449290, 0, 0, 0, 0, 0, 'Rektha Gruff', NULL, NULL, 0, 42, 42, 0, 474, 128, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.328, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(449401, 0, 0, 0, 0, 0, 'Gabriel Smokestacks', NULL, NULL, 9975007, 45, 45, 0, 474, 1, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1.0, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(449402, 0, 0, 0, 0, 0, 'Barnabas', 'Gabriel''s Bodyguard', NULL, 0, 44, 44, 0, 474, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 7, 134217728, 449402, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1.2, 1, 1, 1, 0, 999, 1, 0, 0, '', 0),
(255334, 0, 0, 0, 0, 0, 'Stormborn Cloud Serpent', NULL, NULL, 0, 49, 49, 0, 14, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 0, 2048, 0, 27, 1, 1, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 2.5, 1, 1, 1, 0, 999, 1, 0, 0, '', 0),
(255335, 0, 0, 0, 0, 0, 'Cerulis', 'Ascendant of Storms', NULL, 0, 50, 50, 0, 14, 0, 1, 1.14286, 1, 1, 18, 1, 0, 1, 2000, 2000, 1, 1, 8, 0, 2048, 0, 301, 4, 1, 255335, 0, 0, 0, 0, 0, 0, '', 0, 1, 6, 1, 1, 1, 0, 999, 1, 0, 0, '', 0),
(255336, 0, 0, 0, 0, 0, 'Living Storm', 'Attendant of Cerulis', NULL, 0, 48, 48, 0, 14, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 0, 2048, 0, 301, 4, 1, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.32, 1, 1, 1, 0, 999, 1, 0, 0, '', 0),
(255292, 0, 0, 0, 0, 0, 'Bronze Whelp', NULL, NULL, 0, 45, 45, 0, 14, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 0, 2048, 0, 426, 2, 9, 255292, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.4, 1, 1, 1, 0, 999, 1, 0, 0, '', 0),
(542311, 0, 0, 0, 0, 0, 'Mordok Charstone', 'Rogue Pyromancer', NULL, 0, 43, 43, 0, 14, 0, 1, 1.14286, 1, 1, 18, 2, 0, 1, 2000, 2000, 1, 1, 8, 0, 2048, 0, 20, 7, 1, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 4.5, 1, 1, 1, 0, 999, 1, 0, 0, '', 0),
(542312, 0, 0, 0, 0, 0, 'Thaladorius Rex', 'Rogue Barbarian', NULL, 0, 43, 43, 0, 14, 0, 1, 1.14286, 1, 1, 18, 2, 0, 1, 2000, 2000, 1, 1, 1, 0, 2048, 0, 20, 7, 1, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 4.5, 1, 1, 1, 0, 999, 1, 0, 0, '', 0),
(542313, 0, 0, 0, 0, 0, 'Ze''bulba', 'Rogue Tinker', NULL, 0, 43, 43, 0, 14, 0, 1, 1.14286, 1, 1, 18, 2, 0, 1, 2000, 2000, 1, 1, 1, 0, 2048, 0, 20, 7, 1, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 4.5, 1, 1, 1, 0, 999, 1, 0, 0, '', 0)
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

-- Stand-in displays, estimated: the captured displays of 255331, 449290, 449295, 449390, 449391, 449401, 542311,
-- 542312, 542313, 713002 are not in the client's CreatureDisplayInfo.dbc (checked in every Data\*.MPQ and the realm
-- patch archives) nor the server's. They take a Tanaris or Booty Bay NPC display of the race and sex the name and
-- the capture suggest: 255331 7429 (human male); 449290 4488 (human female); 449295 4490 (human female); 449390 7181
-- (goblin male); 449391 1546 (human female); 449401 7180 (goblin male); 542311 19174 (dwarf male); 542312 4478
-- (human male); 542313 15210 (troll male); 713002 7337 (goblin male). Every other display is the captured one.
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (41676,46252,46996,255292,255331,255334,255335,255336,
  449290,449295,449390,449391,449401,449402,542311,542312,542313,713002,749258);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(41676, 0, 21629, 1, 1, 0),
(46252, 0, 10472, 1, 1, 0),
(46996, 0, 7109, 1, 1, 0),
(255292, 0, 14720, 1, 1, 0),
(255331, 0, 7429, 1, 1, 0),
(255334, 0, 2703, 1, 1, 0),
(255335, 0, 35513, 1, 1, 0),
(255336, 0, 8716, 1, 1, 0),
(449290, 0, 4488, 1, 1, 0),
(449295, 0, 4490, 1, 1, 0),
(449390, 0, 7181, 1, 1, 0),
(449391, 0, 1546, 1, 1, 0),
(449401, 0, 7180, 1, 1, 0),
(449402, 0, 30244, 1, 1, 0),
(542311, 0, 19174, 1, 1, 0),
(542312, 0, 4478, 1, 1, 0),
(542313, 0, 15210, 1, 1, 0),
(713002, 0, 7337, 1, 1, 0),
(749258, 0, 7343, 1, 1, 0);

-- Guids 9975000-9975025 are the new NPCs; Arvon stands in Booty Bay (map 0) where the client point of 255040 puts
-- him. Guids 9975026-9975067 are the SUB spawns of the Giant Surf Glider, Raging Dune Smasher and Great Shark this
-- server lacks, at the dump's positions.
DELETE FROM `creature` WHERE `guid` BETWEEN 9975000 AND 9975299;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
  `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
  `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
  `CreateObject`, `Comment`) VALUES
(9975000, 449390, 1, 0, 0, 1, 1, 0, -6955.0, -4881.7, 0.7, 5.02, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Zebel Shplit (client SuperTrack point; facing estimated)'),
(9975001, 749258, 1, 0, 0, 1, 1, 0, -8260.0, -5051.2, 8.7, 1.14, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Snazzy Boomsprocket (client SuperTrack point; facing estimated)'),
(9975002, 449295, 1, 0, 0, 1, 1, 0, -6905.2, -4839.1, 8.4, 1.27, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Marie (client SuperTrack point beside Yeh''kinya; facing estimated)'),
(9975003, 449391, 1, 0, 0, 1, 1, 0, -6906.9, -4691.0, 8.9, 5.39, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Franchesca (client SuperTrack point; facing estimated)'),
(9975004, 41676, 1, 0, 0, 1, 1, 0, -7020.1, -4737.6, 9.23, 2.72, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Importer Sprocketspring (client SuperTrack point of objective 2 of 255037; z terrain, facing estimated)'),
(9975005, 46252, 1, 0, 0, 1, 1, 0, -6854.5, -4768.2, 9.76, 0.24, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Henry Crabgrass (client SuperTrack point of objective 3 of 255037; z terrain, facing estimated)'),
(9975006, 713002, 1, 0, 0, 1, 1, 0, -6850.5, -4759.2, 9.85, 4.1, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Renthar (beside Henry Crabgrass at the rocket scaffold as the live stream shows; spot, z terrain and facing estimated)'),
(9975007, 46996, 1, 0, 0, 1, 1, 0, -6856.5, -4762.5, 9.69, 5.96, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Apprentice Engineer (at the rocket scaffold beside Henry Crabgrass as the live stream shows; spot, z terrain and facing estimated)'),
(9975008, 46996, 1, 0, 0, 1, 1, 0, -6851.0, -4765.5, 9.91, 2.47, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Apprentice Engineer (at the rocket scaffold beside Henry Crabgrass as the live stream shows; spot, z terrain and facing estimated)'),
(9975009, 255331, 0, 0, 0, 1, 1, 0, -14453.1, 406.3, 25.3, 2.43, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Arvon (client SuperTrack point; facing estimated)'),
(9975010, 449401, 1, 0, 0, 1, 1, 0, -7024.3, -4761.0, 9.78, 2.81, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Gabriel Smokestacks (client SuperTrack point of 255048; z terrain, facing estimated)'),
(9975011, 449402, 1, 0, 0, 1, 1, 0, -7022.0, -4758.5, 9.98, 3.97, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Barnabas (beside Gabriel Smokestacks; spot, z terrain and facing estimated)'),
(9975012, 255335, 1, 0, 0, 1, 1, 0, -9509.0, -2495.0, 21.85, 3.91, 900, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Cerulis (Project Descension spawn b18d7ee7; z terrain, facing and respawn estimated)'),
(9975013, 255336, 1, 0, 0, 1, 1, 0, -9463.0, -2426.0, 20.05, 4.28, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Living Storm (Project Descension spawn b18d7ee7; facing estimated)'),
(9975014, 255336, 1, 0, 0, 1, 1, 0, -9498.0, -2489.0, 19.62, 3.64, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Living Storm (beside Cerulis as the Project Descension pin; spot, z terrain and facing estimated)'),
(9975015, 255334, 1, 0, 0, 1, 1, 0, -9298.0, -2408.0, 8.98, 3.54, 300, 8, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Stormborn Cloud Serpent (at the zeppelin wreck by the Zeppelin Battery as the live stream shows; spot, z terrain and facing estimated)'),
(9975016, 449290, 1, 0, 0, 1, 1, 0, -9049.0, -3668.0, 35.1, 5.7, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Rektha Gruff (Project Descension spawn b18d7ee7 at its corrected height; facing estimated)'),
(9975017, 542311, 1, 0, 0, 1, 1, 0, -7899.0, -3461.0, 76.05, 2.79, 900, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Mordok Charstone (Project Descension spawn b18d7ee7 at its corrected height; facing and respawn estimated)'),
(9975018, 542312, 1, 0, 0, 1, 1, 0, -7902.0, -3458.0, 76.48, 3.16, 900, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Thaladorius Rex (beside Mordok Charstone as the Project Descension pin; spot, z terrain, facing and respawn estimated)'),
(9975019, 542313, 1, 0, 0, 1, 1, 0, -7899.0, -3392.0, 74.11, 3.53, 900, 15, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Ze''bulba (one of the ten Project Descension pins b18d7ee7 at its corrected height; facing, wander and respawn estimated)'),
(9975020, 255292, 1, 0, 0, 1, 1, 0, -8195.9, -4482.1, 8.97, 0.0, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Bronze Whelp (around the client SuperTrack point of 255029; spot, z terrain and facing estimated)'),
(9975021, 255292, 1, 0, 0, 1, 1, 0, -8205.1, -4477.4, 9.04, 2.4, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Bronze Whelp (around the client SuperTrack point of 255029; spot, z terrain and facing estimated)'),
(9975022, 255292, 1, 0, 0, 1, 1, 0, -8199.1, -4491.1, 8.95, 4.8, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Bronze Whelp (around the client SuperTrack point of 255029; spot, z terrain and facing estimated)'),
(9975023, 255292, 1, 0, 0, 1, 1, 0, -8193.4, -4473.6, 9.47, 0.92, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Bronze Whelp (around the client SuperTrack point of 255029; spot, z terrain and facing estimated)'),
(9975024, 255292, 1, 0, 0, 1, 1, 0, -8211.8, -4484.2, 9.71, 3.32, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Bronze Whelp (around the client SuperTrack point of 255029; spot, z terrain and facing estimated)'),
(9975025, 255292, 1, 0, 0, 1, 1, 0, -8188.6, -4489.3, 8.04, 5.72, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Bronze Whelp (around the client SuperTrack point of 255029; spot, z terrain and facing estimated)'),
(9975026, 5432, 1, 0, 0, 1, 1, 0, -10257.0, -3768.0, 0.6, 4.55, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975027, 5432, 1, 0, 0, 1, 1, 0, -10137.0, -3918.0, 8.9, 4.99, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975028, 5432, 1, 0, 0, 1, 1, 0, -10103.0, -3846.0, 5.8, 5.01, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975029, 5432, 1, 0, 0, 1, 1, 0, -10096.0, -4194.0, 0.6, 1.32, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975030, 5432, 1, 0, 0, 1, 1, 0, -10062.0, -3730.0, 6.4, 1.34, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975031, 5432, 1, 0, 0, 1, 1, 0, -9983.0, -3600.0, 1.1, 5.45, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975032, 5432, 1, 0, 0, 1, 1, 0, -9989.0, -4221.0, 6.9, 3.23, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975033, 5432, 1, 0, 0, 1, 1, 0, -9944.0, -4370.0, 0.6, 1.04, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975034, 5432, 1, 0, 0, 1, 1, 0, -9884.0, -3640.0, 10.0, 4.4, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975035, 5432, 1, 0, 0, 1, 1, 0, -9829.0, -3566.0, 0.7, 5.91, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975036, 5432, 1, 0, 0, 1, 1, 0, -9836.0, -4304.0, 8.5, 3.32, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975037, 5432, 1, 0, 0, 1, 1, 0, -9754.0, -4453.0, 0.6, 2.26, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975038, 5432, 1, 0, 0, 1, 1, 0, -9718.0, -4372.0, 6.0, 3.02, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975039, 5432, 1, 0, 0, 1, 1, 0, -9610.0, -4381.0, 0.6, 5.3, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975040, 5432, 1, 0, 0, 1, 1, 0, -10254.0, -4093.0, 0.6, 5.66, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975041, 5432, 1, 0, 0, 1, 1, 0, -10200.0, -3943.0, 3.4, 0.52, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975042, 5432, 1, 0, 0, 1, 1, 0, -10145.0, -3699.0, 0.2, 2.03, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Giant Surf Glider (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975043, 5470, 1, 0, 0, 1, 1, 0, -9551.3, -2781.9, 7.9, 3.51, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Raging Dune Smasher (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975044, 5470, 1, 0, 0, 1, 1, 0, -9614.7, -2783.2, 7.9, 5.32, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Raging Dune Smasher (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975045, 5470, 1, 0, 0, 1, 1, 0, -9516.2, -2750.0, 8.8, 3.9, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Raging Dune Smasher (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975046, 12124, 1, 0, 0, 1, 1, 0, -10531.1, -4098.5, -47.3, 5.37, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975047, 12124, 1, 0, 0, 1, 1, 0, -10270.0, -4498.0, -10.0, 1.46, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975048, 12124, 1, 0, 0, 1, 1, 0, -9950.0, -2766.0, -5.0, 0.54, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975049, 12124, 1, 0, 0, 1, 1, 0, -9918.0, -3272.0, -10.0, 6.1, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975050, 12124, 1, 0, 0, 1, 1, 0, -9257.0, -4765.0, -6.0, 5.75, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975051, 12124, 1, 0, 0, 1, 1, 0, -9031.0, -4754.0, -2.0, 1.45, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975052, 12124, 1, 0, 0, 1, 1, 0, -8967.0, -4736.0, -14.0, 0.01, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975053, 12124, 1, 0, 0, 1, 1, 0, -8683.0, -5351.0, -67.0, 4.61, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975054, 12124, 1, 0, 0, 1, 1, 0, -8556.0, -5368.0, -7.0, 1.36, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975055, 12124, 1, 0, 0, 1, 1, 0, -8260.0, -5424.0, -6.0, 4.12, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975056, 12124, 1, 0, 0, 1, 1, 0, -8146.0, -5495.0, -11.0, 2.34, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975057, 12124, 1, 0, 0, 1, 1, 0, -7877.0, -5452.0, -9.0, 1.39, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975058, 12124, 1, 0, 0, 1, 1, 0, -7862.0, -5524.0, -9.0, 0.66, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975059, 12124, 1, 0, 0, 1, 1, 0, -7621.0, -5110.0, -21.0, 1.91, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975060, 12124, 1, 0, 0, 1, 1, 0, -7620.0, -5040.0, -15.0, 2.28, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975061, 12124, 1, 0, 0, 1, 1, 0, -10054.6, -4651.1, -82.3, 6.02, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975062, 12124, 1, 0, 0, 1, 1, 0, -9870.3, -4875.4, -65.7, 5.02, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975063, 12124, 1, 0, 0, 1, 1, 0, -8994.0, -4864.5, -75.2, 2.58, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975064, 12124, 1, 0, 0, 1, 1, 0, -8776.6, -5152.9, -84.9, 1.6, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975065, 12124, 1, 0, 0, 1, 1, 0, -8429.4, -5566.2, -60.3, 4.39, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975066, 12124, 1, 0, 0, 1, 1, 0, -7793.1, -5573.2, -60.2, 1.07, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)'),
(9975067, 12124, 1, 0, 0, 1, 1, 0, -7578.3, -5245.5, -51.6, 5.26, 300, 10, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Great Shark (SUB creature_spawn, db.exil.es dump 2026-10-04; facing and wander estimated)');

-- Importer Sprocketspring sells the ten drinks and fruits of the first vendor page the live stream shows, then the
-- 16 goods of SUB npc_vendor (2026-10-04); the stream does not show pages 2 and 3, so their order is estimated.
-- Rektha Gruff's Mystic Scrolls follow SUB npc_vendor; her list may be partial. The same table lists goods the
-- Gadgetzan and Steamwheedle vendors here lack: Innkeeper Fizzgrimble's Hearthstone, Dirge Quikcleave's 100582,
-- 100587 and 100627 and Blizrik Buckshot's 426757 and 426761. Henry Crabgrass teaches the stock engineering trainer
-- list (estimated: no trainer capture exists).
DELETE FROM `npc_vendor` WHERE `entry` IN (41676,449290);
DELETE FROM `npc_vendor` WHERE (`entry` = 7733 AND `item` = 6948) OR
  (`entry` = 8125 AND `item` = 100582) OR
  (`entry` = 8125 AND `item` = 100587) OR
  (`entry` = 8125 AND `item` = 100627) OR
  (`entry` = 8131 AND `item` = 426757) OR
  (`entry` = 8131 AND `item` = 426761);
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(41676, 0, 159, 0, 0, 0, 0),
(41676, 1, 1179, 0, 0, 0, 0),
(41676, 2, 1205, 0, 0, 0, 0),
(41676, 3, 1645, 0, 0, 0, 0),
(41676, 4, 1708, 0, 0, 0, 0),
(41676, 5, 4536, 0, 0, 0, 0),
(41676, 6, 4537, 0, 0, 0, 0),
(41676, 7, 4538, 0, 0, 0, 0),
(41676, 8, 4539, 0, 0, 0, 0),
(41676, 9, 4602, 0, 0, 0, 0),
(41676, 10, 772061, 0, 0, 0, 0),
(41676, 11, 772062, 0, 0, 0, 0),
(41676, 12, 772063, 0, 0, 0, 0),
(41676, 13, 772064, 0, 0, 0, 0),
(41676, 14, 772065, 0, 0, 0, 0),
(41676, 15, 772066, 0, 0, 0, 0),
(41676, 16, 772067, 0, 0, 0, 0),
(41676, 17, 772068, 0, 0, 0, 0),
(41676, 18, 772069, 0, 0, 0, 0),
(41676, 19, 772070, 0, 0, 0, 0),
(41676, 20, 772071, 0, 0, 0, 0),
(41676, 21, 772072, 0, 0, 0, 0),
(41676, 22, 772073, 0, 0, 0, 0),
(41676, 23, 772074, 0, 0, 0, 0),
(41676, 24, 772075, 0, 0, 0, 0),
(41676, 25, 772076, 0, 0, 0, 0),
(449290, 0, 201005, 0, 0, 0, 0),
(449290, 1, 201450, 0, 0, 0, 0),
(7733, 0, 6948, 0, 0, 0, 0),
(8125, 0, 100582, 0, 0, 0, 0),
(8125, 0, 100587, 0, 0, 0, 0),
(8125, 0, 100627, 0, 0, 0, 0),
(8131, 0, 426757, 0, 0, 0, 0),
(8131, 0, 426761, 0, 0, 0, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` = 46252;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES
(46252, 92);

-- Greetings and gossip options as the live stream (YouTube rEaTnfr2Ke4) shows them. Words hidden by the stream
-- overlay are reconstructed: "Two" and "back" in Prospector Ironboot's greeting, "who" and "While" in Franchesca's
-- and the end of Zebel Shplit's, which the stream cuts off after "Steamwheedle". Zebel's "Famous for what
-- exactly..?" option is left out, since the stream never shows its answer. Ironboot keeps his quests and gains the
-- gossip flag.
DELETE FROM `gossip_menu` WHERE `MenuID` BETWEEN 9975000 AND 9975099;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(9975000, 9975000),
(9975001, 9975001),
(9975002, 9975002),
(9975003, 9975003),
(9975004, 9975004),
(9975005, 9975005),
(9975006, 9975006),
(9975007, 9975007),
(9975008, 9975008);

DELETE FROM `npc_text` WHERE `ID` BETWEEN 9975000 AND 9975099;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `VerifiedBuild`) VALUES
(9975000, '<Henry speaks to you in a voice that sounds as though his tongue is permanently glued to the bottom of his mouth.>$B$BYou know I habbent'' been an engineer for ''berry long, so sometimes I ebben'' suprise myself with the stuff I know.', '<Henry speaks to you in a voice that sounds as though his tongue is permanently glued to the bottom of his mouth.>$B$BYou know I habbent'' been an engineer for ''berry long, so sometimes I ebben'' suprise myself with the stuff I know.', 0, 0, 1, 0),
(9975001, 'Got fruit, milk, anything that''ll cool ya down in this hot Tanaris weather.', 'Got fruit, milk, anything that''ll cool ya down in this hot Tanaris weather.', 0, 0, 1, 0),
(9975002, 'Two weeks ago I pulled my sorry arse up from the bar stool and said I''d get my life back. Came here searching for thorium. Found it, I did, but that''s not all.$B$BThere''s a ruin not far to the south of here. Got dragons, bronze as sand. One of ''em was guarding a treasure. Ancient lookin'' sword. I plan to go back for it, once me'' legs stop shakin''.', 'Two weeks ago I pulled my sorry arse up from the bar stool and said I''d get my life back. Came here searching for thorium. Found it, I did, but that''s not all.$B$BThere''s a ruin not far to the south of here. Got dragons, bronze as sand. One of ''em was guarding a treasure. Ancient lookin'' sword. I plan to go back for it, once me'' legs stop shakin''.', 0, 0, 1, 0),
(9975003, 'Ah, I don''t think we''ve made acquaintance. I''m Zebel Shplit, renowned Steamwheedle porter.', 'Ah, I don''t think we''ve made acquaintance. I''m Zebel Shplit, renowned Steamwheedle porter.', 0, 0, 1, 0),
(9975004, 'The sands speaks dwarf, but only to those who listen. While this town is a pitiful residence, the dunes are what''s important.', 'The sands speaks dwarf, but only to those who listen. While this town is a pitiful residence, the dunes are what''s important.', 0, 0, 1, 0),
(9975005, 'The secret to goblin engineering? One part science, two parts courage, and three parts running really fast when things start beeping unexpectedly.', 'The secret to goblin engineering? One part science, two parts courage, and three parts running really fast when things start beeping unexpectedly.', 0, 0, 1, 0),
(9975006, '<Renthar stares vacantly into the middle-distance. He seems to start his sentence in the middle of a thought he had already been considering for some time>$B$B...you know, you really only have to options when it comes to building rockets. You can either build the system that builds the system of engineers necessary to construct a rocket from scratch, or you can borrow technology from the super advanced space faring civilization that crashed their own much more advanced rocket into our planet several years ago.$B$B<Renthar turns back to watch one of the engineers bang tirelessly on the rickety, half-completed rocket.>$B$B...I''m still not entirely sure why I went with the first option.', '<Renthar stares vacantly into the middle-distance. He seems to start his sentence in the middle of a thought he had already been considering for some time>$B$B...you know, you really only have to options when it comes to building rockets. You can either build the system that builds the system of engineers necessary to construct a rocket from scratch, or you can borrow technology from the super advanced space faring civilization that crashed their own much more advanced rocket into our planet several years ago.$B$B<Renthar turns back to watch one of the engineers bang tirelessly on the rickety, half-completed rocket.>$B$B...I''m still not entirely sure why I went with the first option.', 0, 0, 1, 0),
(9975007, 'Well what can I do ya for $r?', 'Well what can I do ya for $r?', 0, 0, 1, 0),
(9975008, 'Yeah, well, he has not paid me for the last five shipments. So you can tell him this. He either pays every last one of them, with interest, or he never sees another patented Smokestack.', 'Yeah, well, he has not paid me for the last five shipments. So you can tell him this. He either pays every last one of them, with interest, or he never sees another patented Smokestack.', 0, 0, 1, 0);

DELETE FROM `gossip_menu_option` WHERE `MenuID` BETWEEN 9975000 AND 9975099;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`,
  `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`,
  `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(9975000, 0, 3, 'Train Me.', 0, 5, 16, 0, 0, 0, 0, '', 0, 0),
(9975000, 1, 0, 'I have some goods to deliver for you.', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(9975001, 0, 1, 'I want to browse your goods.', 0, 3, 128, 0, 0, 0, 0, '', 0, 0),
(9975001, 1, 0, 'I have some goods to deliver for you.', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(9975002, 0, 0, 'I have some goods to deliver for you.', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(9975007, 0, 0, 'Zebel sent me here to pick up a cigar shipment', 0, 1, 1, 9975008, 0, 0, 0, '', 0, 0),
(9975008, 0, 0, 'That''s none of my business, I''m just here for the cigars.', 0, 1, 1, 0, 0, 0, 0, '', 0, 0);

UPDATE `creature_template` SET `gossip_menu_id` = 9975002, `npcflag` = `npcflag` | 1 WHERE `entry` = 10460;

-- Each delivery option of 255037 shows only while that delivery is outstanding, and Gabriel Smokestacks asks about
-- the cigars only while the player is on 255048 without the shipment.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` BETWEEN 9975000 AND 9975099;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
  `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
  `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(15, 9975002, 0, 0, 0, 9, 0, 255037, 0, 0, 0, 0, 0, '', 'Prospector Ironboot - delivery only on quest 255037'),
(15, 9975002, 0, 0, 0, 48, 0, 255037, 0, 1, 1, 0, 0, '', 'Prospector Ironboot - delivery not made yet'),
(15, 9975001, 1, 0, 0, 9, 0, 255037, 0, 0, 0, 0, 0, '', 'Importer Sprocketspring - delivery only on quest 255037'),
(15, 9975001, 1, 0, 0, 48, 0, 255037, 1, 1, 1, 0, 0, '', 'Importer Sprocketspring - delivery not made yet'),
(15, 9975000, 1, 0, 0, 9, 0, 255037, 0, 0, 0, 0, 0, '', 'Henry Crabgrass - delivery only on quest 255037'),
(15, 9975000, 1, 0, 0, 48, 0, 255037, 2, 1, 1, 0, 0, '', 'Henry Crabgrass - delivery not made yet'),
(15, 9975007, 0, 0, 0, 9, 0, 255048, 0, 0, 0, 0, 0, '', 'Gabriel Smokestacks - cigars only on quest 255048'),
(15, 9975007, 0, 0, 0, 2, 0, 355500, 1, 0, 1, 0, 0, '', 'Gabriel Smokestacks - shipment not looted yet');

-- Quest objects: WDB gameobjectcache captures up to 2026-09-07. The logbook starts 255040 and the battery ends
-- 255055 and starts 255056.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`,
  `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`,
  `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
(255040, 2, 1021172, 'Bloodsail Logbook', '', '', '', 0.25, 0, 255040, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(255045, 2, 1011195, 'Zeppelin Battery', '', '', '', 0.5, 0, 255045, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0)
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

DELETE FROM `gameobject` WHERE `guid` BETWEEN 9001900 AND 9001999;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9001900, 255040, 1, 0, 0, 1, 1, -7948.3, -5436.6, 17.41, 2.1, 0, 0, 0.867423, 0.497571, 60, 100, 1, '', 0, 'Bloodsail Logbook beside the Dented Footlocker at Lost Rigger Cove; spot and facing estimated'),
(9001901, 255045, 1, 0, 0, 1, 1, -9305.0, -2415.0, 9.46, 4.0, 0, 0, 0.909297, -0.416147, 60, 100, 1, '', 0, 'Zeppelin Battery at the zeppelin wreck as the live stream shows; spot, z terrain and facing estimated');

-- Quest item drops; each comment names its source.
DELETE FROM `creature_loot_template` WHERE (`Entry` = 255292 AND `Item` = 355083) OR
  (`Entry` = 255335 AND `Item` = 355103) OR
  (`Entry` = 449402 AND `Item` = 355500) OR
  (`Entry` = 5466 AND `Item` = 355089) OR
  (`Entry` = 8667 AND `Item` = 9200813) OR
  (`Entry` = 7855 AND `Item` = 355137) OR
  (`Entry` = 7856 AND `Item` = 355137) OR
  (`Entry` = 7857 AND `Item` = 355137) OR
  (`Entry` = 7858 AND `Item` = 355137);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
  `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(255292, 355083, 0, 50, 1, 1, 0, 1, 1, 'Bronze Whelp - quest 255029, WDB creaturecache quest item; chance estimated'),
(255335, 355103, 0, 100, 1, 1, 0, 1, 1, 'Cerulis - quest 255056, WDB creaturecache quest item; chance estimated'),
(449402, 355500, 0, 100, 1, 1, 0, 1, 1, 'Barnabas - quest 255048, SUB creature_loot 2026-10-04'),
(5466, 355089, 0, 100, 1, 1, 0, 1, 1, 'Coast Strider - quest 255036, SUB creature_loot 2026-10-04 and Exiles DB 2026-09-13'),
(8667, 9200813, 0, 100, 1, 1, 0, 1, 1, 'Gusting Vortex - quest 982258, SUB creature_loot 2026-10-04 and Exiles DB 2026-09-13'),
(7855, 355137, 0, 30, 1, 1, 0, 1, 1, 'Southsea Pirate - quest 909041, Lost Rigger Cove pirates per the quest text; chance estimated'),
(7856, 355137, 0, 30, 1, 1, 0, 1, 1, 'Southsea Freebooter - quest 909041, Lost Rigger Cove pirates per the quest text; chance estimated'),
(7857, 355137, 0, 30, 1, 1, 0, 1, 1, 'Southsea Dock Worker - quest 909041, Lost Rigger Cove pirates per the quest text; chance estimated'),
(7858, 355137, 0, 30, 1, 1, 0, 1, 1, 'Southsea Swashbuckler - quest 909041, Lost Rigger Cove pirates per the quest text; chance estimated');

-- Quests: WDB questcache.
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
(255028, 2, 45, 40, 440, 0, 0, 0, 0, 0, 0, 0, 5, 6500, 2475, 0, 0, 0, 0, 0, 8, 0, 375250, 200, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 369, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Serpentine Strange', 'Investigate the strange naga sightings to the south of Steamwheedle Port.', 'I seen'' something strange lately, $r. Just behind that mountain ridge right south of here, I seen'' a naga swimmin'' around. Haven''t seen one of those slimy bastards ever in the desert, but it can''t be good. Half of our jobs are done in the water, and I don''t want that thing slithering up and taking one of my alchemists for a snack. Can you go there and deal with it?', '', 'Inform Security Chief Bilgewhizzle that the naga sighting is dealt with.', 8617, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Naga sighting resolved', '', '', '', 0),
(255029, 2, 45, 40, 440, 0, 0, 0, 0, 0, 0, 0, 5, 6500, 2475, 0, 0, 0, 0, 0, 8, 0, 375250, 200, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 369, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Corruption of the Highborne', 'Collect 1 Sands of Time near the Caverns of Time and bring it to Zalashji.', 'My people were once like yours, $r. We dwelt upon the ssssshores of a great nation. But our queen betrayed us, sssssold us to the enemy for the promise of power. Now we have it, bound to the dark depthssss…\n\nI ssseek a way to reverse our transformation and regain our losssst forms. Ssssuch power to reverse time musssst be in control of the Bronze Dragons. Find their lair and sssslaughter their young. Bring me the ssssalvation I seek.', '', 'Return to Zalashji in Zalashji''s Den.', 0, 0, 0, 0, 0, 0, 0, 0, 355083, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(255036, 2, 45, 40, 440, 1, 2, 0, 0, 0, 0, 255037, 6, 6500, 2475, 0, 0, 0, 0, 0, 8, 0, 375250, 200, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 369, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Sea Giant Fantasy', 'Recovery Snazzy''s radio from the nearby sea giants.', 'Please don''t tell Zebel! More than my career, there''s no tellin'' what''ll happen to me if he catches me while in a bad mood.\n\nLook. I may or may not have been chillin'' near the shore line. And maybe, just maybe I dozed off with my radio there too. Who''s ta say? Or maybe.. I was ambushed! Fightin'' off sea giants left and right like a right badass, only losin'' my radio when they finally managed to knocked me out.\n\nThe second story, I think''ll find sounds better with is shiny gold, ripe with ya name on it aye? Now that I got yer attention, how''s about yous go and see about retrieving my radio? Bet It''ll be more than worth ya while.', '', 'Return to Snazzy Boomsprocket.', 0, 0, 0, 0, 0, 0, 0, 0, 355089, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(255037, 2, 45, 40, 440, 0, 0, 0, 0, 0, 0, 0, 5, 6500, 2475, 0, 0, 0, 0, 0, 8, 0, 375250, 200, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 355174, 1, 355175, 1, 355176, 1, 355177, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 369, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Nothing to Declare', 'Deliver Snazzy''s goods at Steamwheedle', 'Say, since you''re headin'' back ta Steamwheedle anyways, care to do me a favor?\n\nI gots myself quite a bit of free time down ere, and wouldn''t ya know it, I make myself a pretty good product. The route to port isn''t an easy one, so most my runners end up quittin'' early, voluntarily or otherwise.\n\nBut ya clearly the type with no problems out there, so here''s the deal. Go to the port, carry and deliver my stuff, and I pay you. Doesn''t get more convenient than that aye? Plus, I''ll even throw in a free hit for you since we''re such great pals, how''s that sound?', '', 'Return to Zebel Shplit at Steamwheedle Port.', 10460, 41676, 46252, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Delivery to Prospector Ironboot', 'Delivery to Importer Sprocketspring', 'Delivery to Henry Crabgrass', '', 0),
(255040, 2, 40, 35, 440, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Informant', 'Confront the Bloodsail informant in Booty Bay.', '<This logbook contains information on the inner workings of Booty Bay. It seems the Bloodsail Raiders have an informant in Booty Bay who owns a local tannery. With this information, it shouldn''t be too much trouble to track him down.>', '', 'Confront the Bloodsail informant in Booty Bay.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(255041, 2, 40, 35, 440, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 8, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Informant - Booty Bay''s Ally', 'Side with Booty Bay and report the informant to Baron Revilgaz.', 'And what possible reason would you have to take their side? This isn''t your problem, so just reconsider and take my deal.\n\nI''d hate for you to find out why we''re called the Bloodsail...', '', 'Report the informant''s defeat to Baron Revilgaz.', 255331, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(255042, 2, 40, 35, 440, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 8, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Informant - Bloodsail''s Ally', 'Side with the Bloodsail Buccaneers and accept the informant''s bribe.', 'See? I knew we''d see eye to eye.', '', 'Collect your gold and be on your way.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(255048, 2, 45, 40, 440, 0, 0, 0, 0, 0, 0, 0, 5, 6500, 2475, 0, 0, 0, 0, 0, 8, 0, 375250, 200, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 369, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Smoke on the Water', 'Retrieve Zebel''s cigar shipment from his supplier and return to Zebel Shplit in Steamwheedle.', 'Ahhh there you are. See This is what I like! Someone who actually comes back when they are told to.\n\nNow listen up, kid, because I''ve got an even easier job for you. Easy like tying your boots or counting your fingers. I need cigars. Good ones. Not the soggy driftwood garbage some folks try to pass off around here.\n\nI got a supplier here in Steamwheedle who owes me a favor. All you gotta do is go over there, tell him Zebel sent you, and pick up the shipment. No negotiations. No creative interpretations. You take the box and you come right back here. Got it?', '', 'Return to Zebel Shplit in Steamwheedle.', 0, 0, 0, 0, 0, 0, 0, 0, 355500, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 'Zebel''s Cigar Shipment', '', '', '', 0),
(255055, 2, 49, 44, 440, 0, 0, 0, 0, 0, 0, 255056, 5, 6500, 2475, 0, 0, 0, 0, 0, 8, 0, 375250, 200, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Battery Salvage', 'Defeat the Stormborn Cloud Serpent and collect the zeppelin''s battery.', 'We need a better battery to make a proper rocket, but I can''t get a hold of anything decent here\n\nAn adventurer, perfect, you could probably solve this. There was a zeppelin that went down a few weeks ago to the south-west. Those things always have good batteries...not that it saved this one, but that''s beside the point.\n\nI''ve got plenty of gold to pay you with, just need someone to trek over there and grab that battery from the wreck.', '', 'Inspect the Zeppelin Battery.', 255334, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Find the Zeppelin Battery', '', '', '', 0),
(255056, 2, 49, 44, 440, 1, 2, 0, 0, 0, 0, 0, 5, 6500, 2475, 0, 0, 0, 0, 355101, 8, 0, 375250, 200, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Power From Storms', 'Find a source of energy and restore the battery', '<You can hear the telltale whirling of air elementals nearby. Perhaps they are drawn here by a powerful energy source, something that might be used to restore the lost charge. It''s likely worth investigating before bringing the dying battery back to Renthar, at least.>', '', 'Return to Renthar at Steamwheedle Port.', 0, 0, 0, 0, 0, 0, 0, 0, 355103, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(909040, 2, 46, 40, 440, 0, 0, 0, 0, 0, 0, 0, 3, 0, 1935, 0, 0, 0, 0, 990900, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 369, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Emergency Measures', 'Deliver Bilgewhizzle''s Order to Zebel Shplit in Steamwheedle Port.', 'This whole operation runs on water, and right now the Wastewander scum have made sure there is barely a drop left to spare. Freeing up our pumps is one thing, but we are running dangerously low on reserve. If Gadgetzan is going to stay quenched, we need more water and fast.\n\nWhile you are putting those bandits in their place, head over to Steamwheedle and deliver this order for me. One of the local porters, Zebel Sphlit, should be our guy for a quick refill. Get it to him and he will know what to do.', '', 'Return to Zebel Shplit at Steamwheedle Port in Tanaris.', 0, 0, 0, 0, 0, 0, 0, 0, 990900, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(909041, 2, 53, 45, 440, 0, 0, 0, 0, 0, 0, 0, 4, 2100, 3150, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ink And Illusions', 'Retrieve a Pirate Diary from Lost Rigger Cove.', 'Oh oh oh, this is perfect timing. I just know there is something incredible written down out there, something authentic. Not tavern rumors or sailor gossip, but a real pirate diary. The kind stained with saltwater and bad decisions.\n\nThink about it. Their thoughts. Their routines. Their flair. Everyone talks about pirates like they are brutes with knives, but that cannot be the whole story. There has to be wit. Drama. A sense of style in how they live and steal.\n\nIf I could just read one genuine diary, I could finally understand how a pirate truly thinks. For research of course. Very serious research.\n\nYou should find one for me. A real one. Do not worry about how dangerous it sounds. Pirates write all the time. Probably.', '', 'Return to Marie in Tanaris with a genuine Pirate Diary.', 0, 0, 0, 0, 0, 0, 0, 0, 355137, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 'Pirate Diary', '', '', '', 0),
(909042, 2, 54, 45, 440, 0, 0, 0, 0, 0, 0, 0, 5, 0, 3600, 0, 0, 0, 0, 0, 8, 0, 8484, 1, 375250, 190, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 369, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Taint Beneath The Dunes', 'Destroy the insectoid creatures within the Gaping Chasm.', 'The sand you brought me was not as pure as it should have been.\n\nSomething is burrowing beneath the dunes to the south. Many legs. Endless hunger. They gnaw at the land and leave hollows where memory should be. The desert recoils from them, but it cannot move away.\n\nGo south. Destroy what crawls and feeds below. Do not listen to their noise. They are not part of this place. This is not slaughter. It is cleansing.', '', 'Return to Franchesca in Tanaris after cleansing the Gaping Chasm.', 5454, 5453, 5441, 5451, 5, 5, 5, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Hazzali Sandreavers slain', 'Hazzali Tunnelers slain', 'Hazzali Wasps slain', 'Hazzali Swarmers slain', 0),
(982257, 2, 50, 44, 440, 0, 0, 0, 0, 0, 0, 0, 5, 1500, 975, 0, 0, 0, 0, 0, 8, 0, 375250, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Contractual Concern', 'Find Zebel''s southernmost operative, Snazzy Boomsprocket.', 'Of all the times for Snazzy to be late! What the hell am I even paying him for?\n\nJust wait. When I get my claws on him, he''s gonna know why they call me The San… Ah ha! You look like just the $r I need right now. Care for a job?\n\nSnazzy is my southern operative. His job is to keep tabs on the Lost Riggers to make sure they aren''t up to something while my boats are about to leave port. The thing is, he''s just gone radio silent, and today''s cargo is worth BOAT LOADS.\n\nBut seriously, I can''t get moving until I know the coast is clear. I need you to find him and make sure he does his job, or bring him here so I can deal with him myself.', '', 'Find Snazzy Boomsprocket.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(982258, 2, 47, 40, 440, 0, 0, 0, 0, 0, 0, 909042, 5, 0, 1800, 0, 0, 0, 0, 0, 8, 0, 8484, 1, 375250, 190, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 369, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Whispers In The Living Sand', 'Slay a Gusting Vortex and collect its Living Sand.', 'The dunes are restless.\n\nWhen the sand rises and takes form, it is not anger. It is warning. The desert gathers itself when something has disturbed its balance, when footsteps linger too long or blood is spilled without reason.\n\nThose creatures you have seen moving across the dunes are not elementals in the way you understand them. They are the dunes answering intrusion.\n\nFace one of them. When it falls, the sand it leaves behind will still be warm with motion. That is living sand. Take only what remains. Do not scatter it. Do not linger.', '', 'Return to Franchesca in Tanaris with the living sand from a Gusting Vortex.', 0, 0, 0, 0, 0, 0, 0, 0, 9200813, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 'Living Sand', '', '', '', 0)
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

-- Chains follow the captured NextQuestInChain and the quest texts. Contractual Concern is captured twice, as 255035
-- at level 45 and 982257 at level 50; Zebel offers only 982257, with the details, objective and completion text of
-- the 255035 capture, which the live stream shows for it. Sea Giant Fantasy 255036 does not require it. Arvon offers
-- two endings to The Informant: report him to Baron Revilgaz (255041) or keep his secret (255042); only one can be
-- taken (estimated).
DELETE FROM `quest_template_addon` WHERE `ID` IN (255028,255029,255036,255037,255040,255041,255042,255048,255055,255056,
  909040,909041,909042,982257,982258);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `SourceSpellID`, `PrevQuestID`,
  `NextQuestID`, `ExclusiveGroup`, `BreadcrumbForQuestId`, `RewardMailTemplateID`, `RewardMailDelay`,
  `RequiredSkillID`, `RequiredSkillPoints`, `RequiredMinRepFaction`, `RequiredMaxRepFaction`, `RequiredMinRepValue`,
  `RequiredMaxRepValue`, `ProvidedItemCount`, `SpecialFlags`) VALUES
(255028, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255029, 0, 0, 0, 255028, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255036, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255037, 0, 0, 0, 255036, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255040, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255041, 0, 0, 0, 255040, 0, 255041, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255042, 0, 0, 0, 255040, 0, 255041, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255048, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255055, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255056, 0, 0, 0, 255055, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
(909040, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
(909041, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(909042, 0, 0, 0, 982258, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(982257, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(982258, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

-- Givers and enders follow the captured texts and the client SuperTrack turn-in points. Emergency Measures 909040
-- hands over Bilgewhizzle's Order for Zebel; its giver is Chief Engineer Bilgewhizzle of the Gadgetzan water tower,
-- whom the text names (estimated: no capture names the giver).
DELETE FROM `creature_queststarter` WHERE `quest` IN (255028,255029,255036,255037,255040,255041,255042,255048,255055,
  255056,909040,909041,909042,982257,982258);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(7407, 909040),
(7882, 255028),
(8617, 255029),
(255331, 255041),
(255331, 255042),
(449295, 909041),
(449390, 255048),
(449390, 982257),
(449391, 909042),
(449391, 982258),
(713002, 255055),
(749258, 255036),
(749258, 255037);

DELETE FROM `creature_questender` WHERE `quest` IN (255028,255029,255036,255037,255040,255041,255042,255048,255055,
  255056,909040,909041,909042,982257,982258);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(2496, 255041),
(7882, 255028),
(8617, 255029),
(255331, 255040),
(255331, 255042),
(449295, 909041),
(449390, 255037),
(449390, 255048),
(449390, 909040),
(449391, 909042),
(449391, 982258),
(713002, 255056),
(749258, 255036),
(749258, 982257);

DELETE FROM `gameobject_queststarter` WHERE `quest` IN (255040,255056);
INSERT INTO `gameobject_queststarter` (`id`, `quest`) VALUES
(255040, 255040),
(255045, 255056);

DELETE FROM `gameobject_questender` WHERE `quest` = 255055;
INSERT INTO `gameobject_questender` (`id`, `quest`) VALUES
(255045, 255055);

-- Credits; the credit entries are the captured ones. Each delivery of 255037 counts when the player picks "I have
-- some goods to deliver for you." at its recipient, and choosing "That's none of my business, I'm just here for the
-- cigars." makes Gabriel Smokestacks send his bodyguard Barnabas, who drops the shipment of 255048, at the player
-- while Gabriel cheers him on, as the live stream shows. Barnabas takes the attackable neutral faction 7 for the
-- fight. The other triggers are estimated, since no capture shows them: speaking to Zalashji resolves the naga
-- sighting of 255028, and Arvon turns on a player who takes 255041 and must be killed; he takes faction 7 too, so
-- the Booty Bay bruisers stay out of it.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (8617,10460,41676,46252,255331,449401,449402) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`,
  `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
  `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(8617, 0, 0, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 8617, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Zalashji - On Gossip Hello - Quest Credit'),
(10460, 0, 0, 1, 62, 0, 100, 0, 9975002, 0, 0, 0, 0, 0, 33, 10460, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Prospector Ironboot - On Gossip Select - Quest Credit'),
(10460, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Prospector Ironboot - Linked - Close Gossip'),
(41676, 0, 0, 1, 62, 0, 100, 0, 9975001, 1, 0, 0, 0, 0, 33, 41676, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Importer Sprocketspring - On Gossip Select - Quest Credit'),
(41676, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Importer Sprocketspring - Linked - Close Gossip'),
(46252, 0, 0, 1, 62, 0, 100, 0, 9975000, 1, 0, 0, 0, 0, 33, 46252, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Henry Crabgrass - On Gossip Select - Quest Credit'),
(46252, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Henry Crabgrass - Linked - Close Gossip'),
(449401, 0, 0, 1, 62, 0, 100, 0, 9975008, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gabriel Smokestacks - On Gossip Select - Say Line 0'),
(449401, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gabriel Smokestacks - Linked - Close Gossip'),
(449401, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gabriel Smokestacks - Linked - Store Invoker'),
(449401, 0, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 100, 1, 0, 0, 0, 0, 0, 19, 449402, 30, 0, 0, 0, 0, 0, 0, 'Gabriel Smokestacks - Linked - Send Invoker to Barnabas'),
(449401, 0, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 19, 449402, 30, 0, 0, 0, 0, 0, 0, 'Gabriel Smokestacks - Linked - Set Data 1 1 on Barnabas'),
(449402, 0, 0, 1, 38, 0, 100, 0, 1, 1, 0, 0, 0, 0, 2, 7, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Barnabas - On Data Set 1 1 - Set Faction Neutral Attackable'),
(449402, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Barnabas - Linked - Attack Stored Invoker'),
(449402, 0, 2, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 19, 449401, 30, 0, 0, 0, 0, 0, 0, 'Barnabas - On Aggro - Gabriel Smokestacks Say Line 1'),
(449402, 0, 3, 0, 0, 0, 100, 0, 8000, 10000, 12000, 15000, 0, 0, 1, 1, 0, 0, 0, 0, 0, 19, 449401, 30, 0, 0, 0, 0, 0, 0, 'Barnabas - In Combat - Gabriel Smokestacks Say Line 1'),
(449402, 0, 4, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Barnabas - On Evade - Restore Faction'),
(449402, 0, 5, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Barnabas - On Respawn - Restore Faction'),
(255331, 0, 0, 1, 19, 0, 100, 0, 255041, 0, 0, 0, 0, 0, 2, 7, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Arvon - On Quest Accepted - Set Faction Neutral Attackable'),
(255331, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Arvon - Linked - Attack Invoker'),
(255331, 0, 2, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Arvon - On Evade - Restore Faction'),
(255331, 0, 3, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Arvon - On Respawn - Restore Faction');

UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` IN (8617,10460);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceId` = 0 AND `SourceEntry` IN
  (8617,10460,41676,46252,255331,449401,449402);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
  `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
  `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 8617, 0, 0, 9, 0, 255028, 0, 0, 0, 0, 0, '', 'Zalashji - credit only on quest 255028');

DELETE FROM `creature_text` WHERE `CreatureID` = 449401;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`,
  `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(449401, 0, 0, 'That''s it! I''m tired of explaining this to his stupid cronies! I bet your head would send the message loud and clear to Zebel, get him Barny!', 12, 0, 100, 0, 0, 0, 0, 0, 'Gabriel Smokestacks - sends Barnabas'),
(449401, 1, 0, 'Yeah! That''s it Barny, show ''em what happens when they mess with Gabriel Smokestacks!', 12, 0, 50, 0, 0, 0, 0, 0, 'Gabriel Smokestacks - cheers Barnabas on'),
(449401, 1, 1, 'Come on, Barny! Put that wimp in their place!', 12, 0, 50, 0, 0, 0, 0, 0, 'Gabriel Smokestacks - cheers Barnabas on');
