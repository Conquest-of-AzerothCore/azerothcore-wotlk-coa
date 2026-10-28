CREATE TABLE IF NOT EXISTS `ascension_void_portal_group` (
  `groupId` int unsigned NOT NULL,
  `comment` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`groupId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `gameobject_template`
(`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`,
 `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`,
 `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`,
 `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(239828, 10, 138016, 'Void Portal', 'Pickup', '', '', 1.0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 61003, 0,
 0, 0, 0, '', 'go_void_portal', NULL)
ON DUPLICATE KEY UPDATE
 `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
 `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `unk1` = VALUES(`unk1`),
 `size` = VALUES(`size`),
 `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`),
 `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`),
 `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`),
 `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`),
 `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`),
 `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`),
 `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`),
 `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`),
 `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`),
 `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `creature` WHERE `guid` BETWEEN 8001308 AND 8001327;
INSERT INTO `creature`
(`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`,
 `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`,
 `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`) VALUES
(8001308, 23746, 0, 139, 0, 1, 1, 3460.597656, -4946.015625, 182.513626, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001309, 23746, 0, 139, 0, 1, 1, 2858.920898, -2883.853516, 97.198929, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001310, 23746, 0, 139, 0, 1, 1, 1360.456055, -3172.931641, 120.511841, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001311, 23746, 0, 139, 0, 1, 1, 2515.266602, -4085.935547, 73.702888, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001312, 23746, 0, 139, 0, 1, 1, 1724.883789, -5635.669922, 100.934669, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001313, 23746, 0, 11, 0, 1, 1, -3827.748047, -1324.343750, 25.797464, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001314, 23746, 0, 11, 0, 1, 1, -2477.062500, -1808.867188, 10.223799, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001315, 23746, 0, 11, 0, 1, 1, -2859.833984, -2951.750000, 33.704609, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001316, 23746, 0, 41, 0, 1, 1, -11216.916016, -2019.095703, 47.164402, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001317, 23746, 0, 41, 0, 1, 1, -10776.353516, -2190.767578, 117.356544, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001318, 23746, 1, 490, 0, 1, 1, -6695.734375, -430.988281, -255.372452, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001319, 23746, 1, 490, 0, 1, 1, -7665.640625, -1489.726562, -268.301636, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001320, 23746, 1, 490, 0, 1, 1, -8070.984375, -1267.003906, -329.709137, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001321, 23746, 1, 490, 0, 1, 1, -7665.892578, -1996.138672, -271.626495, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001322, 23746, 1, 490, 0, 1, 1, -6463.984375, -2137.658203, -255.302307, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001323, 23746, 1, 406, 0, 1, 1, 2307.876953, 1539.663086, 286.949463, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001324, 23746, 1, 406, 0, 1, 1, 1716.447266, 705.009766, 155.224609, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001325, 23746, 1, 406, 0, 1, 1, 1297.418945, -603.339844, 28.397209, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001326, 23746, 1, 16, 0, 1, 1, 2307.497070, -5962.173828, 118.548775, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, ''),
(8001327, 23746, 1, 16, 0, 1, 1, 4201.229492, -7831.912109, 12.709650, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '');

DELETE FROM `spawn_group` WHERE `groupId` IN (9000001, 9000002, 9000003, 9000004);
INSERT INTO `spawn_group` (`groupId`, `spawnType`, `spawnId`) VALUES
(9000001, 0, 8001308),
(9000001, 0, 8001309),
(9000001, 0, 8001310),
(9000001, 0, 8001311),
(9000001, 0, 8001312),
(9000002, 0, 8001313),
(9000002, 0, 8001314),
(9000002, 0, 8001315),
(9000002, 0, 8001316),
(9000002, 0, 8001317),
(9000003, 0, 8001318),
(9000003, 0, 8001319),
(9000003, 0, 8001320),
(9000003, 0, 8001321),
(9000003, 0, 8001322),
(9000004, 0, 8001323),
(9000004, 0, 8001324),
(9000004, 0, 8001325),
(9000004, 0, 8001326),
(9000004, 0, 8001327);

DELETE FROM `spawn_group_template` WHERE `groupId` IN (9000001, 9000002, 9000003, 9000004);
INSERT INTO `spawn_group_template` (`groupId`, `groupName`, `groupFlags`) VALUES
(9000001, 'Void Portal - Eastern Plaguelands', 4),
(9000002, 'Void Portal - Wetlands and Deadwind Pass', 4),
(9000003, 'Void Portal - Un''Goro Crater', 4),
(9000004, 'Void Portal - Azshara and Stonetalon Mountains', 4);

DELETE FROM `ascension_void_portal_group` WHERE `groupId` IN (9000001, 9000002, 9000003, 9000004);
INSERT INTO `ascension_void_portal_group` (`groupId`, `comment`) VALUES
(9000001, 'Eastern Plaguelands'),
(9000002, 'Wetlands and Deadwind Pass'),
(9000003, 'Un''Goro Crater'),
(9000004, 'Azshara and Stonetalon Mountains');
