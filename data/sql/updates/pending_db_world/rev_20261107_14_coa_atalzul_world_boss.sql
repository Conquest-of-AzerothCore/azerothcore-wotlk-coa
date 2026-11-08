-- Atal'zul, the Soulreaver (67532) in his boss map (890), the way Setis is fought: a shrine in the Eastern
-- Plaguelands by Zul'Mashar takes players in (Normal only), the portal he leaves where he falls and the shrine at
-- the entrance take them back, and players who die in his map rise at its start. The shrine's spot is a taken in game.

-- Loot: one roll of his 8 items (item level 74, as the quick guide shows them);
-- atalzul_instance_death_coa rolls one more for every four players in his map.
UPDATE `creature_template` SET `lootid` = 67532 WHERE `entry` = 67532;
DELETE FROM `creature_loot_template` WHERE `Entry` = 67532;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(67532, 11425, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Band of the Dead'),
(67532, 11429, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Desecrator'),
(67532, 11426, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Shroud of Sacrifice'),
(67532, 11330, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Signet of the Soulflayer'),
(67532, 11428, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Skullcrusher'),
(67532, 11430, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Soul Essence Vial'),
(67532, 11427, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Soulrender Rifle'),
(67532, 11329, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Talisman of Soul Theft');

-- The Treasures of Azeroth chest every world boss gives (978059) has a 5% roll at any world boss item (978060):
-- his items join that pool.
INSERT IGNORE INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
  `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 978060, l.`Item`, 0, 0, 0, 1, 1, 1, 1, CONCAT('Treasures of Azeroth - World Boss - ', i.`name`)
FROM `creature_loot_template` l JOIN `item_template` i ON i.`entry` = l.`Item`
WHERE l.`Entry` = 67532 AND l.`GroupId` = 1 AND l.`Reference` = 0 AND i.`Quality` = 4;

-- His health is per player in his map (10 to 40): each kill's pool over its players.
UPDATE `coa_world_boss_level` SET `health` = 1272231, `note` = 'per player; Atal''zul kill 01:28, 20 players'
WHERE `entry` = 67532 AND `difficulty` = 0;
UPDATE `coa_world_boss_level` SET `health` = 1272231, `note` = 'per player; Atal''zul kill 01:28, 20 players'
WHERE `entry` = 67532 AND `difficulty` = 2;

-- The shrine, the portal out and the shrine at the entrance of his map.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(978090, 10, 4076, 'Shrine of Atal''zul', '', '', '', 3, '', 'go_atalzul_altar_coa', 12340),
(978091, 10, 4396, 'Portal to Zul''Mashar', '', '', '', 1.5, '', 'go_atalzul_exit_coa', 12340),
(978092, 10, 4076, 'Shrine of Atal''zul', '', '', '', 3, '', 'go_atalzul_leave_coa', 12340)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
  `size` = VALUES(`size`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `gameobject` WHERE `guid` IN (9780930, 9780931);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`) VALUES
(9780930, 978090, 0, 0, 0, 1, 1, 3335.8843, -4842.772, 167.1344, 5.1617, 0, 0, 0.531815, -0.846860, 300, 100, 1),
(9780931, 978092, 890, 10281, 10281, 15, 1, 3358.02, -4839.59, 167.44, 0, 0, 0, 0, 1, 300, 100, 1);

-- Players who die in his map rise at its start: WorldSafeLocs.dbc 6090.
DELETE FROM `game_graveyard` WHERE `ID` = 6090;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(6090, 890, 3353.02, -4844.59, 167.44, 'Atalzulbossmap Boss map Graveyard');
DELETE FROM `graveyard_zone` WHERE `ID` = 6090 AND `GhostZone` = 10281;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(6090, 10281, 0, 'Zul''Mashar (Atal''zul boss map)');

-- The shrine's words.
DELETE FROM `npc_text` WHERE `ID` = 978090;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`) VALUES
(978090, 'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.',
  'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.');

-- His hologram above the shrine: ghostly (22650), rooted, and frozen in place (16245).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
  `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `type_flags`, `AIName`, `ScriptName`,
  `VerifiedBuild`) VALUES
(978090, 'Atal''zul, the Soulreaver', '', 63, 63, 35, 0, 1, 1, 1, 33554434, 7, 0, '', '', 12340)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `faction` = VALUES(`faction`), `unit_flags` = VALUES(`unit_flags`),
  `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 978090;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(978090, 0, 6708, 1, 1, 12340);
DELETE FROM `creature_template_addon` WHERE `entry` = 978090;
INSERT INTO `creature_template_addon` (`entry`, `auras`) VALUES (978090, '22650 16245');
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 978090;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(978090, 1, 0, 0, 1);
DELETE FROM `creature` WHERE `guid` = 9780932;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`) VALUES
(9780932, 978090, 0, 0, 0, 1, 1, 3335.8843, -4842.772, 172.13, 5.1617, 300, 0, 0);

-- In his map Zul'rogg starts on top of the pyramid and the four Soul Vessels stand around it (spots taken in game).
UPDATE `creature` SET `position_x` = 3439.5637, `position_y` = -4982.276, `position_z` = 195.7287,
  `orientation` = 2.3572 WHERE `guid` = 9780105 AND `id` = 67533;
UPDATE `creature` SET `position_x` = 3404.716, `position_y` = -4901.075, `position_z` = 159.3792
WHERE `guid` = 9780106;
UPDATE `creature` SET `position_x` = 3358.0588, `position_y` = -4949.7046, `position_z` = 159.3839
WHERE `guid` = 9780107;
UPDATE `creature` SET `position_x` = 3328.0198, `position_y` = -4888.4087, `position_z` = 159.2575
WHERE `guid` = 9780108;
UPDATE `creature` SET `position_x` = 3377.5986, `position_y` = -4873.0796, `position_z` = 159.2516
WHERE `guid` = 9780109;

-- Atal'zul and Zul'rogg are undead: both look ghostly (22650), as on Ascension.
DELETE FROM `creature_template_addon` WHERE `entry` IN (67532, 67533);
INSERT INTO `creature_template_addon` (`entry`, `auras`) VALUES (67532, '22650'), (67533, '22650');

-- Their models (DevModels gallery): Atal'zul the troll lich (79329), also for his hologram; Zul'rogg the dire troll
-- (79411).
UPDATE `creature_template_model` SET `CreatureDisplayID` = 79329 WHERE `CreatureID` IN (67532, 978090);
UPDATE `creature_template_model` SET `CreatureDisplayID` = 79411 WHERE `CreatureID` = 67533;
