-- The Scadeald mailbox in Dunshire, confirmed by the user in live footage; position and facing from the user's in-game
-- .gps.
DELETE FROM `gameobject` WHERE `guid` = 9999401;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9999401, 2310437, 0, 0, 0, 1, 1, -7782.271, 591.526, 136.780, 4.125539, 0, 0, 0.881402, -0.472366, 300, 0, 1, 'Pale Reach: Dunshire mailbox');
