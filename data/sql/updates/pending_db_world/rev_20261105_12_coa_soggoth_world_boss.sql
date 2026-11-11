-- The Will of Soggoth (64605) in his boss map (883, Master's Gastric Pit), the way Setis is fought: a shrine in the
-- open world takes players in (Normal only), the portal he leaves where he falls and the shrine at the entrance take
-- them back, and players who die in his map rise at its start.

-- Loot: one roll of his eleven items (item level 68, as the quick guide shows them); soggoth_instance_death_coa rolls
-- one more for every four players in his map.
UPDATE `creature_template` SET `lootid` = 64605 WHERE `entry` = 64605;
DELETE FROM `creature_loot_template` WHERE `Entry` = 64605;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(64605, 11274, 0, 0, 0, 1, 1, 1, 1, 'The Will of Soggoth - Breastplate of the Void''s Fury'),
(64605, 11271, 0, 0, 0, 1, 1, 1, 1, 'The Will of Soggoth - Eles''finel'),
(64605, 11328, 0, 0, 0, 1, 1, 1, 1, 'The Will of Soggoth - Guidance of the Old Gods'),
(64605, 11327, 0, 0, 0, 1, 1, 1, 1, 'The Will of Soggoth - Shroud of Soothing Twilight'),
(64605, 11275, 0, 0, 0, 1, 1, 1, 1, 'The Will of Soggoth - The Darkened Gaze'),
(64605, 11431, 0, 0, 0, 1, 1, 1, 1, 'The Will of Soggoth - The Deceiving Refraction'),
(64605, 11326, 0, 0, 0, 1, 1, 1, 1, 'The Will of Soggoth - The Dreaming Eternity'),
(64605, 11277, 0, 0, 0, 1, 1, 1, 1, 'The Will of Soggoth - Thorn of Aydreath'),
(64605, 11276, 0, 0, 0, 1, 1, 1, 1, 'The Will of Soggoth - Treads of Twilight Shadow'),
(64605, 11272, 0, 0, 0, 1, 1, 1, 1, 'The Will of Soggoth - Twilight Faceguard'),
(64605, 11273, 0, 0, 0, 1, 1, 1, 1, 'The Will of Soggoth - Visage of Aydreath');

-- He waits in the middle of the pit (WorldMapArea 2037), below the ledge his map starts on, so players do not land
-- on top of him; floor height measured.
UPDATE `creature` SET `position_x` = 4530.0, `position_y` = 250.0, `position_z` = 31.48, `orientation` = 3.1416
WHERE `guid` = 9780102 AND `id` = 64605;

-- His health is per player in his map (10 to 40). The CoA logs of Normal kills end at 20.14M with 38 players and
-- 20.91M with 40, about 523,000 a player; only Normal is open, so the heroic row stays as it is.
UPDATE `coa_world_boss_level` SET `health` = 523000, `note` = 'per player; Normal kill logs, 40 players 20.91M'
WHERE `entry` = 64605 AND `difficulty` = 0;
-- His model, as Creature.dbc gives it (FacelessOne, green).
UPDATE `creature_template_model` SET `CreatureDisplayID` = 228465, `DisplayScale` = 1 WHERE `CreatureID` = 64605;

-- Ascension's Shrine of Soggoth (280144) in Darkshore by the Master's Glaive, where his cultists wake him (quests
-- 1006500, 100076; spot taken in game), the portal out and the shrine at the entrance of his map.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(280144, 10, 4076, 'Shrine of Soggoth', '', '', '', 3, '', 'go_soggoth_altar_coa', 12340),
(978078, 10, 4396, 'Portal out of the Gastric Pit', '', '', '', 1.5, '', 'go_soggoth_exit_coa', 12340),
(978079, 10, 4076, 'Shrine of Soggoth', '', '', '', 3, '', 'go_soggoth_leave_coa', 12340)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
  `size` = VALUES(`size`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `gameobject` WHERE `guid` IN (9780916, 9780917);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`) VALUES
(9780916, 280144, 1, 148, 449, 1, 1, 4548.8184, 343.0483, 48.7305, 6.0221, 0, 0, 0.130197, -0.991488, 300, 100, 1),
(9780917, 978079, 883, 10238, 10238, 15, 1, 4405.5, 264.3, 78.02, 0, 0, 0, 0, 1, 300, 100, 1);

-- Players who die in his map rise at its start: WorldSafeLocs.dbc 6083 "Soggoth Graveyard".
DELETE FROM `game_graveyard` WHERE `ID` = 6083;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(6083, 883, 4410.54, 269.283, 78.0196, 'Soggoth Graveyard');
DELETE FROM `graveyard_zone` WHERE `ID` = 6083 AND `GhostZone` = 10238;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(6083, 10238, 0, 'Master''s Gastric Pit (The Will of Soggoth boss map)');

-- The shrine's words.
DELETE FROM `npc_text` WHERE `ID` = 978077;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`) VALUES
(978077, 'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.',
  'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.');

-- His hologram above the shrine: ghostly (22650), rooted, and frozen in place (16245).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
  `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `type_flags`, `AIName`, `ScriptName`,
  `VerifiedBuild`) VALUES
(978077, 'The Will of Soggoth', '', 63, 63, 35, 0, 1, 1, 1, 33554434, 10, 0, '', '', 12340)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `faction` = VALUES(`faction`),
  `npcflag` = VALUES(`npcflag`), `unit_flags` = VALUES(`unit_flags`), `type_flags` = VALUES(`type_flags`),
  `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 978077;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(978077, 0, 228465, 0.06, 1, 12340);
DELETE FROM `creature_template_addon` WHERE `entry` = 978077;
INSERT INTO `creature_template_addon` (`entry`, `auras`) VALUES (978077, '22650 16245');
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 978077;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(978077, 1, 0, 0, 1);
DELETE FROM `creature` WHERE `guid` = 9780918;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`) VALUES
(9780918, 978077, 1, 148, 449, 1, 1, 4548.8184, 343.0483, 53.7, 6.0221, 300, 0, 0);

-- The other world boss maps' graveyards (WorldSafeLocs.dbc 6084-6090), so players who die in any of them rise at
-- its start.
DELETE FROM `game_graveyard` WHERE `ID` BETWEEN 6084 AND 6090;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(6084, 884, -4751.12, 2466.51, -82.4105, 'Depthbreaker''s Hollow Boss map Graveyard'),
(6085, 885, 3270.86, -3730.45, 125.108, 'Bough Shadow Boss map Graveyard'),
(6086, 886, -2855.81, 1784.38, 29.9513, 'Dream Bough Boss map Graveyard'),
(6087, 887, 699.752, -4090.8, 100.715, 'Seradane Boss map Graveyard'),
(6088, 888, -10401.3, -377.872, 48.5314, 'Twilight Grove Boss map Graveyard'),
(6089, 889, 4741.1, -4934.99, 695.783, 'Frostgiantnbossmap Boss map Graveyard'),
(6090, 890, 3353.02, -4844.59, 167.439, 'Atalzulbossmap Boss map Graveyard');
DELETE FROM `graveyard_zone` WHERE `ID` BETWEEN 6084 AND 6090;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(6084, 10240, 0, 'Depthbreaker''s Hollow boss map'),
(6085, 10271, 0, 'Bough Shadow (Emeriss boss map)'),
(6086, 10272, 0, 'Dream Bough (Taerar boss map)'),
(6087, 10273, 0, 'Seradane (Ysondre boss map)'),
(6088, 10274, 0, 'Twilight Grove (Lethon boss map)'),
(6089, 10280, 0, 'Snowgrave''s Cavern (Korrim Snowgrave boss map)'),
(6090, 10281, 0, 'Zul''Mashar (Atal''zul boss map)');

-- The Treasures of Azeroth chest every world boss gives (1615011) has a 5% roll at any world boss item (978060):
-- his items join that pool.
INSERT IGNORE INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
  `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 978060, l.`Item`, 0, 0, 0, 1, 1, 1, 1, CONCAT('Treasures of Azeroth - World Boss - ', i.`name`)
FROM `creature_loot_template` l JOIN `item_template` i ON i.`entry` = l.`Item`
WHERE l.`Entry` = 64605 AND l.`GroupId` = 1 AND l.`Reference` = 0 AND i.`Quality` = 4;

-- World bosses give Ascension's own Treasures of Azeroth chest (1615011), which holds what 978059 holds;
-- 978059 keeps its loot for the chests players still hold.
DELETE FROM `item_loot_template` WHERE `Entry` = 1615011;
INSERT INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(1615011, 978059, 978059, 100, 0, 1, 0, 1, 1, 'Treasures of Azeroth - a Heroic Dungeon epic'),
(1615011, 978060, 978060, 5, 0, 1, 0, 1, 1, 'Treasures of Azeroth - 5% a world boss item'),
(1615011, 400750, 0, 100, 0, 1, 0, 15, 15, 'Treasures of Azeroth - 15 Raider''s Commendations'),
(1615011, 978061, 978061, 100, 0, 1, 0, 4, 4, 'Treasures of Azeroth - 1000 Runes of Descension (250 x 4)');
