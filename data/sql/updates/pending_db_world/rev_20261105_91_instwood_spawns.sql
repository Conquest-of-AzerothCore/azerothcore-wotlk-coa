DELETE FROM `gameobject` WHERE `guid` BETWEEN 9998500 AND 9998507 AND `id` = 2300328 AND DATABASE() = 'coa_world';
INSERT IGNORE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`)
SELECT `s`.* FROM (VALUES
ROW(9998500, 2300328, 1199, 0, 0, 1, 1, 2903.91, -474.912, 106.802, 3.31823, 0, 0, 0.996102, -0.0882055, 300, 0, 1, '', NULL),
ROW(9998501, 2300328, 1199, 0, 0, 1, 1, 2903.59, -473.134, 106.802, 3.31823, 0, 0, 0.996102, -0.0882055, 300, 0, 1, '', NULL),
ROW(9998502, 2300328, 1199, 0, 0, 1, 1, 2903.3, -471.501, 106.802, 3.31823, 0, 0, 0.996102, -0.0882055, 300, 0, 1, '', NULL),
ROW(9998503, 2300328, 1199, 0, 0, 1, 1, 2903.03, -469.969, 106.802, 3.31823, 0, 0, 0.996102, -0.0882055, 300, 0, 1, '', NULL),
ROW(9998504, 2300328, 1199, 0, 0, 1, 1, 2901.25, -452.392, 98.4267, 3.31823, 0, 0, 0.996103, -0.0882031, 300, 0, 1, '', NULL),
ROW(9998505, 2300328, 1199, 0, 0, 1, 1, 2901.07, -450.643, 98.4267, 3.31823, 0, 0, 0.996103, -0.0882031, 300, 0, 1, '', NULL),
ROW(9998506, 2300328, 1199, 0, 0, 1, 1, 2900.83, -448.898, 98.4267, 3.31823, 0, 0, 0.996103, -0.0882031, 300, 0, 1, '', NULL),
ROW(9998507, 2300328, 1199, 0, 0, 1, 1, 2900.47, -446.858, 98.4267, 3.31823, 0, 0, 0.996103, -0.0882031, 300, 0, 1, '', NULL)
) AS `s` WHERE DATABASE() = 'coa_world';

DELETE FROM `creature` WHERE (`guid`, `id`) IN ((9999833, 9990500), (9999834, 9990400), (9999835, 9990300), (9999836, 9990320), (9999837, 9990340), (9999838, 9990200), (9999839, 9990220), (9999840, 9780012)) AND DATABASE() = 'coa_world';
INSERT IGNORE INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`)
SELECT `s`.* FROM (VALUES
ROW(9999833, 9990500, 1199, 0, 0, 1, 1, 0, 2917.27, -454.477, 98.4266, 2.30503, 300, 0, 0, 9300, 0, 0, 0, 0, 0, '', NULL, 0),
ROW(9999834, 9990400, 1199, 0, 0, 1, 1, 0, 2941.33, -459.038, 99.6591, 3.31818, 300, 0, 0, 9300, 0, 0, 0, 0, 0, '', NULL, 0),
ROW(9999835, 9990300, 1199, 0, 0, 1, 1, 0, 2912.76, -476.299, 97.9939, 1.71597, 300, 0, 0, 9300, 0, 0, 0, 0, 0, '', NULL, 0),
ROW(9999836, 9990320, 1199, 0, 0, 1, 1, 0, 2908, -472.286, 97.9939, 0.172662, 300, 0, 0, 9300, 0, 0, 0, 0, 0, '', NULL, 0),
ROW(9999837, 9990340, 1199, 0, 0, 1, 1, 0, 2910.91, -468.15, 97.9939, 4.89293, 300, 0, 0, 9300, 0, 0, 0, 0, 0, '', NULL, 0),
ROW(9999838, 9990200, 1199, 0, 0, 1, 1, 0, 2936.92, -441.147, 107.366, 4.92039, 300, 0, 0, 9300, 0, 0, 0, 0, 0, '', NULL, 0),
ROW(9999839, 9990220, 1199, 0, 0, 1, 1, 0, 2917.61, -470.22, 106.926, 0.211941, 300, 0, 0, 9300, 0, 0, 0, 0, 0, '', NULL, 0),
ROW(9999840, 9780012, 1199, 0, 0, 1, 1, 0, 2938.05, -471.61, 99.6593, 1.77887, 300, 0, 0, 46254, 0, 0, 0, 0, 0, '', NULL, 0)
) AS `s` WHERE DATABASE() = 'coa_world';

DELETE FROM `game_tele` WHERE `id` = 19646 AND `name` = 'gear' AND DATABASE() = 'coa_world';
INSERT IGNORE INTO `game_tele` (`id`, `position_x`, `position_y`, `position_z`, `orientation`, `map`, `name`)
SELECT `s`.* FROM (VALUES
ROW(19646, 2908.36, -447.541, 98.4266, 6.15742, 1199, 'gear')
) AS `s` WHERE DATABASE() = 'coa_world';
