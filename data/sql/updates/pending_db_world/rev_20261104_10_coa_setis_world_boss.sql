-- Setis (64600): his loot, the shrine by the Scarab Wall that takes players into his map (880), the portal back
-- he leaves when he dies, the graveyard and shrine at the start of his map, and his place and health.

-- Loot: one roll of his nine items here; boss_setis_coa rolls one more for every four players in his map. The
-- level 68 items drop on the normal difficulties; their Heroic World Boss versions (level 71), in loot mode 2,
-- only on the heroic ones. The Idol of the Old Gods always drops, and the recipe at 1%, as on Ascension.
-- His kills count for 14471, the Setis of quest 170010 "A Threat to Azeroth: Setis".
UPDATE `creature_template` SET `lootid` = 64600, `subname` = 'The Gate Warden', `KillCredit1` = 14471
WHERE `entry` = 64600;
DELETE FROM `creature_loot_template` WHERE `Entry` = 64600;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(64600, 17365, 0, 0, 0, 1, 1, 1, 1, 'Setis - Amulet of the Gate Warden'),
(64600, 17366, 0, 0, 0, 1, 1, 1, 1, 'Setis - Amulet of the Sand Prince'),
(64600, 17358, 0, 0, 0, 1, 1, 1, 1, 'Setis - Belt of the Sand Prince'),
(64600, 17357, 0, 0, 0, 1, 1, 1, 1, 'Setis - Bracers of the Sand Prince'),
(64600, 17367, 0, 0, 0, 1, 1, 1, 1, 'Setis - Insignia of the Shifting Sands'),
(64600, 17243, 0, 0, 0, 1, 1, 1, 1, 'Setis - Scepter of the Gate Warden'),
(64600, 17244, 0, 0, 0, 1, 1, 1, 1, 'Setis - Staff of the Gate Warden'),
(64600, 17356, 0, 0, 0, 1, 1, 1, 1, 'Setis - Waistguard of the Shifting Sands'),
(64600, 17334, 0, 0, 0, 1, 1, 1, 1, 'Setis - Wristguards of the Shifting Sands'),
(64600, 317365, 0, 0, 0, 2, 2, 1, 1, 'Setis (heroic) - Amulet of the Gate Warden'),
(64600, 317366, 0, 0, 0, 2, 2, 1, 1, 'Setis (heroic) - Amulet of the Sand Prince'),
(64600, 317358, 0, 0, 0, 2, 2, 1, 1, 'Setis (heroic) - Belt of the Sand Prince'),
(64600, 317357, 0, 0, 0, 2, 2, 1, 1, 'Setis (heroic) - Bracers of the Sand Prince'),
(64600, 317367, 0, 0, 0, 2, 2, 1, 1, 'Setis (heroic) - Insignia of the Shifting Sands'),
(64600, 317243, 0, 0, 0, 2, 2, 1, 1, 'Setis (heroic) - Scepter of the Gate Warden'),
(64600, 317244, 0, 0, 0, 2, 2, 1, 1, 'Setis (heroic) - Staff of the Gate Warden'),
(64600, 317356, 0, 0, 0, 2, 2, 1, 1, 'Setis (heroic) - Waistguard of the Shifting Sands'),
(64600, 317334, 0, 0, 0, 2, 2, 1, 1, 'Setis (heroic) - Wristguards of the Shifting Sands'),
(64600, 1005032, 0, 100, 0, 3, 0, 1, 1, 'Setis - Idol of the Old Gods'),
(64600, 6001, 0, 1, 0, 3, 0, 1, 1, 'Setis - Recipe: Potion of Lightning Reflexes');

