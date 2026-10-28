-- A Tin Vein the user placed near Dun Kazad, where there is no tin nearby.
DELETE FROM `gameobject` WHERE `guid` = 9963066;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9963066, 1732, 0, 0, 0, 1, 1, -6674.8, -535.214, 595.119, 5.62712, 0, 0, 0.322181, -0.946678, 300, 0, 1, '', NULL, 'Tin Vein (placed in game)');
