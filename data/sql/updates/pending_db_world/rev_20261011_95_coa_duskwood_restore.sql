-- Duskwood restore from Ascension captures: thirteen missing Duskwood quests (WDB questcache 2026-09-04..08),
-- their givers and credit NPCs (WDB creaturecache 2026-09-04..08), the Discarded Junk and Cage Prop objects (WDB
-- gameobjectcache 2026-09-04..07), quest item drops and 98 creature spawns missing here (db.exil.es dump 2026-10-04),
-- plus creature cache values that differ from the captures.
-- Positions follow the client QuestSuperTrack/SuperTrack points where one exists; every other spot, every facing and
-- every level, faction, NPC and unit flag of the new NPCs is estimated, since the captures carry none. Their type
-- flags, health modifiers and movement ids follow each NPC's creaturecache row.
-- Quest levels follow the captures, except 255071, 255072 and 255074: one capture lists them at -1, the Dawnrise
-- questcache 2026-09-01 at 26, 26 and 25 (25 for 255074 also in the db.exil.es dump 2026-10-04), which is used.
-- 255074 drops the captured creature count of 12, which names no creature; its objective is the 10 Black Ravager
-- Meat. Displays marked stand-in replace Ascension models the client lacks.

INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`,
  `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`,
  `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`,
  `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`,
  `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`,
  `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`,
  `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`,
  `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(255023, 0, 0, 0, 0, 0, 'Oswin Drake', 'The Night Watch', NULL, 9950203, 30, 30, 0, 53, 3, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(764547, 0, 0, 0, 0, 0, 'Oswin Drake', 'The Night Watch', NULL, 0, 30, 30, 0, 53, 2, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(764560, 0, 0, 0, 0, 0, 'Captain Aldric Vayne', 'The Night Watch', NULL, 0, 32, 32, 0, 53, 2, 1, 1.14286, 1, 1, 18, 1, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(764561, 0, 0, 0, 0, 0, 'Nightbane Worgen', NULL, NULL, 9950200, 24, 24, 0, 35, 1, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 768, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1.064, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(254904, 0, 0, 0, 0, 0, 'Julie Addle', NULL, NULL, 0, 20, 20, 0, 12, 2, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.12, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(254905, 0, 0, 0, 0, 0, 'Julie Addle', NULL, NULL, 0, 20, 20, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.12, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(254906, 0, 0, 0, 0, 0, 'Julie Addle', NULL, NULL, 0, 20, 20, 0, 12, 2, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1.12, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(255157, 0, 0, 0, 0, 0, 'Ryton Altham', NULL, NULL, 9950204, 22, 22, 0, 12, 3, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1.024, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(751496, 0, 0, 0, 0, 0, 'Eleanor Zemille', 'The Widow', NULL, 9950205, 25, 25, 0, 12, 3, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.024, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(751497, 0, 0, 0, 0, 0, 'Angus the Handsome', 'Zemille Prospect', NULL, 0, 25, 25, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.024, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(751498, 0, 0, 0, 0, 0, 'Westly the Broad', 'Zemille Prospect', NULL, 0, 25, 25, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.024, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(751499, 0, 0, 0, 0, 0, 'Maxwell the Strong', 'Zemille Prospect', NULL, 0, 25, 25, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.024, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(751500, 0, 0, 0, 0, 0, 'Brutus the Stallion', 'Zemille Prospect', NULL, 0, 25, 25, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.024, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(751501, 0, 0, 0, 0, 0, 'Quartermaster Fenrich', 'The Night Watch', NULL, 9950207, 39, 39, 0, 12, 131, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 8, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(751502, 0, 0, 0, 0, 0, 'Quill the Foolish', NULL, NULL, 9950206, 25, 25, 0, 12, 3, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.024, 1, 1, 1, 0, 999, 1, 0, 2, '', 0),
(100209, 0, 0, 0, 0, 0, 'Bandit Support', NULL, NULL, 0, 26, 26, 0, 17, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 8, 0, 2048, 0, 0, 7, 0, 100209, 0, 0, 0, 0, 21, 126, '', 0, 1, 1.064, 1, 1, 1, 0, 0, 1, 0, 0, '', 0),
(255360, 0, 0, 0, 0, 0, 'Tranquil Gardens Cemetary Dummy', NULL, NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 33554434, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 5.022, 1, 1, 1, 0, 0, 1, 0, 130, '', 0),
(255361, 0, 0, 0, 0, 0, 'Raven Hill Dummy', NULL, NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 33554434, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 5.022, 1, 1, 1, 0, 0, 1, 0, 130, '', 0),
(255362, 0, 0, 0, 0, 0, 'Vul''Gol Ogre Mound Dummy', NULL, NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 33554434, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 5.022, 1, 1, 1, 0, 0, 1, 0, 130, '', 0),
(255363, 0, 0, 0, 0, 0, 'Brightwood Grove Dummy', NULL, NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 33554434, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 5.022, 1, 1, 1, 0, 0, 1, 0, 130, '', 0)
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

-- Stand-in displays: Ascension displays 750771, 750770, 254904, 255157, 256714, 256715 and 256815-256819 are not in
-- the client's CreatureDisplayInfo.dbc. Their stand-ins are estimated, with the sex taken from the name: Oswin Drake
-- 2389, Captain Aldric Vayne 2395 and Quartermaster Fenrich 2392 (Night Watch watchers), Julie Addle 1472, Ryton
-- Altham 3324, Eleanor Zemille 5552, the four Zemille Prospects 5551, 5550, 5074 and 3506, and Quill the Foolish
-- 3484. The Nightbane Worgen (203), the scouting dummies (100003) and Bandit Support (4281 and 4282) keep their client
-- displays.
-- The Zemille Prospects are level 25 as MatodanDLC's recording 6QNRME4U5pY (2026-07-19, 1:01:31) shows for Maxwell
-- the Strong and Brutus the Stallion. Other levels, factions and flags are estimated: the Night Watch follows Watcher
-- Dodds (888), the townsfolk Barkeep Hann (274), and the caged worgen and the scouting dummies are friendly and
-- cannot be attacked. Julie Addle 254905 is the captured credit entry of 254091 and Oswin Drake 764547 the captured
-- second Oswin record; neither is spawned.
-- Quartermaster Fenrich 751501 stands inside a small Darkshire house in the recording above (1:01:48), about six
-- seconds' run downhill from Eleanor Zemille's door past Finbus Geargrind's house: the patch-WB1 farmhouse (WMO uid
-- 1157568) north of hers, which holds no other NPC. He stands on its floor (z 28.78 from the WMO), facing its south
-- door; his spot in the room and his facing are estimated. His tooltip there reads Level 39 and Stormwind, so he has
-- level 39 and faction template 12 (Stormwind, as the Darkshire townsfolk).
-- Bandit Support 100209 is level 26 in the WDB creaturecache (db.exil.es dump 2026-10-04, creature) and has the Defias
-- Enchanter's client displays (Creature.dbc); its faction, class, health, gold and drop follow the Defias Enchanter
-- (910) as estimates. No capture spawns or summons it, so it is not spawned.
-- The dummy name 'Vul'Gol Ogre Mound Dummy' was captured with a broken apostrophe and is written with a plain one.
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (255023,764547,764560,764561,254904,254905,254906,255157,
  751496,751497,751498,751499,751500,751501,751502,255360,255361,255362,255363,100209);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(255023, 0, 2389, 1, 1, 0),
(764547, 0, 2389, 1, 1, 0),
(764560, 0, 2395, 1, 1, 0),
(764561, 0, 203, 1, 1, 0),
(254904, 0, 1472, 1, 1, 0),
(254905, 0, 1472, 1, 1, 0),
(254906, 0, 1472, 1, 1, 0),
(255157, 0, 3324, 1, 1, 0),
(751496, 0, 5552, 1, 1, 0),
(751497, 0, 5551, 1, 1, 0),
(751498, 0, 5550, 1, 1, 0),
(751499, 0, 5074, 1, 1, 0),
(751500, 0, 3506, 1, 1, 0),
(751501, 0, 2392, 1, 1, 0),
(751502, 0, 3484, 1, 1, 0),
(255360, 0, 100003, 1, 1, 0),
(255361, 0, 100003, 1, 1, 0),
(255362, 0, 100003, 1, 1, 0),
(255363, 0, 100003, 1, 1, 0),
(100209, 0, 4281, 1, 1, 0),
(100209, 1, 4282, 1, 1, 0);

-- Guids 9950500-9950515 are the new NPCs. The Night Watch camp at The Night's Watch (area 1816) holds Oswin Drake,
-- Captain Aldric Vayne, the caged worgen and Julie Addle's second record, where quests 254086-254091 point; the camp
-- layout is estimated around the tent and prisoner cages patch-WB1 builds next to the Worldforged Bloodied Axe there:
-- the worgen stands in the western cage (map object 5504842), the others face it at terrain height. The Zemille
-- Prospects stand in front of Eleanor Zemille on her floor of the patch-WB1 house, and Herble Baubbletump (guid 4246)
-- moves from the old house's wall onto that floor; their spots come from the house's floor and wall geometry.
-- Guids 9950516-9950613 are spawns the db.exil.es dump 2026-10-04 (creature_spawn, Duskwood) lists and this
-- server lacks; their positions are the dump's, their facings and respawn times are estimated. Guid 9950614 is
-- Quartermaster Fenrich.
DELETE FROM `creature` WHERE `guid` BETWEEN 9950500 AND 9950699;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
  `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
  `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
  `CreateObject`, `Comment`) VALUES
(9950500, 254904, 0, 0, 0, 1, 1, 0, -10531.7, -1168.46, 34.96, 4.19, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Julie Addle (client SuperTrack, Scarlet Raven Tavern upper floor at the patch-WB1 floor height; facing the room estimated)'),
(9950501, 751496, 0, 0, 0, 1, 1, 0, -10578.8, -1288.93, 41.35, 1.6, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Eleanor Zemille (client SuperTrack; facing estimated)'),
(9950502, 751497, 0, 0, 0, 1, 1, 0, -10575.8, -1288.9, 41.35, 3.15, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Angus the Handsome (in front of Eleanor Zemille on her patch-WB1 floor, facing her; spot estimated)'),
(9950503, 751498, 0, 0, 0, 1, 1, 0, -10579.8, -1286.4, 41.35, 5.09, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Westly the Broad (in front of Eleanor Zemille on her patch-WB1 floor, facing her; spot estimated)'),
(9950504, 751499, 0, 0, 0, 1, 1, 0, -10576.3, -1286.4, 41.35, 3.93, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Maxwell the Strong (in front of Eleanor Zemille on her patch-WB1 floor, facing her; spot estimated)'),
(9950505, 751500, 0, 0, 0, 1, 1, 0, -10582.3, -1287.9, 41.35, 6.0, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Brutus the Stallion (in front of Eleanor Zemille on her patch-WB1 floor, facing her; spot estimated)'),
(9950506, 255157, 0, 0, 0, 1, 1, 0, -10466.1, -1200.19, 27.27, 3.1, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Ryton Altham (client SuperTrack; facing estimated)'),
(9950507, 751502, 0, 0, 0, 1, 1, 0, -10445.8, -1447.77, 70.4, 2.4, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Quill the Foolish (client SuperTrack; facing estimated)'),
(9950508, 255360, 0, 0, 0, 1, 1, 0, -10969.9, -1275.52, 52.67, 0, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Scouting point for 255072 (client SuperTrack objective point)'),
(9950509, 255361, 0, 0, 0, 1, 1, 0, -10754.7, 311.02, 38.35, 0, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Scouting point for 255072 (client SuperTrack objective point)'),
(9950510, 255362, 0, 0, 0, 1, 1, 0, -11119.4, -99.17, 12.71, 0, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Scouting point for 255072 (client SuperTrack objective point)'),
(9950511, 255363, 0, 0, 0, 1, 1, 0, -10450.0, -802.08, 51.72, 0, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Scouting point for 255072 (client SuperTrack objective point)'),
(9950512, 255023, 0, 0, 0, 1, 1, 0, -9991.0, -840.0, 22.1, 2.89, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Oswin Drake (Night Watch camp at The Night''s Watch, facing the cage; spot estimated)'),
(9950513, 764560, 0, 0, 0, 1, 1, 0, -9996.47, -837.45, 21.99, 3.31, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Captain Aldric Vayne (Night Watch camp at The Night''s Watch, facing the cage; spot estimated)'),
(9950514, 254906, 0, 0, 0, 1, 1, 0, -9996.6, -839.36, 21.92, 2.64, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Julie Addle (Night Watch camp at The Night''s Watch, facing the cage; spot estimated)'),
(9950515, 764561, 0, 0, 0, 1, 1, 0, -9999.23, -837.92, 21.86, 0.17, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Nightbane Worgen (inside the patch-WB1 camp cage, facing the tent; facing estimated)'),
(9950516, 569, 0, 0, 0, 1, 1, 0, -10967.8, 386.512, 39.4026, 5.45, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Green Recluse (db.exil.es creature_spawn 4241; facing estimated)'),
(9950517, 210, 0, 0, 0, 1, 1, 0, -10208, 343.256, 8.85151, 1.85, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Bone Chewer (db.exil.es creature_spawn 4401; facing estimated)'),
(9950518, 1110, 0, 0, 0, 1, 1, 0, -10321.2, 421.358, 15.8676, 0.29, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Skeletal Raider (db.exil.es creature_spawn 4889; facing estimated)'),
(9950519, 930, 0, 0, 0, 1, 1, 0, -10305.9, -53.0144, 42.2362, 5.1, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Black Widow Hatchling (db.exil.es creature_spawn 4902; facing estimated)'),
(9950520, 531, 0, 0, 0, 1, 1, 0, -10487.3, 394.844, 36.3066, 0.69, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Skeletal Fiend (db.exil.es creature_spawn 4941; facing estimated)'),
(9950521, 531, 0, 0, 0, 1, 1, 0, -10570.2, 244.374, 29.1534, 1.8, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Skeletal Fiend (db.exil.es creature_spawn 4944; facing estimated)'),
(9950522, 531, 0, 0, 0, 1, 1, 0, -10445.5, 221.74, 31.8922, 6.25, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Skeletal Fiend (db.exil.es creature_spawn 4973; facing estimated)'),
(9950523, 531, 0, 0, 0, 1, 1, 0, -10508.7, 191.16, 31.5408, 5.18, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Skeletal Fiend (db.exil.es creature_spawn 5038; facing estimated)'),
(9950524, 531, 0, 0, 0, 1, 1, 0, -10491.4, 228.798, 32.7765, 5.55, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Skeletal Fiend (db.exil.es creature_spawn 5039; facing estimated)'),
(9950525, 531, 0, 0, 0, 1, 1, 0, -10499, 214.294, 32.6515, 5.92, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Skeletal Fiend (db.exil.es creature_spawn 5040; facing estimated)'),
(9950526, 531, 0, 0, 0, 1, 1, 0, -10484.3, 203.061, 31.2289, 0.01, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Skeletal Fiend (db.exil.es creature_spawn 5041; facing estimated)'),
(9950527, 531, 0, 0, 0, 1, 1, 0, -10551.5, 420.895, 36.6954, 5.24, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Skeletal Fiend (db.exil.es creature_spawn 5140; facing estimated)'),
(9950528, 565, 0, 0, 0, 1, 1, 0, -10254.5, 152.618, 33.0951, 2.66, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Rabid Dire Wolf (db.exil.es creature_spawn 5150; facing estimated)'),
(9950529, 531, 0, 0, 0, 1, 1, 0, -10565.1, 401.82, 31.357, 0.08, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Skeletal Fiend (db.exil.es creature_spawn 5160; facing estimated)'),
(9950530, 531, 0, 0, 0, 1, 1, 0, -10564.5, 379.374, 32.4905, 3.04, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Skeletal Fiend (db.exil.es creature_spawn 5168; facing estimated)'),
(9950531, 531, 0, 0, 0, 1, 1, 0, -10472.6, 427.357, 38.8509, 6.0, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Skeletal Fiend (db.exil.es creature_spawn 5176; facing estimated)'),
(9950532, 531, 0, 0, 0, 1, 1, 0, -10551.9, 275.876, 28.4794, 0.18, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Skeletal Fiend (db.exil.es creature_spawn 5958; facing estimated)'),
(9950533, 531, 0, 0, 0, 1, 1, 0, -10478.4, 232.747, 31.9005, 1.29, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Skeletal Fiend (db.exil.es creature_spawn 5961; facing estimated)'),
(9950534, 1436, 0, 0, 0, 1, 1, 0, -10929, -386, 40.186, 2.33, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Watcher Cutford (db.exil.es creature_spawn 86857; facing estimated)'),
(9950535, 13321, 0, 0, 0, 1, 1, 0, -10345.8, 671.718, 23.5855, 0.68, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146224; facing estimated)'),
(9950536, 13321, 0, 0, 0, 1, 1, 0, -10343.1, 677.718, 20.5679, 1.05, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146225; facing estimated)'),
(9950537, 13321, 0, 0, 0, 1, 1, 0, -10248.7, 633.956, 23.6976, 1.42, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146226; facing estimated)'),
(9950538, 13321, 0, 0, 0, 1, 1, 0, -10246.4, 617.87, 25.0034, 1.79, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146227; facing estimated)'),
(9950539, 13321, 0, 0, 0, 1, 1, 0, -10246.3, 627.489, 24.4922, 2.16, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146228; facing estimated)'),
(9950540, 13321, 0, 0, 0, 1, 1, 0, -10245.7, 637.448, 21.7191, 2.53, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146229; facing estimated)'),
(9950541, 13321, 0, 0, 0, 1, 1, 0, -10245.5, 628.831, 23.4324, 2.9, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146230; facing estimated)'),
(9950542, 13321, 0, 0, 0, 1, 1, 0, -10244.4, 634.768, 21.7023, 3.27, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146231; facing estimated)'),
(9950543, 13321, 0, 0, 0, 1, 1, 0, -10244.3, 616.315, 23.9472, 3.64, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146232; facing estimated)'),
(9950544, 13321, 0, 0, 0, 1, 1, 0, -10244.3, 627.924, 23.1074, 4.01, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146233; facing estimated)'),
(9950545, 13321, 0, 0, 0, 1, 1, 0, -10243.1, 612.897, 23.1891, 4.38, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146234; facing estimated)'),
(9950546, 13321, 0, 0, 0, 1, 1, 0, -10241.4, 612.409, 22.4951, 4.75, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146235; facing estimated)'),
(9950547, 13321, 0, 0, 0, 1, 1, 0, -10239.8, 615.411, 21.6294, 5.12, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146236; facing estimated)'),
(9950548, 13321, 0, 0, 0, 1, 1, 0, -10239.8, 622.683, 21.3765, 5.49, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146237; facing estimated)'),
(9950549, 13321, 0, 0, 0, 1, 1, 0, -10238.1, 731.058, 22.8112, 5.86, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146238; facing estimated)'),
(9950550, 13321, 0, 0, 0, 1, 1, 0, -10234.7, 730.201, 23.5592, 6.23, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146239; facing estimated)'),
(9950551, 13321, 0, 0, 0, 1, 1, 0, -10228.2, 522.337, 24.1037, 0.32, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146240; facing estimated)'),
(9950552, 13321, 0, 0, 0, 1, 1, 0, -10222.3, 522.373, 22.6896, 0.69, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146241; facing estimated)'),
(9950553, 13321, 0, 0, 0, 1, 1, 0, -10219.6, 702.298, 23.0979, 1.06, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146242; facing estimated)'),
(9950554, 13321, 0, 0, 0, 1, 1, 0, -10218.1, 702.563, 23.0757, 1.43, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146243; facing estimated)'),
(9950555, 13321, 0, 0, 0, 1, 1, 0, -10217.4, 700.898, 22.4759, 1.8, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146244; facing estimated)'),
(9950556, 13321, 0, 0, 0, 1, 1, 0, -10210.1, 718.655, 24.4369, 2.17, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146245; facing estimated)'),
(9950557, 13321, 0, 0, 0, 1, 1, 0, -10202, 719.078, 22.4897, 2.54, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146246; facing estimated)'),
(9950558, 13321, 0, 0, 0, 1, 1, 0, -10200.2, 719.282, 21.721, 2.91, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146247; facing estimated)'),
(9950559, 13321, 0, 0, 0, 1, 1, 0, -10166.6, 177.348, 22.5777, 4.02, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146250; facing estimated)'),
(9950560, 13321, 0, 0, 0, 1, 1, 0, -10162.1, 194.668, 20.7642, 4.39, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146251; facing estimated)'),
(9950561, 13321, 0, 0, 0, 1, 1, 0, -10161.2, 173.958, 20.4728, 4.76, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146252; facing estimated)'),
(9950562, 13321, 0, 0, 0, 1, 1, 0, -10157.5, 199.677, 19.6944, 5.13, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146253; facing estimated)'),
(9950563, 13321, 0, 0, 0, 1, 1, 0, -10155.7, 177.278, 18.1481, 5.5, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146254; facing estimated)'),
(9950564, 13321, 0, 0, 0, 1, 1, 0, -10144.9, 17.1177, 21.584, 5.87, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146255; facing estimated)'),
(9950565, 13321, 0, 0, 0, 1, 1, 0, -10144.9, 434.429, 26.7174, 6.24, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146256; facing estimated)'),
(9950566, 13321, 0, 0, 0, 1, 1, 0, -10143.2, 16.0609, 21.3106, 0.33, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146257; facing estimated)'),
(9950567, 13321, 0, 0, 0, 1, 1, 0, -10139, 442.719, 23.0846, 0.7, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146258; facing estimated)'),
(9950568, 13321, 0, 0, 0, 1, 1, 0, -10130.3, 425.983, 23.9461, 1.81, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146261; facing estimated)'),
(9950569, 13321, 0, 0, 0, 1, 1, 0, -10127.5, -21.0402, 22.609, 2.55, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146263; facing estimated)'),
(9950570, 13321, 0, 0, 0, 1, 1, 0, -10124.8, -26.9209, 22.9127, 2.92, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146264; facing estimated)'),
(9950571, 13321, 0, 0, 0, 1, 1, 0, -10123.5, -24.8186, 22.4132, 3.29, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146265; facing estimated)'),
(9950572, 13321, 0, 0, 0, 1, 1, 0, -10118.7, -35.5315, 23.9235, 4.03, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146267; facing estimated)'),
(9950573, 13321, 0, 0, 0, 1, 1, 0, -10116, -23.3745, 20.0494, 4.4, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146268; facing estimated)'),
(9950574, 13321, 0, 0, 0, 1, 1, 0, -10113.5, -31.3858, 21.8537, 4.77, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146269; facing estimated)'),
(9950575, 13321, 0, 0, 0, 1, 1, 0, -10112.7, 375.601, 22.8096, 5.51, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146271; facing estimated)'),
(9950576, 13321, 0, 0, 0, 1, 1, 0, -10112.4, -29.4765, 21.1276, 5.88, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146272; facing estimated)'),
(9950577, 13321, 0, 0, 0, 1, 1, 0, -10112, -28.7135, 20.8546, 6.25, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146273; facing estimated)'),
(9950578, 13321, 0, 0, 0, 1, 1, 0, -10110.5, 372.686, 21.4028, 0.71, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146275; facing estimated)'),
(9950579, 13321, 0, 0, 0, 1, 1, 0, -10107.3, -30.209, 19.9523, 1.82, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146278; facing estimated)'),
(9950580, 13321, 0, 0, 0, 1, 1, 0, -10073.1, -119.185, 21.9381, 4.41, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146285; facing estimated)'),
(9950581, 13321, 0, 0, 0, 1, 1, 0, -10072.5, -114.621, 21.0966, 5.15, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146287; facing estimated)'),
(9950582, 13321, 0, 0, 0, 1, 1, 0, -10071.7, -123.984, 22.3771, 5.89, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146289; facing estimated)'),
(9950583, 13321, 0, 0, 0, 1, 1, 0, -10071.4, -124.227, 22.4856, 6.26, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146290; facing estimated)'),
(9950584, 13321, 0, 0, 0, 1, 1, 0, -10071, -123.364, 22.192, 0.35, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146291; facing estimated)'),
(9950585, 13321, 0, 0, 0, 1, 1, 0, -10070.1, -117.052, 21.1349, 0.72, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146292; facing estimated)'),
(9950586, 13321, 0, 0, 0, 1, 1, 0, -10046.5, -154.988, 22.1513, 3.68, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146300; facing estimated)'),
(9950587, 13321, 0, 0, 0, 1, 1, 0, -10044.6, -157.696, 22.1669, 4.42, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146302; facing estimated)'),
(9950588, 13321, 0, 0, 0, 1, 1, 0, -10041.7, -153.125, 20.8467, 5.53, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146305; facing estimated)'),
(9950589, 13321, 0, 0, 0, 1, 1, 0, -10035.4, -177.169, 23.1288, 1.1, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146310; facing estimated)'),
(9950590, 13321, 0, 0, 0, 1, 1, 0, -10034.8, -192.623, 22.7074, 1.47, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146311; facing estimated)'),
(9950591, 13321, 0, 0, 0, 1, 1, 0, -10033.3, -175.238, 22.3049, 1.84, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146312; facing estimated)'),
(9950592, 13321, 0, 0, 0, 1, 1, 0, -10032.3, -195.022, 22.1887, 2.58, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146314; facing estimated)'),
(9950593, 13321, 0, 0, 0, 1, 1, 0, -10032.2, -179.542, 22.2963, 2.95, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146315; facing estimated)'),
(9950594, 13321, 0, 0, 0, 1, 1, 0, -10029.6, -187.896, 21.771, 3.32, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146316; facing estimated)'),
(9950595, 13321, 0, 0, 0, 1, 1, 0, -10015.2, -1313.23, 25.2621, 5.17, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146321; facing estimated)'),
(9950596, 13321, 0, 0, 0, 1, 1, 0, -10011.2, -1311.47, 23.4067, 5.91, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146323; facing estimated)'),
(9950597, 13321, 0, 0, 0, 1, 1, 0, -10009.9, -1320, 22.8872, 0.37, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146325; facing estimated)'),
(9950598, 13321, 0, 0, 0, 1, 1, 0, -10004, -1102.11, 24.7492, 0.74, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146326; facing estimated)'),
(9950599, 13321, 0, 0, 0, 1, 1, 0, -9997.92, -1091.81, 21.904, 1.48, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146328; facing estimated)'),
(9950600, 13321, 0, 0, 0, 1, 1, 0, -9996.08, -1093.35, 21.4083, 1.85, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146329; facing estimated)'),
(9950601, 13321, 0, 0, 0, 1, 1, 0, -9995.16, -1094.63, 21.0532, 2.22, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146330; facing estimated)'),
(9950602, 13321, 0, 0, 0, 1, 1, 0, -9992.62, -1057.28, 22.257, 2.59, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146331; facing estimated)'),
(9950603, 13321, 0, 0, 0, 1, 1, 0, -9988.49, -1054.75, 21.3923, 2.96, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146332; facing estimated)'),
(9950604, 13321, 0, 0, 0, 1, 1, 0, -9977.61, -936.44, 21.7839, 3.7, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146334; facing estimated)'),
(9950605, 13321, 0, 0, 0, 1, 1, 0, -9975.93, -928.977, 22.5959, 4.44, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146336; facing estimated)'),
(9950606, 13321, 0, 0, 0, 1, 1, 0, -9973.53, -935.904, 21.0554, 5.55, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146339; facing estimated)'),
(9950607, 13321, 0, 0, 0, 1, 1, 0, -9964.98, -802.162, 22.1535, 1.12, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146344; facing estimated)'),
(9950608, 13321, 0, 0, 0, 1, 1, 0, -9963.86, -794.949, 22.3552, 1.49, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146345; facing estimated)'),
(9950609, 13321, 0, 0, 0, 1, 1, 0, -9959.34, -783.836, 21.6004, 2.6, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146348; facing estimated)'),
(9950610, 13321, 0, 0, 0, 1, 1, 0, -9946.75, -731.445, 22.476, 4.45, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146353; facing estimated)'),
(9950611, 13321, 0, 0, 0, 1, 1, 0, -9945.91, -732.519, 22.1444, 4.82, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146354; facing estimated)'),
(9950612, 13321, 0, 0, 0, 1, 1, 0, -9945.57, -738.131, 21.4035, 5.19, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146355; facing estimated)'),
(9950613, 13321, 0, 0, 0, 1, 1, 0, -9917.64, -661.39, 21.5912, 1.5, 300, 5, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Frog (db.exil.es creature_spawn 146362; facing estimated)'),
(9950614, 751501, 0, 0, 0, 1, 1, 0, -10570.0, -1232.1, 28.78, 3.14, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Quartermaster Fenrich (patch-WB1 farmhouse north of Eleanor Zemille; spot in the room and facing estimated)');
UPDATE `creature` SET `position_x` = -10584, `position_y` = -1274, `position_z` = 41.34, `orientation` = 0.26
  WHERE `guid` = 4246 AND `id` = 3133;

-- Discarded Junk (quest 254088) and the Cage Prop: WDB gameobject cache 2026-09-04..07. The Cage Prop is not spawned:
-- the patch-WB1 camp already holds the cage.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`,
  `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`,
  `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
(254693, 3, 1010201, 'Discarded Junk', '', 'Searching', '', 1, 1689, 254693, 0, 0, 0, 0, 0, 0, 254088, 0, 254088, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(523544, 5, 675, 'Cage Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0)
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

DELETE FROM `gameobject_template_addon` WHERE `entry` = 254693;
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`, `mingold`, `maxgold`, `artkit0`, `artkit1`,
  `artkit2`, `artkit3`) VALUES
(254693, 0, 4, 0, 0, 0, 0, 0, 0);

-- The book's chance is estimated: the db.exil.es dump 2026-10-04 (gameobject_loot) lists it with chance 0.
DELETE FROM `gameobject_loot_template` WHERE `Entry` = 254693;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
  `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(254693, 354319, 0, 100, 1, 1, 0, 1, 1, 'Discarded Junk - Half-Finished Book');

-- Quest item drops: db.exil.es dump 2026-10-04 (creature_loot) for the Wedding Ring, Enchanted Dust and Black Ravager
-- Meat. The Valuable Gemstone drops from the creatures whose WDB creaturecache entries list it as a quest item
-- (captures up to 2026-09-05); its 65% chance is estimated. Bandit Support 100209 drops the dust at 75% in the dump
-- (creature_loot) and the Exiles DB export (2026-09-12).
DELETE FROM `creature_loot_template` WHERE (`Entry` = 785 AND `Item` = 355112) OR
  (`Entry` = 787 AND `Item` = 355112) OR
  (`Entry` = 1110 AND `Item` = 355112) OR
  (`Entry` = 910 AND `Item` = 355114) OR
  (`Entry` = 100209 AND `Item` = 355114) OR
  (`Entry` = 628 AND `Item` = 355115) OR
  (`Entry` = 923 AND `Item` = 355115) OR
  (`Entry` = 1258 AND `Item` = 355115) OR
  (`Entry` = 212 AND `Item` = 355113) OR
  (`Entry` = 891 AND `Item` = 355113) OR
  (`Entry` = 892 AND `Item` = 355113) OR
  (`Entry` = 1251 AND `Item` = 355113) OR
  (`Entry` = 1487 AND `Item` = 355113);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
  `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(785, 355112, 0, 65, 1, 1, 0, 1, 1, 'Skeletal Warder - Wedding Ring'),
(787, 355112, 0, 65, 1, 1, 0, 1, 1, 'Skeletal Healer - Wedding Ring'),
(1110, 355112, 0, 65, 1, 1, 0, 1, 1, 'Skeletal Raider - Wedding Ring'),
(910, 355114, 0, 75, 1, 1, 0, 1, 1, 'Defias Enchanter - Enchanted Dust'),
(100209, 355114, 0, 75, 1, 1, 0, 1, 1, 'Bandit Support - Enchanted Dust'),
(628, 355115, 0, 65, 1, 1, 0, 1, 1, 'Black Ravager - Black Ravager Meat'),
(923, 355115, 0, 65, 1, 1, 0, 1, 1, 'Young Black Ravager - Black Ravager Meat'),
(1258, 355115, 0, 65, 1, 1, 0, 1, 1, 'Black Ravager Mastiff - Black Ravager Meat'),
(212, 355113, 0, 65, 1, 1, 0, 1, 1, 'Splinter Fist Warrior - Valuable Gemstone'),
(891, 355113, 0, 65, 1, 1, 0, 1, 1, 'Splinter Fist Fire Weaver - Valuable Gemstone'),
(892, 355113, 0, 65, 1, 1, 0, 1, 1, 'Splinter Fist Taskmaster - Valuable Gemstone'),
(1251, 355113, 0, 65, 1, 1, 0, 1, 1, 'Splinter Fist Firemonger - Valuable Gemstone'),
(1487, 355113, 0, 65, 1, 1, 0, 1, 1, 'Splinter Fist Enslaver - Valuable Gemstone');

-- Object spawns. The junk piles lie among the Defias at Addle's Stead, where quest 254088 sends the player; every
-- spot, facing and respawn time is estimated.
DELETE FROM `gameobject` WHERE `guid` BETWEEN 9001400 AND 9001499;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9001400, 254693, 0, 0, 0, 1, 1, -11008.0, 227.0, 27.01, 1.1, 0, 0, 0.522687, 0.852525, 120, 100, 1, '', 0, 'Discarded Junk (Addle''s Stead among the Defias spawns; spot and facing estimated)'),
(9001401, 254693, 0, 0, 0, 1, 1, -11033.0, 246.0, 26.98, 4.0, 0, 0, 0.909297, -0.416147, 120, 100, 1, '', 0, 'Discarded Junk (Addle''s Stead among the Defias spawns; spot and facing estimated)'),
(9001402, 254693, 0, 0, 0, 1, 1, -11027.0, 276.0, 26.55, 2.6, 0, 0, 0.963558, 0.267499, 120, 100, 1, '', 0, 'Discarded Junk (Addle''s Stead among the Defias spawns; spot and facing estimated)'),
(9001403, 254693, 0, 0, 0, 1, 1, -11014.0, 247.0, 27.01, 5.3, 0, 0, 0.472031, -0.881582, 120, 100, 1, '', 0, 'Discarded Junk (Addle''s Stead among the Defias spawns; spot and facing estimated)'),
(9001404, 254693, 0, 0, 0, 1, 1, -11041.0, 209.0, 27.33, 0.7, 0, 0, 0.342898, 0.939373, 120, 100, 1, '', 0, 'Discarded Junk (Addle''s Stead among the Defias spawns; spot and facing estimated)'),
(9001405, 254693, 0, 0, 0, 1, 1, -11015.0, 197.0, 27.65, 3.4, 0, 0, 0.991665, -0.128844, 120, 100, 1, '', 0, 'Discarded Junk (Addle''s Stead among the Defias spawns; spot and facing estimated)');

-- The objective text 'Vul'Gol Ogre Mound' was captured with a broken apostrophe and is written with a plain one.
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
(254086, 2, 24, 18, 10, 0, 0, 0, 0, 0, 0, 254087, 3, 3110, 675, 0, 0, 0, 0, 0, 8, 0, 375250, 140, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Interrogation', 'Oswin Drake of the Night Watch needs help interrogating the captured worgen', 'Wouldn''t hurt anything at least, and might help us get our answers sooner, so if you want to try I won''t stop you.\n\nJust don''t get too close to the cage, it might try and rip out your throat.', '', 'Return to Oswin Drake of the Night Watch', 764561, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Worgen Interrogated', '', '', '', 0),
(254087, 2, 24, 18, 10, 0, 0, 0, 0, 0, 0, 254088, 3, 5100, 675, 0, 0, 0, 0, 0, 8, 0, 375250, 150, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Taken By the Dark', 'Find Julie Addle at the Scarlet Raven Tavern', 'I remember now, heard tell of a Julie Addle staying at the inn in Darkshire. Have to keep eyes on everyone these days, never know when a commoner might turn out to be something more.\n\nThe three of us are needed here, there''s too few of us already. Still, doubt we''ll get any further this way, if you find yourself at Darkshire, maybe you could seek her out yourself and see if she''ll be any help.', '', 'Find Julie Addle at the Scarlet Raven Tavern', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(254088, 2, 24, 18, 10, 0, 0, 0, 0, 0, 0, 254089, 5, 5100, 675, 0, 0, 0, 0, 0, 8, 0, 375250, 140, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Addle''s Stead', 'Find some trace of Arvis Addle''s old life at Addle''s Stead', 'I apologize. I hadn''t expected any news of him, but I''ll be fine. If he remembers my name, there might still be some hope.\n\nOur farmstead was attacked by worgen some time back, we tried to flee, but they were faster. So my husband...he...he told me to run, and started fighting. Neither of us are fighters, but I didn''t know what to do, so I listened. I ran until I found myself here...I never saw him again after that.\n\nI haven''t tried to return. There''s nothing left for me there now, and I''ve heard even though the worgen are gone, it''s been taken by bandits now.\n\nStill, maybe there''s something left there that he might recognize, some trace of his old life. It might be your best chance.', '', 'Bring the book back to Julie Addle at the Scarlet Raven Tavern', 0, 0, 0, 0, 0, 0, 0, 0, 354319, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(254089, 2, 24, 18, 10, 0, 0, 0, 0, 0, 0, 254091, 4, 5100, 675, 0, 0, 0, 0, 0, 8, 0, 375250, 140, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Addle''s Stead', 'Bring the half-finished book and a bottle of Sweet Nectar to the captured worgen', 'Before you go, I should also mention that he used to stop by this tavern for Sweet Nectar. Never was much for harder drinks, made it hard to write he always said. Maybe if you bring him some that will help too.\n\n...Why am I not coming with?\n\nNo, you''re right. I''m afraid to see him like this. I don''t even know how much of the man I loved he''ll still be, but he''s more likely to recognize me than his half-finished novel and a favorite drink.\n\nIf you get the nectar, I''ll bring the book and meet you there. One way or another, I have to face him.', '', 'Speak with Julie Addle at the Night''s Watch', 0, 0, 0, 0, 0, 0, 0, 0, 1708, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(254091, 2, 24, 18, 10, 0, 0, 0, 0, 0, 0, 0, 4, 5100, 675, 0, 0, 0, 0, 0, 8, 0, 375250, 140, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'May We Be Reunited', 'Speak with Arvis Addle, the captured worgen', '<Julie takes a deep breath.>\n\nAlright, whatever happens here, I''m ready.', '', 'Bring news of Arvis''s words to Captain Aldric Vayne', 254905, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Arvis Addle Questioned', '', '', '', 0),
(255067, 2, 27, 20, 10, 0, 0, 0, 0, 0, 0, 255068, 5, 2200, 765, 0, 0, 0, 0, 0, 8, 0, 375250, 140, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Til Undeath Do We Part', 'Collect wedding rings from under at Raven Hill Cemetary.', 'Wedding bands nowadays are so terribly uninspired wouldn''t you agree?\n\nI''d have one forged to my liking of course-elegant, yet grand...but I haven''t the time, unless...\n\nPerhaps you could place the order with Clarise on my behalf? I trust your judgment…well enough. I''m much too busy tending to my "prospects" at present.\n\nYou can acquire the metal from some...old suitors of mine...they won''t be needing it.', '', 'Speak with Clarise Gnarltree.', 0, 0, 0, 0, 0, 0, 0, 0, 355112, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(255068, 2, 27, 20, 10, 0, 0, 0, 0, 0, 0, 255069, 5, 2200, 765, 0, 0, 0, 0, 0, 8, 0, 375250, 140, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'An Incomplete Order', 'Collect gemstones at the Vul''Gol Ogre Mound.', 'If I know Eleanor, and unfortunately I do, she won’t settle for anything less than the largest diamond I can get my hands on.\n\nOrdinarily I’d order a shipment from Stormwind, but if you’ve met Eleanor, you’ll know she doesn’t care much for waiting.\n\nThe only stones worth cutting in all of Duskwood are buried in the caves the ogres dwell in.\n\nIf you’re truly set on risking your life for that blasted woman, bring me some diamonds from those caves. I’ll see it set properly.', '', 'Return to Clarise Gnarltree.', 0, 0, 0, 0, 0, 0, 0, 0, 355113, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(255069, 2, 27, 20, 10, 0, 0, 0, 0, 0, 0, 0, 3, 2200, 765, 0, 0, 0, 0, 0, 8, 0, 375250, 140, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'From Death Comes Love', 'Bring the delivery to Eleanor Zemille.', 'I''ve finished setting the ring, and what a beauty it is! I''ve never forged a more pristine piece of jewelry.\n\nThe seamless sheen of the metal, and a glistening jewel befitting that of a noble!\n\nIt''s a shame it''ll end up buried at Raven Hill sooner or later...', '', 'Bring the delivery to Eleanor Zemille.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(255070, 2, 26, 20, 10, 0, 0, 0, 0, 0, 0, 0, 5, 2200, 765, 0, 0, 0, 0, 0, 8, 0, 375250, 140, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Tilling Against the Taint', 'Collect Enchanted Dust for Ryton Altham.', 'The only things still clingin’ to life in these cursed fields are my poor pumpkins… and even they’re witherin’ before my eyes...If only I could magically solve all my problems...\n\nMagic..yes! Hey now- don’t look at me like that, I know how it sounds. But I''m not talkin'' about none of that dark stuff. The only other magic I know of though in these woods are used by those thievin'' enchanters down at Addles'' Stead.\n\nWhat do you say we put them to better use?', '', 'Return to Ryton Altham at Darkshire.', 0, 0, 0, 0, 0, 0, 0, 0, 355114, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(255071, 2, 26, 20, 10, 0, 0, 0, 0, 0, 0, 0, 3, 2200, 446, 0, 0, 0, 0, 0, 8, 0, 375250, 140, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Strangers in Our Midst', 'Find the stranger lingering at the edge of town.', 'Been hearing reports of a rather odd looking fellow snooping around the edge of town...\n\nI''ve got my hands tied up here...mind taking a look for me?', '', 'Find the stranger lingering at the edge of town.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(255072, 2, 26, 20, 10, 0, 0, 0, 0, 0, 0, 0, 6, 2200, 446, 0, 0, 0, 0, 0, 8, 0, 375250, 140, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Fool and the Foul', 'Scout locations around Duskwood for Quill the Foolish.', 'It is my sworn duty to brave that which lesser folk dare not face. Why, only recently I ventured into Deadwind Pass itself! A grim place…very grim, after several...strategic withdrawals-\n\nI ventured here to Duskwood!\n\nHowever, I know not where there is thrill to be sought!...Would you be able to aid in me in finding new adventure?', '', 'Return to Quill the Foolish.', 255360, 255361, 255362, 255363, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Tranquil Gardens Cemetary', 'Raven Hill', 'Vul’Gol Ogre Mound', 'Brightwood Grove', 0),
(255073, 2, 24, 18, 10, 0, 0, 0, 0, 0, 0, 0, 5, 2200, 765, 0, 0, 0, 0, 0, 8, 0, 375250, 140, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Skittering Bedfellows', 'Slay Black Widow Hatchlings in Duskwood.', 'You strike me as someone who knows how to handle… troublesome creatures. How fortunate. It seems we may share a talent.\n\nAlas, I find myself in need of a small favor. I would tend to it personally, but I am… otherwise occupied.\n\nThe spiders behind my house have become unbearably loud. Magnificent specimens, truly-such strong legs…such venom. It would be a shame for it go to waste.\n\nAnd yet, they disturb my peace. Silence them for me, won’t you dear?', '', 'Return to Eleanor Zemille.', 930, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0),
(255074, 2, 25, 19, 10, 0, 0, 0, 0, 0, 0, 0, 5, 2200, 446, 0, 0, 0, 0, 0, 8, 0, 375250, 140, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Supplies and Safety', 'Collect meat from Young Black Ravagers, Black Ravager Mastiffs, and Black Ravagers', 'We''ve got wolves on all sides of us. Not quite as dangerous as the undead or the worgen, but plenty enough to rip some poor travelers to shreds.\n\nThen there''s the food shortage, not much grows without sunlight, and Westfall hasn''t had anything to spare recently with the Defias problem. Wolf meat''s certainly not the best solution, but it''s a better one than starving, and it''d let you solve two problems at once.\n\nBring what you gather to Watcher Dodds, he''ll make sure it gets to the rest of the Night Watch.', '', 'Bring the meat to Watcher Dodds', 0, 0, 0, 0, 0, 0, 0, 0, 355115, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, '', '', '', '', 0)
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

DELETE FROM `quest_template_addon` WHERE `ID` IN (254086,254087,254088,254089,254091,255067,255068,255069,255070,255071,
  255072,255073,255074);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `SourceSpellID`, `PrevQuestID`,
  `NextQuestID`, `ExclusiveGroup`, `BreadcrumbForQuestId`, `RewardMailTemplateID`, `RewardMailDelay`,
  `RequiredSkillID`, `RequiredSkillPoints`, `RequiredMinRepFaction`, `RequiredMaxRepFaction`, `RequiredMinRepValue`,
  `RequiredMaxRepValue`, `ProvidedItemCount`, `SpecialFlags`) VALUES
(254086, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(254087, 0, 0, 0, 254086, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(254088, 0, 0, 0, 254087, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(254089, 0, 0, 0, 254088, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(254091, 0, 0, 0, 254089, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255067, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255068, 0, 0, 0, 255067, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255069, 0, 0, 0, 255068, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255070, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255071, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255072, 0, 0, 0, 255071, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255073, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(255074, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

-- Givers and enders follow the captured texts (Details speaker, EndText target). Quartermaster Fenrich gives 255074
-- in MatodanDLC's recordings 7Klf_HWwngk (2026-08-16, 0:04:01) and 6QNRME4U5pY (2026-07-19, 1:01:50). The starter of
-- 255071 is estimated: Commander Althea Ebonlocke, who leads the Night Watch the text speaks for. 255072 follows
-- 255071, whose ender Quill the Foolish gives it.
DELETE FROM `creature_queststarter` WHERE `quest` IN (254086,254087,254088,254089,254091,255067,255068,255069,255070,
  255071,255072,255073,255074);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(255023, 254086),
(255023, 254087),
(254904, 254088),
(254904, 254089),
(254906, 254091),
(751496, 255067),
(3136, 255068),
(3136, 255069),
(255157, 255070),
(264, 255071),
(751502, 255072),
(751496, 255073),
(751501, 255074);

DELETE FROM `creature_questender` WHERE `quest` IN (254086,254087,254088,254089,254091,255067,255068,255069,255070,
  255071,255072,255073,255074);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(255023, 254086),
(254904, 254087),
(254904, 254088),
(254906, 254089),
(764560, 254091),
(3136, 255067),
(3136, 255068),
(751496, 255069),
(255157, 255070),
(751502, 255071),
(751502, 255072),
(751496, 255073),
(888, 255074);

UPDATE `creature_template` SET `npcflag` = `npcflag` | 2 WHERE `entry` = 3136;

-- Credits. No capture describes the live scripts, so every trigger below is estimated; the credit entries are the
-- captured ones. The caged worgen's third gossip step credits 254086. When Julie Addle rewards 'Addle's Stead'
-- (254089), the worgen and Julie hold their recorded talk and Julie then casts the client's 'Arvis Reunion Credit'
-- (355229), which gives every player within 30 yards, and their groups, the 254905 credit of 254091; opening the
-- worgen's gossip casts it too. Coming within 40 yards of each scouting point credits 255072.
-- Captain Aldric Vayne answers Julie's second line 2.5 seconds later, and Ryton Altham's second line follows his first
-- by 12 seconds, as in jLBZUj7KUhw (2026-07-20, 1:51:51-1:51:54 and 1:53:17-1:53:29). Ryton speaks when a player comes
-- within 15 yards; that trigger and its 2-3 minute repeat are estimated.
DELETE FROM `smart_scripts`
  WHERE (`entryorguid` IN (254906,764561,255157,255360,255361,255362,255363) AND `source_type` = 0)
  OR (`entryorguid` IN (25490600, 25515700) AND `source_type` = 9);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`,
  `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
  `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(764561, 0, 0, 0, 62, 0, 100, 0, 9950202, 0, 0, 0, 0, 0, 33, 764561, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Nightbane Worgen - On Gossip Option 0 Selected - Quest Credit ''The Interrogation'''),
(764561, 0, 1, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 355229, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Nightbane Worgen - On Gossip Hello - Cast ''Arvis Reunion Credit'''),
(764561, 0, 2, 0, 62, 0, 100, 0, 9950202, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Nightbane Worgen - On Gossip Option 0 Selected - Close Gossip'),
(254906, 0, 0, 0, 20, 0, 100, 0, 254089, 0, 0, 0, 0, 0, 80, 25490600, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Julie Addle - On Quest ''Addle''''s Stead'' Rewarded - Run Script'),
(25490600, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 19, 764561, 20, 0, 0, 0, 0, 0, 0, 'Julie Addle - Actionlist - Nightbane Worgen Says Line 0'),
(25490600, 9, 1, 0, 0, 0, 100, 0, 3000, 3000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Julie Addle - Actionlist - Julie Addle Says Line 0'),
(25490600, 9, 2, 0, 0, 0, 100, 0, 6000, 6000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 19, 764561, 20, 0, 0, 0, 0, 0, 0, 'Julie Addle - Actionlist - Nightbane Worgen Says Line 1'),
(25490600, 9, 3, 0, 0, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Julie Addle - Actionlist - Julie Addle Says Line 1'),
(25490600, 9, 4, 0, 0, 0, 100, 0, 2500, 2500, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 19, 764560, 20, 0, 0, 0, 0, 0, 0, 'Julie Addle - Actionlist - Captain Aldric Vayne Says Line 0'),
(25490600, 9, 5, 0, 0, 0, 100, 0, 4500, 4500, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 19, 764561, 20, 0, 0, 0, 0, 0, 0, 'Julie Addle - Actionlist - Nightbane Worgen Says Line 2'),
(25490600, 9, 6, 0, 0, 0, 100, 0, 6000, 6000, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Julie Addle - Actionlist - Julie Addle Says Line 2'),
(25490600, 9, 7, 0, 0, 0, 100, 0, 7000, 7000, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 19, 764561, 20, 0, 0, 0, 0, 0, 0, 'Julie Addle - Actionlist - Nightbane Worgen Says Line 3'),
(25490600, 9, 8, 0, 0, 0, 100, 0, 7000, 7000, 0, 0, 0, 0, 1, 4, 0, 0, 0, 0, 0, 19, 764561, 20, 0, 0, 0, 0, 0, 0, 'Julie Addle - Actionlist - Nightbane Worgen Says Line 4'),
(25490600, 9, 9, 0, 0, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Julie Addle - Actionlist - Julie Addle Says Line 3'),
(25490600, 9, 10, 0, 0, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 11, 355229, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Julie Addle - Actionlist - Cast ''Arvis Reunion Credit'''),
(255157, 0, 0, 0, 10, 0, 100, 0, 2, 15, 120000, 180000, 1, 0, 80, 25515700, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ryton Altham - On Player In Range - Run Script'),
(25515700, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ryton Altham - Actionlist - Say Line 0'),
(25515700, 9, 1, 0, 0, 0, 100, 0, 12000, 12000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ryton Altham - Actionlist - Say Line 1'),
(255360, 0, 0, 0, 10, 0, 100, 0, 2, 40, 5000, 5000, 1, 0, 33, 255360, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Tranquil Gardens Cemetary Dummy - On Player In Range - Quest Credit ''The Fool and the Foul'''),
(255361, 0, 0, 0, 10, 0, 100, 0, 2, 40, 5000, 5000, 1, 0, 33, 255361, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Raven Hill Dummy - On Player In Range - Quest Credit ''The Fool and the Foul'''),
(255362, 0, 0, 0, 10, 0, 100, 0, 2, 40, 5000, 5000, 1, 0, 33, 255362, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Vul''Gol Ogre Mound Dummy - On Player In Range - Quest Credit ''The Fool and the Foul'''),
(255363, 0, 0, 0, 10, 0, 100, 0, 2, 40, 5000, 5000, 1, 0, 33, 255363, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Brightwood Grove Dummy - On Player In Range - Quest Credit ''The Fool and the Foul''');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceId` = 0
  AND `SourceEntry` IN (254906,764561,255157,255360,255361,255362,255363);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
  `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
  `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 764561, 0, 0, 9, 0, 254086, 0, 0, 0, 0, 0, '', 'Nightbane Worgen - credit only on ''The Interrogation'''),
(22, 2, 764561, 0, 0, 9, 0, 254091, 0, 0, 0, 0, 0, '', 'Nightbane Worgen - credit only on ''May We Be Reunited'''),
(22, 1, 255360, 0, 0, 9, 0, 255072, 0, 0, 0, 0, 0, '', 'Tranquil Gardens Cemetary Dummy - credit only on ''The Fool and the Foul'''),
(22, 1, 255361, 0, 0, 9, 0, 255072, 0, 0, 0, 0, 0, '', 'Raven Hill Dummy - credit only on ''The Fool and the Foul'''),
(22, 1, 255362, 0, 0, 9, 0, 255072, 0, 0, 0, 0, 0, '', 'Vul''Gol Ogre Mound Dummy - credit only on ''The Fool and the Foul'''),
(22, 1, 255363, 0, 0, 9, 0, 255072, 0, 0, 0, 0, 0, '', 'Brightwood Grove Dummy - credit only on ''The Fool and the Foul''');

-- Duskwood creature cache values: Ascension creaturecache.wdb captures up to 2026-09-08, matching the db.exil.es dump
-- 2026-10-04 (creature).
UPDATE `creature_template` SET `rank` = 2 WHERE `entry` IN (503,507,521,771);

-- Nightbane Vile Fang level range: db.exil.es dump 2026-10-04, creature.
UPDATE `creature_template` SET `minlevel` = 29 WHERE `entry` = 206;
