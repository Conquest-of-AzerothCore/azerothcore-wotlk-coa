-- Stranglethorn Vale, Venture Co. Base (Lake Nazferiti mine): camp rework.
-- Tents, campfire, crates and static (non-mineable) gold veins, the existing Venture Co. NPCs repositioned
-- around them, and more miners/mechanics. Guids match the spawns already placed in-game on Rexxar.

-- 9000806 'Gold Vein': static (type 5 generic, no lock/loot) copy of 211032 'Gold Mine' at the size of
-- the mineable 181109 'Gold Vein' (0.5), for Venture Co. Miners to stand and mine at.
DELETE FROM `gameobject_template` WHERE `entry` = 9000806;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(9000806, 5, 311, 'Gold Vein', '', '', '', 0.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0);

-- 211032 'Gold Mine' (unspawned before this change): size 2 -> 1.5 for the larger veins in the camp.
UPDATE `gameobject_template` SET `size` = 1.5 WHERE `entry` = 211032;

-- Reposition the existing Venture Co. Miners (1094), Geologists (1096) and Mechanic (1097).
-- Geologists 728 and 1315 now stand by the tents and no longer wander.
UPDATE `creature` SET `position_x` = -11466.921875, `position_y` = 382.698944, `position_z` = 74.754494, `orientation` = 4.594915 WHERE `guid` = 393 AND `id` = 1094;
UPDATE `creature` SET `position_x` = -11463.008789, `position_y` = 376.818573, `position_z` = 75.692551, `orientation` = 3.020192 WHERE `guid` = 395 AND `id` = 1094;
UPDATE `creature` SET `position_x` = -11529.823242, `position_y` = 354.448975, `position_z` = 44.268181, `orientation` = 1.005616, `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 728 AND `id` = 1096;
UPDATE `creature` SET `position_x` = -11534.638672, `position_y` = 375.644989, `position_z` = 45.635517, `orientation` = 0.459811 WHERE `guid` = 1314 AND `id` = 1097;
UPDATE `creature` SET `position_x` = -11545.506836, `position_y` = 396.493225, `position_z` = 46.047916, `orientation` = 2.649535, `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 1315 AND `id` = 1096;
UPDATE `creature` SET `position_x` = -11497.851562, `position_y` = 374.319275, `position_z` = 55.525867, `orientation` = 1.962329 WHERE `guid` = 2128 AND `id` = 1094;
UPDATE `creature` SET `position_x` = -11517.196289, `position_y` = 400.192322, `position_z` = 46.636654, `orientation` = 1.771382 WHERE `guid` = 2130 AND `id` = 1094;
UPDATE `creature` SET `position_x` = -11502.416992, `position_y` = 377.273682, `position_z` = 53.761555, `orientation` = 0.173083 WHERE `guid` = 2131 AND `id` = 1094;
UPDATE `creature` SET `position_x` = -11469.875, `position_y` = 352.398407, `position_z` = 63.547501, `orientation` = 2.739872 WHERE `guid` = 2132 AND `id` = 1094;
UPDATE `creature` SET `position_x` = -11477.941406, `position_y` = 364.645081, `position_z` = 56.935703, `orientation` = 1.176928 WHERE `guid` = 2133 AND `id` = 1094;
UPDATE `creature` SET `position_x` = -11501.851562, `position_y` = 454.211884, `position_z` = 64.955795, `orientation` = 0.577586 WHERE `guid` = 2136 AND `id` = 1094;
UPDATE `creature` SET `position_x` = -11501.836914, `position_y` = 459.814484, `position_z` = 64.041428, `orientation` = 5.706235 WHERE `guid` = 2141 AND `id` = 1094;
UPDATE `creature` SET `position_x` = -11509.720703, `position_y` = 427.196503, `position_z` = 53.66584, `orientation` = 1.0174 WHERE `guid` = 2146 AND `id` = 1094;
UPDATE `creature` SET `position_x` = -11521.601562, `position_y` = 406.259277, `position_z` = 47.617077, `orientation` = 5.513812 WHERE `guid` = 2148 AND `id` = 1094;
UPDATE `creature` SET `position_x` = -11545.120117, `position_y` = 421.734161, `position_z` = 47.883755, `orientation` = 5.305726 WHERE `guid` = 2149 AND `id` = 1096;

-- New Venture Co. Miners (1094) and Mechanics (1097).
DELETE FROM `creature` WHERE `guid` IN (9999265, 9999268, 9999269, 9999270, 9999271, 9999273, 9999274, 9999275, 9999276, 9999277);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9999265, 1094, 0, 0, 0, 1, 1, 1, -11510.605469, 433.78717, 54.387619, 5.5845, 300, 0, 0, 2238, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999268, 1094, 0, 0, 0, 1, 1, 1, -11459.788086, 340.639954, 56.723316, 5.178533, 300, 0, 0, 2115, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999269, 1094, 0, 0, 0, 1, 1, 1, -11486.636719, 332.727539, 46.865547, 6.13279, 300, 0, 0, 2238, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999270, 1094, 0, 0, 0, 1, 1, 1, -11481.055664, 327.725372, 47.591408, 1.828808, 300, 0, 0, 2238, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999271, 1094, 0, 0, 0, 1, 1, 1, -11505.714844, 353.188873, 48.467384, 0.686053, 300, 0, 0, 2238, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999273, 1097, 0, 0, 0, 1, 1, 1, -11544.569336, 418.412659, 47.064949, 1.616751, 300, 0, 0, 2238, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999274, 1097, 0, 0, 0, 1, 1, 1, -11524.813477, 391.729614, 45.49868, 6.262366, 300, 0, 0, 2115, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999275, 1094, 0, 0, 0, 1, 1, 1, -11544.244141, 383.991302, 47.41127, 4.381336, 300, 0, 0, 2115, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999276, 1094, 0, 0, 0, 1, 1, 1, -11550.768555, 420.69281, 47.895546, 2.025138, 300, 0, 0, 2115, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999277, 1094, 0, 0, 0, 1, 1, 1, -11534.96875, 437.204071, 47.409771, 0.611418, 300, 0, 0, 2238, 0, 0, 0, 0, 0, '', NULL, 0, NULL);

