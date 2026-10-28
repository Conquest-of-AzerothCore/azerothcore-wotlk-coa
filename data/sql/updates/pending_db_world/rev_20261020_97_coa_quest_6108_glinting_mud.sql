-- Glinting Mud (154357, loot for Hilary's Necklace) gets the one extra spawn point that Ascension's client marks on
-- the minimap in https://www.youtube.com/watch?v=OFGQoZ4CzY8 (0:10-0:18, quest in the log). That video shows 11
-- spawn-point rings along the Lakeshire lake: guids 131-140 and one more at map 34.19, 53.45.
-- The x and y come from the minimap: each ring was tracked over 34 frames against the on-screen player coordinates,
-- with the Redridge WorldMapArea.dbc bounds (-1570/-3741, -8575/-10022). The ten known spawns were fitted to their
-- rings (0.278 px per yard, residual at most 2.0 yd). The new ring lies at -9348.5, -2312.2 (spread 0.6 yd), 2.1 yd
-- from pfQuest-tbc's (34.1, 53.4).
-- The z is the ADT terrain height in the server's maps/0004936.map at that x and y. That puts the mud on the lake
-- bed, 10.6 yd below the water at 56.16, like the other ten, whose z values match the same map data within 0.11 yd.
-- Orientation and rotation are copied from guid 135, the nearest pool member; spawntimesecs 2, animprogress 255 and
-- state 1 match all ten members. The pool stays at two active nodes: the video does not show more at once.
DELETE FROM `gameobject` WHERE `guid` = 8006108;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(8006108, 154357, 0, 0, 0, 1, 1, -9348.5, -2312.2, 45.539, 3.927, 0, 0, 0.923878, -0.382688, 2, 255, 1, '', NULL, 'Glinting Mud (Ascension spawn point, issue 6108)');
DELETE FROM `pool_gameobject` WHERE `guid` = 8006108;
INSERT INTO `pool_gameobject` (`guid`, `pool_entry`, `chance`, `description`) VALUES
(8006108, 138, 0, 'Glinting Mud');
UPDATE `pool_template` SET `description` = 'Glinting Mud - 2/11' WHERE `entry` = 138;
