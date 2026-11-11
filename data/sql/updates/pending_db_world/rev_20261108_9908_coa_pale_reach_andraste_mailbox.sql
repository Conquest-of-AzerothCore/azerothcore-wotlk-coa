-- The Scadeald mailbox at Andraste's Fortress, by the inn, placed by the user; position and facing from their in-game
-- .gps.
DELETE FROM `gameobject` WHERE `guid` = 9999406;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9999406, 2310437, 0, 0, 0, 1, 1, -7485.649, -319.495, 360.863, 3.782889, 0, 0, 0.949031, -0.315182, 300, 0, 1, 'Pale Reach: Andraste''s Fortress mailbox');