-- Camp objects: tents, campfire, static (type 5) crates, gold veins.
DELETE FROM `gameobject` WHERE `guid` IN (9999521, 9999522, 9999523, 9999525, 9999526, 9999527, 9999528, 9999529, 9999554, 9999555, 9999556, 9999557, 9999558, 9999560, 9999561, 9999562, 9999565, 9999566, 9999567);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9999521, 188179, 0, 0, 0, 1, 1, -11536.330078, 375.571533, 45.900249, 0.416625, 0, 0, 0.206809, 0.978381, 300, 0, 1, '', NULL, NULL),
(9999522, 188183, 0, 0, 0, 1, 1, -11545.572266, 423.675385, 48.186207, 5.608102, 0, 0, 0.331168, -0.943572, 300, 0, 1, '', NULL, NULL),
(9999523, 1801, 0, 0, 0, 1, 1, -11522.166992, 391.666626, 45.151432, 5.337143, 0, 0, 0.455578, -0.890196, 300, 0, 1, '', NULL, NULL),
(9999525, 211032, 0, 0, 0, 1, 1, -11518.219727, 404.261292, 48.095787, 0.534424, 0, 0, 0.264044, 0.964511, 300, 0, 1, '', NULL, NULL),
(9999526, 211032, 0, 0, 0, 1, 1, -11507.439453, 431.184235, 54.599087, 0.338073, 0, 0, 0.168233, 0.985747, 300, 0, 1, '', NULL, NULL),
(9999527, 211032, 0, 0, 0, 1, 1, -11498.973633, 378.144867, 56.15432, 0.341998, 0, 0, 0.170167, 0.985415, 300, 0, 1, '', NULL, NULL),
(9999528, 211032, 0, 0, 0, 1, 1, -11468.71875, 376.960297, 75.396927, 3.707428, 0, 0, 0.960245, -0.279159, 300, 0, 1, '', NULL, NULL),
(9999529, 211032, 0, 0, 0, 1, 1, -11498.4375, 457.589569, 66.206604, 6.279603, 0, 0, 0.001791, -0.999998, 300, 0, 1, '', NULL, NULL),
(9999554, 9000806, 0, 0, 0, 1, 1, -11477.443359, 366.052917, 57.535889, 1.141586, 0, 0, 0.540299, 0.841473, 300, 0, 1, '', NULL, NULL),
(9999555, 9000806, 0, 0, 0, 1, 1, -11471.350586, 352.803528, 63.526417, 4.326377, 0, 0, 0.829607, -0.558347, 300, 0, 1, '', NULL, NULL),
(9999556, 9000806, 0, 0, 0, 1, 1, -11458.676758, 339.105225, 57.011177, 5.893245, 0, 0, 0.193737, -0.981053, 300, 0, 1, '', NULL, NULL),
(9999557, 211032, 0, 0, 0, 1, 1, -11482.147461, 332.182678, 47.499939, 1.455743, 0, 0, 0.665282, 0.746592, 300, 0, 1, '', NULL, NULL),
(9999558, 9000806, 0, 0, 0, 1, 1, -11504.570312, 354.166382, 49.670311, 0.917746, 0, 0, 0.442938, 0.896552, 300, 0, 1, '', NULL, NULL),
(9999560, 9000806, 0, 0, 0, 1, 1, -11544.742188, 382.407104, 47.360413, 4.349918, 0, 0, 0.822978, -0.568073, 300, 0, 1, '', NULL, NULL),
(9999561, 9000806, 0, 0, 0, 1, 1, -11551.822266, 422.749237, 48.213123, 1.581388, 0, 0, 0.710841, 0.703352, 300, 0, 1, '', NULL, NULL),
(9999562, 9000806, 0, 0, 0, 1, 1, -11533.423828, 438.362732, 48.020588, 0.733155, 0, 0, 0.358423, 0.933559, 300, 0, 1, '', NULL, NULL),
(9999565, 179972, 0, 0, 0, 1, 1, -11542.619141, 423.298279, 48.000904, 2.413896, 0, 0, 0.934534, 0.355873, 300, 0, 1, '', NULL, NULL),
(9999566, 188234, 0, 0, 0, 1, 1, -11537.938477, 378.986389, 46.595932, 4.086806, 0, 0, 0.890385, -0.455209, 300, 0, 1, '', NULL, NULL),
(9999567, 178305, 0, 0, 0, 1, 1, -11535.466797, 373.685608, 45.43401, 3.505611, 0, 0, 0.983482, -0.181006, 300, 0, 1, '', NULL, NULL);
