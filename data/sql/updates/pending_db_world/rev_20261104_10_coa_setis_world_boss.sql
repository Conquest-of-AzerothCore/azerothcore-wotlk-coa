-- Setis (64600): his loot, the shrine by the Scarab Wall that takes players into his map (880), the portal back
-- he leaves when he dies, the graveyard and shrine at the start of his map, and his place and health.

-- Loot: one roll of his nine items here; boss_setis_coa rolls one more for every four players in his map. The
-- level 68 items drop on the normal difficulties; their Heroic World Boss versions (level 71), in loot mode 2,
-- only on the heroic ones.
UPDATE `creature_template` SET `lootid` = 64600 WHERE `entry` = 64600;
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
(64600, 317334, 0, 0, 0, 2, 2, 1, 1, 'Setis (heroic) - Wristguards of the Shifting Sands');

-- The altar by the Scarab Wall and the portal back.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(64600, 10, 2490, 'Shrine of Setis', '', '', '', 2, '', 'go_setis_altar_coa', 12340),
(64601, 10, 4396, 'Portal to the Scarab Wall', '', '', '', 1.5, '', 'go_setis_exit_coa', 12340),
(64604, 10, 2490, 'Shrine of Setis', '', '', '', 2, '', 'go_setis_leave_coa', 12340)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
  `size` = VALUES(`size`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `gameobject` WHERE `guid` IN (9780102, 9780900);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`) VALUES
(9780102, 64600, 1, 0, 0, 1, 1, -7864.724, 1326.674, -7.357, 5.4786, 0, 0, 0.3915, -0.9202, 300, 100, 1),
(9780900, 64604, 880, 0, 0, 15, 1, -8098.0, 1668.0, 12.9, 0, 0, 0, 0, 1, 300, 100, 1);

-- Players who die in his map rise at its start.
DELETE FROM `game_graveyard` WHERE `ID` = 6099;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(6099, 880, -8093.0, 1663.6, 12.9, 'Setis boss map - start');
DELETE FROM `graveyard_zone` WHERE `ID` = 6099;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(6099, 10235, 0, 'The Scarab Wall (Setis boss map)');

-- Setis stands at the end of the Scarab Wall road, facing the raid as it comes in.
UPDATE `creature` SET `position_x` = -8102.93, `position_y` = 1524.98, `position_z` = 2.65, `orientation` = 6.1819
WHERE `guid` = 9780101 AND `id` = 64600;

-- His health is per player in his map (10 to 40): 975000 on normal, 39 million for 40 players.
UPDATE `coa_world_boss_level` SET `health` = 975000, `note` = 'per player; 39 million for 40 players'
WHERE `entry` = 64600 AND `difficulty` = 0;
UPDATE `coa_world_boss_level` SET `health` = 1810000, `note` = 'per player; the normal one times the log ratio'
WHERE `entry` = 64600 AND `difficulty` = 2;

-- The shrine's words.
DELETE FROM `npc_text` WHERE `ID` = 64600;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`) VALUES
(64600, 'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.',
  'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.');

-- Setis' hologram above the shrine; it stands still.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
  `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `type_flags`, `AIName`, `ScriptName`,
  `VerifiedBuild`) VALUES
(64602, 'Setis', 'the Gate Watcher', 63, 63, 35, 0, 1, 1, 1, 33554434, 7, 0, '', '', 12340)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `faction` = VALUES(`faction`),
  `npcflag` = VALUES(`npcflag`), `unit_flags` = VALUES(`unit_flags`), `type_flags` = VALUES(`type_flags`),
  `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 64602;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(64602, 0, 5965, 0.6, 1, 12340);
DELETE FROM `creature_template_addon` WHERE `entry` = 64602;
INSERT INTO `creature_template_addon` (`entry`, `auras`) VALUES (64602, '22650');
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 64602;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(64602, 1, 0, 0, 1);
DELETE FROM `creature` WHERE `guid` IN (9780900, 9780901);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`) VALUES
(9780900, 64602, 1, 0, 0, 1, 1, -7864.724, 1326.674, -4.6, 5.4786, 300, 0, 0);
