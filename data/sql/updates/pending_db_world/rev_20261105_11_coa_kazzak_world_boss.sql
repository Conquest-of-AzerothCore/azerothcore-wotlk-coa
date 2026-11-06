-- Lord Kazzak (12397) in his boss map (882, Throne of the Doom Lord), the way Setis is fought: the Shrine of Lord
-- Kazzak in the Tainted Scar takes players in (Normal only), the portal he leaves where he falls and the shrine at
-- the entrance take them back, and players who die in his map rise at its start.

-- Ascension fights him in his map as his own entry, 64604 "Lord Kazzak" (kill credit 12397, HealthModifier 3200),
-- the way Setis is 64600; it shares 12397's loot. Of that loot only his ten world boss items change: one equal roll
-- of them (the quick guide's list) in group 1, and kazzak_instance_death_coa rolls one more for every four players.
-- His other rows (runes, felcloth, references, recipes, Summoner's Stone) stay as they are, and every kill gives a
-- Treasures of Azeroth (1615011), as on live.
DROP TEMPORARY TABLE IF EXISTS `coa_kazzak_tmp`;
CREATE TEMPORARY TABLE `coa_kazzak_tmp` SELECT * FROM `creature_template` WHERE `entry` = 12397;
UPDATE `coa_kazzak_tmp` SET `entry` = 64604, `lootid` = 12397, `KillCredit1` = 12397, `HealthModifier` = 3200,
  `AIName` = '', `ScriptName` = 'boss_kazzak_coa';
INSERT INTO `creature_template` SELECT * FROM `coa_kazzak_tmp`
ON DUPLICATE KEY UPDATE `lootid` = 12397, `KillCredit1` = 12397, `HealthModifier` = 3200,
  `ScriptName` = 'boss_kazzak_coa';
DROP TEMPORARY TABLE `coa_kazzak_tmp`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 64604;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(64604, 0, 12449, 1.5, 1, 12340);
UPDATE `creature` SET `id` = 64604 WHERE `guid` = 9780100 AND `id` IN (12397, 64604);

UPDATE `creature_template` SET `lootid` = 12397 WHERE `entry` = 12397;
DELETE FROM `creature_loot_template` WHERE `Entry` = 12397 AND `Item` IN (17111, 17112, 17113, 18204,
  18543, 18544, 18546, 19133, 19134, 19135, 1615011);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(12397, 17111, 0, 0, 0, 1, 1, 1, 1, 'Lord Kazzak - Blazefury Medallion'),
(12397, 17112, 0, 0, 0, 1, 1, 1, 1, 'Lord Kazzak - Empyrean Demolisher'),
(12397, 17113, 0, 0, 0, 1, 1, 1, 1, 'Lord Kazzak - Amberseal Keeper'),
(12397, 18204, 0, 0, 0, 1, 1, 1, 1, 'Lord Kazzak - Eskhandar''s Pelt'),
(12397, 18543, 0, 0, 0, 1, 1, 1, 1, 'Lord Kazzak - Ring of Entropy'),
(12397, 18544, 0, 0, 0, 1, 1, 1, 1, 'Lord Kazzak - Doomhide Gauntlets'),
(12397, 18546, 0, 0, 0, 1, 1, 1, 1, 'Lord Kazzak - Infernal Headcage'),
(12397, 19133, 0, 0, 0, 1, 1, 1, 1, 'Lord Kazzak - Fel Infused Leggings'),
(12397, 19134, 0, 0, 0, 1, 1, 1, 1, 'Lord Kazzak - Flayed Doomguard Belt'),
(12397, 19135, 0, 0, 0, 1, 1, 1, 1, 'Lord Kazzak - Blacklight Bracer'),
(12397, 1615011, 0, 100, 0, 1, 0, 1, 1, 'Lord Kazzak - Treasures of Azeroth');
-- His world-drop references keep their own single roll, in group 2, so they never take the place of his item.
UPDATE `creature_loot_template` SET `GroupId` = 2 WHERE `Entry` = 12397 AND `Reference` BETWEEN 24016 AND 24053
  AND `GroupId` = 1;

-- His health is per player in his map (10 to 40): Ascension's boss-map logs (64604) end at 17.62M with 35-37
-- players and 17.95M with 38, about 476,000 a player.
DELETE FROM `coa_world_boss` WHERE `entry` = 64604;
INSERT INTO `coa_world_boss` (`entry`, `health`, `per_player`, `radius`, `min_players`, `max_players`, `comment`)
VALUES (64604, 17620000, 476000, 1000, 10, 40, 'Lord Kazzak (map 882): per player, boss-map log 2026-07-18 37 players');

-- The shrine now runs go_kazzak_altar_coa, which refuses the heroic difficulties, instead of its SmartAI teleport.
UPDATE `gameobject_template` SET `type` = 10, `size` = 3, `Data3` = 0, `AIName` = '',
  `ScriptName` = 'go_kazzak_altar_coa'
WHERE `entry` = 280137;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 280137 AND `source_type` = 1;
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 9780137;
DELETE FROM `gossip_menu` WHERE `MenuID` = 9780137;

-- The portal out and the shrine at the entrance of his map.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(978074, 10, 4396, 'Portal to the Tainted Scar', '', '', '', 1.5, '', 'go_kazzak_exit_coa', 12340),
(978075, 10, 4076, 'Shrine of Lord Kazzak', '', '', '', 3, '', 'go_kazzak_leave_coa', 12340)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
  `size` = VALUES(`size`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `gameobject` WHERE `guid` = 9780913;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`) VALUES
(9780913, 978075, 882, 10237, 10237, 15, 1, -12564.0, -2377.0, 53.65, 2.5682, 0, 0, 0.9590, 0.2834, 300, 100, 1);

-- Players who die in his map rise at its start: WorldSafeLocs.dbc 6082 "Kazzak Graveyard".
DELETE FROM `game_graveyard` WHERE `ID` = 6082;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(6082, 882, -12569.7, -2373.38, 53.6509, 'Kazzak Graveyard');
DELETE FROM `graveyard_zone` WHERE `ID` = 6082 AND `GhostZone` = 10237;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(6082, 10237, 0, 'Throne of the Doom Lord (Lord Kazzak boss map)');

-- His hologram above the shrine: ghostly (22650), rooted, and frozen in place (16245).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
  `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `type_flags`, `AIName`, `ScriptName`,
  `VerifiedBuild`) VALUES
(978074, 'Lord Kazzak', '', 63, 63, 35, 0, 1, 1, 1, 33554434, 3, 0, '', '', 12340)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `faction` = VALUES(`faction`),
  `npcflag` = VALUES(`npcflag`), `unit_flags` = VALUES(`unit_flags`), `type_flags` = VALUES(`type_flags`),
  `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 978074;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(978074, 0, 12449, 0.3, 1, 12340);
DELETE FROM `creature_template_addon` WHERE `entry` = 978074;
INSERT INTO `creature_template_addon` (`entry`, `auras`) VALUES (978074, '22650 16245');
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 978074;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(978074, 1, 0, 0, 1);
DELETE FROM `creature` WHERE `guid` = 9780914;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`) VALUES
(9780914, 978074, 0, 4, 73, 1, 1, -11665.856, -2371.7654, 5.5, 0.6004, 300, 0, 0);
