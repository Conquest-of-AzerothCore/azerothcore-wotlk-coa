-- Each watchtower fire is two objects on one spot, as on live (user): the stock Campfire (1798) ring and, in its middle, the
-- clickable Cozy Fire, which takes the stock bonfire model.
UPDATE `gameobject_template` SET `displayId` = 200 WHERE `entry` = 2300668;
DELETE FROM `gameobject` WHERE `guid` BETWEEN 9963443 AND 9963445;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9963443, 1798, 0, 0, 0, 1, 1, -6994.1226, 501.18402, 350.3942, 6.179972, 0, 0, 0.051584, -0.998669, 300, 100, 1, 'Campfire under a Cozy Fire, Snowsong Valley watchtower'),
(9963444, 1798, 0, 0, 0, 1, 1, -7000.3325, 507.7701, 350.39496, 1.70949, 0, 0, 0.754404, 0.656411, 300, 100, 1, 'Campfire under a Cozy Fire, Snowsong Valley watchtower'),
(9963445, 1798, 0, 0, 0, 1, 1, -7009.268, 505.57397, 350.39496, 3.0705857, 0, 0, 0.99937, 0.035496, 300, 100, 1, 'Campfire under a Cozy Fire, Snowsong Valley watchtower');
