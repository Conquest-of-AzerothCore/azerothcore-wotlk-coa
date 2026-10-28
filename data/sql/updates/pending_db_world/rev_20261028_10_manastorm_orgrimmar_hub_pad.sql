DELETE FROM `gameobject` WHERE `guid` = 6901539;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(6901539, 20832, 1, 0, 0, 1, 1, 1648.1, -4431.11, 16.9532, 2.18527, 0, 0, 0.887843, 0.460146, 300, 0, 1, '', NULL, NULL);

DELETE FROM `manastorm_hub_return` WHERE `team_id` = 1;
INSERT INTO `manastorm_hub_return` (`team_id`, `gameobject_guid`, `z_offset`) VALUES
(1, 6901539, 1);
