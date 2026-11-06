-- Kaldros Depthbreaker (978080), Ascension's world boss of Depthbreaker's Hollow (map 884, as the quick guide shows
-- the fight), built the way Setis is: a shrine under the sea off Sardor Isle (Feralas) takes players in (Normal only), the portal he
-- leaves where he falls and the shrine at the entrance take them back, and players who die there rise at its start.
-- No log: his kit is his spell block (boss_kaldros_coa), his health is designed per player in his map (10 to 40).

INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`,
  `speed_walk`, `speed_run`, `rank`, `unit_class`, `type`, `lootid`, `HealthModifier`, `DamageModifier`,
  `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(978080, 'Kaldros Depthbreaker', '', 63, 63, 0, 14, 0, 1, 1.14286, 3, 1, 1, 978080, 100, 20, 1, 1,
  'boss_kaldros_coa', 12340)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `rank` = VALUES(`rank`), `lootid` = VALUES(`lootid`),
  `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 978080;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(978080, 0, 17528, 0.6, 1, 12340);

DELETE FROM `coa_world_boss_level` WHERE `entry` = 978080;
INSERT INTO `coa_world_boss_level` (`entry`, `difficulty`, `health`, `damage_pct`, `note`) VALUES
(978080, 0, 1120000, 100, 'per player; no log: Korrim Snowgrave''s level'),
(978080, 2, 1426000, 100, 'per player; no log: Korrim Snowgrave''s level');

-- Loot: one roll of his twelve items (item level 74, as the quick guide shows them); kaldros_instance_death_coa rolls
-- one more for every four players in his map.
DELETE FROM `creature_loot_template` WHERE `Entry` = 978080;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(978080, 18614, 0, 0, 0, 1, 1, 1, 1, 'Kaldros - Coral Cutter'),
(978080, 18575, 0, 0, 0, 1, 1, 1, 1, 'Kaldros - Corsair Cape'),
(978080, 18618, 0, 0, 0, 1, 1, 1, 1, 'Kaldros - Deep Sea Oculus'),
(978080, 18908, 0, 0, 0, 1, 1, 1, 1, 'Kaldros - Drowned Highborne Slicer'),
(978080, 18613, 0, 0, 0, 1, 1, 1, 1, 'Kaldros - Mana Vein Boots'),
(978080, 18916, 0, 0, 0, 1, 1, 1, 1, 'Kaldros - Ocean Kilt'),
(978080, 12140, 0, 0, 0, 1, 1, 1, 1, 'Kaldros - Ocean Song'),
(978080, 18113, 0, 0, 0, 1, 1, 1, 1, 'Kaldros - Sea Speaker Amulet'),
(978080, 18907, 0, 0, 0, 1, 1, 1, 1, 'Kaldros - Sinister Council Staff'),
(978080, 18576, 0, 0, 0, 1, 1, 1, 1, 'Kaldros - Tempest Charm'),
(978080, 18574, 0, 0, 0, 1, 1, 1, 1, 'Kaldros - Tide Bender Cord'),
(978080, 18573, 0, 0, 0, 1, 1, 1, 1, 'Kaldros - Tideforged Sharpshooter');

-- He waits in the hollow, on its graveyard's floor; the shrine stands on the shore (ground height measured).
DELETE FROM `creature` WHERE `guid` IN (9780920, 9780921);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`) VALUES
(9780920, 978080, 884, 10240, 10240, 1, 1, -4730.0, 2466.5, -82.41, 3.1416, 604800, 0, 0),
(9780921, 978081, 1, 0, 0, 1, 1, -4748.838, 2697.8623, -147.7, 3.9223, 300, 0, 0);

-- The shrine on the Feralas coast, the portal out and the shrine at the entrance of the hollow.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(978080, 10, 4076, 'Shrine of Kaldros', '', '', '', 3, '', 'go_kaldros_altar_coa', 12340),
(978081, 10, 4396, 'Portal to Feralas', '', '', '', 1.5, '', 'go_kaldros_exit_coa', 12340),
(978082, 10, 4076, 'Shrine of Kaldros', '', '', '', 3, '', 'go_kaldros_leave_coa', 12340)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
  `size` = VALUES(`size`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `gameobject` WHERE `guid` IN (9780920, 9780921);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`) VALUES
(9780920, 978080, 1, 0, 0, 1, 1, -4748.838, 2697.8623, -152.733, 3.9223, 0, 0, 0.924772, -0.380521, 300, 100, 1),
(9780921, 978082, 884, 10240, 10240, 1, 1, -4746.0, 2462.0, -82.41, 0, 0, 0, 0, 1, 300, 100, 1);

-- Players who die there rise at its start: WorldSafeLocs.dbc 6084 "Depthbreaker's Hollow Boss map Graveyard".
DELETE FROM `game_graveyard` WHERE `ID` = 6084;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(6084, 884, -4751.12, 2466.51, -82.4105, 'Depthbreaker''s Hollow Boss map Graveyard');
DELETE FROM `graveyard_zone` WHERE `ID` = 6084 AND `GhostZone` = 10240;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(6084, 10240, 0, 'Depthbreaker''s Hollow (Kaldros Depthbreaker boss map)');

-- The shrine's words.
DELETE FROM `npc_text` WHERE `ID` = 978080;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`) VALUES
(978080, 'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.',
  'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.');

-- His hologram above the shrine: ghostly (22650), rooted, and frozen in place (16245).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
  `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `type_flags`, `AIName`, `ScriptName`,
  `VerifiedBuild`) VALUES
(978081, 'Kaldros Depthbreaker', '', 63, 63, 35, 0, 1, 1, 1, 33554434, 1, 0, '', '', 12340)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `faction` = VALUES(`faction`), `unit_flags` = VALUES(`unit_flags`),
  `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 978081;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(978081, 0, 17528, 0.1, 1, 12340);
DELETE FROM `creature_template_addon` WHERE `entry` = 978081;
INSERT INTO `creature_template_addon` (`entry`, `auras`) VALUES (978081, '22650 16245');
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 978081;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(978081, 1, 0, 0, 1);
