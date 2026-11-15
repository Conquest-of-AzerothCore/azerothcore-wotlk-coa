-- The Scadeald mailbox left of the Cresthairn inn door (NIs_cJRD9YE at 0:34-0:36); position and facing from the
-- user's in-game .gps.
DELETE FROM `gameobject` WHERE `guid` = 9999400;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9999400, 2310437, 0, 0, 0, 1, 1, -7622.108, 1204.528, 159.920, 3.249124, 0, 0, 0.998555, -0.05374, 300, 0, 1, 'Pale Reach: Cresthairn mailbox by the inn door');
