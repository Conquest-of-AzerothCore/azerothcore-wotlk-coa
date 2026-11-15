-- The Scadeald mailbox in Shadewell Town, placed by the user; position and facing from their in-game .gps.
DELETE FROM `gameobject` WHERE `guid` = 9999405;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9999405, 2310437, 0, 0, 0, 1, 1, -8112.675, -148.802, 332.207, 1.052937, 0, 0, 0.502483, 0.864587, 300, 0, 1, 'Pale Reach: Shadewell Town mailbox');
