-- Azuregos in the boss map Ascension built for him (881, "Azuregos (PvE)"), the way Setis is fought: the
-- shrine where he stands in Azshara takes players in, the portal he leaves where he falls and the shrine at the
-- entrance take them back, and players who die in his map rise at its start.

-- Ascension fights him in his map as his own entry, 64601 "Azuregos" (kill credit 6109, his spells and model), the
-- way Setis is 64600; the open-world 6109 stays where he is. Same loot table: one roll of his items here, and
-- azuregos_instance_death_coa rolls one more for every four players in his map.
DROP TEMPORARY TABLE IF EXISTS `coa_azuregos_tmp`;
CREATE TEMPORARY TABLE `coa_azuregos_tmp` SELECT * FROM `creature_template` WHERE `entry` = 6109;
UPDATE `coa_azuregos_tmp` SET `entry` = 64601, `rank` = 3, `lootid` = 6109, `KillCredit1` = 6109,
  `HealthModifier` = 3200, `AIName` = '', `ScriptName` = 'boss_azuregos_coa';
INSERT INTO `creature_template` SELECT * FROM `coa_azuregos_tmp`
ON DUPLICATE KEY UPDATE `rank` = 3, `lootid` = 6109, `KillCredit1` = 6109, `HealthModifier` = 3200,
  `ScriptName` = 'boss_azuregos_coa';
DROP TEMPORARY TABLE `coa_azuregos_tmp`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 64601;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(64601, 0, 11460, 1, 1, 12340);
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
(6109, 18704, 0, 60, 0, 1, 0, 1, 1, 'Azuregos - Mature Blue Dragon Sinew'),
(6109, 1005012, 0, 100, 0, 1, 0, 1, 1, 'Azuregos - Scale of Azuregos'),
(6109, 1180234, 0, 1, 0, 1, 0, 1, 1, 'Azuregos - Draconic Warhorn: Azuregos'),
(6109, 11938, 0, 100, 0, 1, 0, 1, 1, 'Azuregos - Sack of Gems');

-- His map belongs to Kalimdor, as Setis' 880 does.
UPDATE `instance_template` SET `parent` = 1 WHERE `map` = 881;

-- 64601 stands in his map, ahead of its graveyard (ground height measured).
DELETE FROM `creature` WHERE `guid` = 9780912;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`) VALUES
(9780912, 64601, 881, 10236, 10236, 15, 1, 2890.0, -4950.0, 258.41, 0.86, 604800, 0, 0);

-- His health is per player in his map (10 to 40): the Ascension kill's pool over its 24 players.
DELETE FROM `coa_world_boss` WHERE `entry` = 64601;
INSERT INTO `coa_world_boss` (`entry`, `health`, `per_player`, `radius`, `min_players`, `max_players`, `comment`)
VALUES (64601, 38760524, 1615022, 1000, 10, 40, 'Azuregos (map 881): per player, the Ascension kill of 24 players');

-- The shrine where he stands in Azshara (Ascension's 280139), the portal out and the shrine at the entrance of his map.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(280139, 10, 4076, 'Shrine of Azuregos', '', '', '', 3, '', 'go_azuregos_altar_coa', 12340),
(978071, 10, 4396, 'Portal to Azshara', '', '', '', 1.5, '', 'go_azuregos_exit_coa', 12340),
(978072, 10, 4076, 'Shrine of Azuregos', '', '', '', 3, '', 'go_azuregos_leave_coa', 12340)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
  `size` = VALUES(`size`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `gameobject` WHERE `guid` IN (9780910, 9780911);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`) VALUES
(9780910, 280139, 1, 0, 0, 1, 1, 2622.22, -5977.93, 100.76, 4.2121, 0, 0, 0.860139, -0.510059, 300, 100, 1),
(9780911, 978072, 881, 0, 0, 15, 1, 2953.0, -4886.0, 243.2, 0, 0, 0, 0, 1, 300, 100, 1);

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
(9780910, 280139, 1, 0, 0, 1, 1, 2622.22, -5977.93, 106.0, 4.2121, 300, 0, 0);

-- The Treasures of Azeroth chest every world boss gives (1615011) has a 5% roll at any world boss item (978060):
-- his items join that pool.
INSERT IGNORE INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
  `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 978060, l.`Item`, 0, 0, 0, 1, 1, 1, 1, CONCAT('Treasures of Azeroth - World Boss - ', i.`name`)
FROM `creature_loot_template` l JOIN `item_template` i ON i.`entry` = l.`Item`
WHERE l.`Entry` = 6109 AND l.`GroupId` = 1 AND l.`Reference` = 0 AND i.`Quality` = 4;

-- World bosses give Ascension's own Treasures of Azeroth chest (1615011), which holds what 978059 holds;
-- 978059 keeps its loot for the chests players still hold.
DELETE FROM `item_loot_template` WHERE `Entry` = 1615011;
INSERT INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(1615011, 978059, 978059, 100, 0, 1, 0, 1, 1, 'Treasures of Azeroth - a Heroic Dungeon epic'),
(1615011, 978060, 978060, 5, 0, 1, 0, 1, 1, 'Treasures of Azeroth - 5% a world boss item'),
(1615011, 400750, 0, 100, 0, 1, 0, 15, 15, 'Treasures of Azeroth - 15 Raider''s Commendations'),
(1615011, 978061, 978061, 100, 0, 1, 0, 4, 4, 'Treasures of Azeroth - 1000 Runes of Descension (250 x 4)');