-- The shrine by the Scarab Wall (Ascension's 380138, with its ritual altar model) and the portal back.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(380138, 10, 4076, 'Shrine of Setis', '', '', '', 3, '', 'go_setis_altar_coa', 12340),
(64601, 10, 4396, 'Portal to the Scarab Wall', '', '', '', 1.5, '', 'go_setis_exit_coa', 12340),
(64604, 10, 4076, 'Shrine of Setis', '', '', '', 3, '', 'go_setis_leave_coa', 12340)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
  `size` = VALUES(`size`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `gameobject` WHERE `guid` IN (9780102, 9780900);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`) VALUES
(9780102, 380138, 1, 0, 0, 1, 1, -7864.724, 1326.674, -7.357, 5.4786, 0, 0, 0.3915, -0.9202, 300, 100, 1),
(9780900, 64604, 880, 0, 0, 15, 1, -8098.0, 1668.0, 12.9, 0, 0, 0, 0, 1, 300, 100, 1);

-- Players who die in his map rise at its start: WorldSafeLocs.dbc 6080 "Setis Graveyard".
DELETE FROM `game_graveyard` WHERE `ID` = 6080;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(6080, 880, -8092.98, 1663.63, 12.94, 'Setis Graveyard');
DELETE FROM `graveyard_zone` WHERE `ID` = 6080 AND `GhostZone` = 10235;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(6080, 10235, 0, 'The Scarab Wall (Setis boss map)');

-- Setis stands at the end of the Scarab Wall road, facing the raid as it comes in.
UPDATE `creature` SET `position_x` = -8102.93, `position_y` = 1524.98, `position_z` = 2.65, `orientation` = 6.1819
WHERE `guid` = 9780101 AND `id` = 64600;

-- His health is per player in his map (10 to 40): 470000 on normal, the lower bound of the live kills.
UPDATE `coa_world_boss_level` SET `health` = 470000, `note` = 'per player; the lower bound of the live kills'
WHERE `entry` = 64600 AND `difficulty` = 0;
UPDATE `coa_world_boss_level` SET `health` = 872790, `note` = 'per player; the normal one times the log ratio 1.857'
WHERE `entry` = 64600 AND `difficulty` = 2;

-- The shrine's words.
DELETE FROM `npc_text` WHERE `ID` = 64600;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`) VALUES
(64600, 'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.',
  'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.');

-- Setis' hologram above the shrine: ghostly (22650), rooted, and frozen in place (16245).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
  `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `type_flags`, `AIName`, `ScriptName`,
  `VerifiedBuild`) VALUES
(978062, 'Setis', 'The Gate Warden', 63, 63, 35, 0, 1, 1, 1, 33554434, 7, 0, '', '', 12340)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `faction` = VALUES(`faction`),
  `npcflag` = VALUES(`npcflag`), `unit_flags` = VALUES(`unit_flags`), `type_flags` = VALUES(`type_flags`),
  `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 978062;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(978062, 0, 5965, 0.6, 1, 12340);
DELETE FROM `creature_template_addon` WHERE `entry` = 978062;
INSERT INTO `creature_template_addon` (`entry`, `auras`) VALUES (978062, '22650 16245');
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 978062;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(978062, 1, 0, 0, 1);
DELETE FROM `creature` WHERE `guid` IN (9780900, 9780901);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`) VALUES
(9780900, 978062, 1, 0, 0, 1, 1, -7864.724, 1326.674, -2.0, 5.4786, 300, 0, 0);

-- Treasures of Azeroth, one per player of a world boss kill: a Heroic Dungeon epic, a 5% chance at a world boss
-- item of the normal loot modes, 1000 Runes of Descension (a 250 stack taken four times, as one loot row holds
-- 255 at most) and 15 Raider's Commendations.
DELETE FROM `reference_loot_template` WHERE `Entry` IN (978059, 978060, 978061);
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
  `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(978061, 375250, 0, 100, 0, 1, 0, 250, 250, 'Treasures of Azeroth - 250 Runes of Descension');
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
  `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 978059, `entry`, 0, 0, 0, 1, 1, 1, 1, CONCAT('Treasures of Azeroth - Heroic Dungeon - ', `name`)
FROM `item_template` WHERE `description` = '@Heroic Dungeon@' AND `Quality` = 4 AND `InventoryType` > 0;
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
  `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT DISTINCT 978060, i.`entry`, 0, 0, 0, 1, 1, 1, 1, CONCAT('Treasures of Azeroth - World Boss - ', i.`name`)
FROM (SELECT l.`Item` FROM `creature_loot_template` l
      WHERE l.`Entry` IN (6109, 12397, 14887, 14888, 14889, 14890, 64600) AND l.`Reference` = 0
        AND l.`LootMode` & 1
      UNION SELECT r.`Item` FROM `creature_loot_template` l
      JOIN `reference_loot_template` r ON r.`Entry` = l.`Reference`
      WHERE l.`Entry` IN (6109, 12397, 14887, 14888, 14889, 14890, 64600) AND l.`Reference` <> 0
        AND l.`LootMode` & 1 AND r.`LootMode` & 1) x
JOIN `item_template` i ON i.`entry` = x.`Item`
WHERE i.`Quality` = 4 AND i.`InventoryType` > 0;
-- A 250 stack of runes must fit one loot slot.
UPDATE `item_template` SET `stackable` = 250 WHERE `entry` = 375250 AND `stackable` BETWEEN 0 AND 249;
DELETE FROM `item_loot_template` WHERE `Entry` = 978059;
INSERT INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(978059, 978059, 978059, 100, 0, 1, 0, 1, 1, 'Treasures of Azeroth - a Heroic Dungeon epic'),
(978059, 978060, 978060, 5, 0, 1, 0, 1, 1, 'Treasures of Azeroth - 5% a world boss item'),
(978059, 400750, 0, 100, 0, 1, 0, 15, 15, 'Treasures of Azeroth - 15 Raider''s Commendations'),
(978059, 978061, 978061, 100, 0, 1, 0, 4, 4, 'Treasures of Azeroth - 1000 Runes of Descension (250 x 4)');
