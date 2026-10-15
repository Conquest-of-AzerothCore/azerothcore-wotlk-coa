-- Sardragar, the Dark Iron dwarf leading the troggs ("WARNING! KILL!"), where the user stood in game (.gps 2026-10-15).
DELETE FROM `creature` WHERE `guid` = 9965157;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(9965157, 164399, 0, 0, 0, 1, 1, 0, -6994.248, -61.875, 398.778, 4.1356, 300, 0, 0, 'Sardragar (placed in game)');
