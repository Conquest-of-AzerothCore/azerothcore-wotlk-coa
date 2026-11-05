-- Azuregos (6109) in the boss map Ascension built for him (881, "Azuregos (PvE)"), the way Setis is fought: the
-- shrine where he stood in Azshara takes players in, the portal he leaves where he falls and the shrine at the
-- entrance take them back, and players who die in his map rise at its start.

-- Loot: one roll of his items here; azuregos_instance_death_coa rolls one more for every four players in his map.
UPDATE `creature_template` SET `lootid` = 6109 WHERE `entry` = 6109;
DELETE FROM `creature_loot_template` WHERE `Entry` = 6109;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(6109, 17070, 0, 0, 0, 1, 1, 1, 1, 'Azuregos - Fang of the Mystics'),
(6109, 18202, 0, 0, 0, 1, 1, 1, 1, 'Azuregos - Eskhandar''s Left Claw'),
(6109, 18208, 0, 0, 0, 1, 1, 1, 1, 'Azuregos - Drape of Benediction'),
(6109, 18541, 0, 0, 0, 1, 1, 1, 1, 'Azuregos - Puissant Cape'),
(6109, 18542, 0, 0, 0, 1, 1, 1, 1, 'Azuregos - Typhoon'),
(6109, 18545, 0, 0, 0, 1, 1, 1, 1, 'Azuregos - Leggings of Arcane Supremacy'),
(6109, 18547, 0, 0, 0, 1, 1, 1, 1, 'Azuregos - Unmelting Ice Girdle'),
(6109, 19130, 0, 0, 0, 1, 1, 1, 1, 'Azuregos - Cold Snap'),
(6109, 19131, 0, 0, 0, 1, 1, 1, 1, 'Azuregos - Snowblind Shoes'),
(6109, 19132, 0, 0, 0, 1, 1, 1, 1, 'Azuregos - Crystal Adorned Crown'),
(6109, 18704, 0, 10, 0, 1, 0, 1, 1, 'Azuregos - Mature Blue Dragon Sinew'),
(6109, 11938, 0, 100, 0, 1, 0, 1, 1, 'Azuregos - Sack of Gems');

-- His map had no instance_template row, so the server refused every teleport there.
DELETE FROM `instance_template` WHERE `map` = 881;
INSERT INTO `instance_template` (`map`, `parent`, `script`, `allowMount`) VALUES (881, 0, '', 0);

-- He moves into his map, ahead of its graveyard.
UPDATE `creature` SET `map` = 881, `zoneId` = 10236, `areaId` = 10236, `spawnMask` = 15,
  `position_x` = 2890.0, `position_y` = -4950.0, `position_z` = 258.41, `orientation` = 0.86
WHERE `guid` = 52349 AND `id` = 6109;

-- His health is per player in his map (10 to 40): the Ascension kill's pool over its 24 players.
UPDATE `coa_world_boss` SET `per_player` = 1615022, `radius` = 1000,
  `comment` = 'Azuregos: per player in his map, the Ascension kill of 24 players'
WHERE `entry` = 6109;

-- The shrine where he stood in Azshara, the portal out and the shrine at the entrance of his map.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(978070, 10, 4076, 'Shrine of Azuregos', '', '', '', 3, '', 'go_azuregos_altar_coa', 12340),
(978071, 10, 4396, 'Portal to Azshara', '', '', '', 1.5, '', 'go_azuregos_exit_coa', 12340),
(978072, 10, 4076, 'Shrine of Azuregos', '', '', '', 3, '', 'go_azuregos_leave_coa', 12340)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
  `size` = VALUES(`size`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `gameobject` WHERE `guid` IN (9780910, 9780911);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`) VALUES
(9780910, 978070, 1, 0, 0, 1, 1, 2622.22, -5977.93, 100.76, 4.2121, 0, 0, 0.8607, -0.5091, 300, 100, 1),
(9780911, 978072, 881, 0, 0, 15, 1, 2953.0, -4886.0, 241.06, 0, 0, 0, 0, 1, 300, 100, 1);

-- Players who die in his map rise at its start: WorldSafeLocs.dbc 6081 "Azuregos Graveyard".
DELETE FROM `game_graveyard` WHERE `ID` = 6081;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(6081, 881, 2948.83, -4882.32, 241.063, 'Azuregos Graveyard');
DELETE FROM `graveyard_zone` WHERE `ID` = 6081 AND `GhostZone` = 10236;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(6081, 10236, 0, 'Azuregos (PvE) boss map');

-- The shrine's words.
DELETE FROM `npc_text` WHERE `ID` = 978070;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`) VALUES
(978070, 'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.',
  'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.');

-- His hologram above the shrine: ghostly (22650), rooted, and frozen in place (16245).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
  `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `type_flags`, `AIName`, `ScriptName`,
  `VerifiedBuild`) VALUES
(978070, 'Azuregos', '', 63, 63, 35, 0, 1, 1, 1, 33554434, 2, 0, '', '', 12340)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `faction` = VALUES(`faction`),
  `npcflag` = VALUES(`npcflag`), `unit_flags` = VALUES(`unit_flags`), `type_flags` = VALUES(`type_flags`),
  `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 978070;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(978070, 0, 11460, 0.15, 1, 12340);
DELETE FROM `creature_template_addon` WHERE `entry` = 978070;
INSERT INTO `creature_template_addon` (`entry`, `auras`) VALUES (978070, '22650 16245');
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 978070;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(978070, 1, 0, 0, 1);
DELETE FROM `creature` WHERE `guid` = 9780910;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`) VALUES
(9780910, 978070, 1, 0, 0, 1, 1, 2622.22, -5977.93, 106.0, 4.2121, 300, 0, 0);
