-- Setis (64600): his loot, the altar by the Scarab Wall that takes players into his map (880), the portal back
-- he leaves when he dies, the graveyard at the start of his map, and the Prismatic Barrier school auras.

-- Loot: two of his nine items (two rolls of the same group). The level 68 items drop on the normal
-- difficulties (10 and 25 normal); their Heroic World Boss versions (level 71) are set up for the heroic ones.
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
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
  `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT `Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId` + 2, `MinCount`,
  `MaxCount`, CONCAT(`Comment`, ' (second item)')
FROM `creature_loot_template` WHERE `Entry` = 64600 AND `GroupId` IN (1, 2);

-- The altar by the Scarab Wall and the portal back.
DELETE FROM `gameobject_template` WHERE `entry` IN (64600, 64601);
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(64600, 10, 2490, 'Altar of Setis', '', '', '', 1, '', 'go_setis_altar_coa', 12340),
(64601, 10, 3931, 'Portal to the Scarab Wall', '', '', '', 1, '', 'go_setis_exit_coa', 12340);
DELETE FROM `gameobject` WHERE `guid` = 9780102;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`) VALUES
(9780102, 64600, 1, 0, 0, 1, 1, -7860.22, 1329.18, -7.52, 2.88, 0, 0, 0.9914, 0.1305, 300, 100, 1);

-- Players who die in his map rise at its start.
DELETE FROM `game_graveyard` WHERE `ID` = 6099;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(6099, 880, -8093.0, 1663.6, 12.9, 'Setis boss map - start');
DELETE FROM `graveyard_zone` WHERE `ID` = 6099;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(6099, 10235, 0, 'The Scarab Wall (Setis boss map)');

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_setis_prismatic_barrier_coa';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2119031, 'spell_setis_prismatic_barrier_coa'),
(2119032, 'spell_setis_prismatic_barrier_coa'),
(2119033, 'spell_setis_prismatic_barrier_coa'),
(2119034, 'spell_setis_prismatic_barrier_coa'),
(2119035, 'spell_setis_prismatic_barrier_coa'),
(2119036, 'spell_setis_prismatic_barrier_coa');
