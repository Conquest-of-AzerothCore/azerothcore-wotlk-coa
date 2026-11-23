-- Hookweed for the Wounded (175021): Hookweed grows as a plant along the Lake Landen shore, as on the realm at launch
-- (Redthedeer VOD 2026-07-13, wJ2j4NOgjRI 01:27:52, 'Hookweed' tooltip on the shore plant, then 1/6). The capture has
-- no spawn positions; the plants stand on dry, gentle ground within 2 yd of the water inside the quest area, scattered
-- at least 38 to 50 yd apart.
DELETE FROM `gameobject` WHERE `guid` BETWEEN 9935000 AND 9935006 AND `id` = 2300636;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`,
    `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`,
    `state`, `ScriptName`) VALUES
(9935000, 2300636, 0, 0, 0, 1, 1, -8142.0, 436.0, 116.282, 2.0347, 0, 0, 0.850718, 0.525622, 60, 100, 1, ''),
(9935001, 2300636, 0, 0, 0, 1, 1, -8240.0, 382.0, 115.794, 0.9478, 0, 0, 0.456360, 0.889795, 60, 100, 1, ''),
(9935002, 2300636, 0, 0, 0, 1, 1, -8310.0, 430.0, 117.386, 4.0899, 0, 0, 0.889679, -0.456586, 60, 100, 1, ''),
(9935003, 2300636, 0, 0, 0, 1, 1, -8118.0, 382.0, 115.865, 0.4551, 0, 0, 0.225591, 0.974222, 60, 100, 1, ''),
(9935004, 2300636, 0, 0, 0, 1, 1, -8184.0, 388.0, 115.917, 3.367, 0, 0, 0.993656, -0.112465, 60, 100, 1, ''),
(9935005, 2300636, 0, 0, 0, 1, 1, -8244.0, 440.0, 116.048, 2.2977, 0, 0, 0.912294, 0.409537, 60, 100, 1, ''),
(9935006, 2300636, 0, 0, 0, 1, 1, -8154.0, 324.0, 117.009, 0.3644, 0, 0, 0.181194, 0.983447, 60, 100, 1, '');

-- Shadewell Murloc Raiders keep a small chance to carry one.
UPDATE `creature_loot_template` SET `Chance` = 5, `MaxCount` = 1 WHERE `Entry` = 164023 AND `Item` = 559856;
