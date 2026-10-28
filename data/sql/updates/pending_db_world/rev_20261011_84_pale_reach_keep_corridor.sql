-- Lower keep doorway guards and Lyrielle's corridor walk: 0MqPfOJqF8w at 06:45-06:48.
DELETE FROM `creature` WHERE `guid` IN (9999201, 9999202);
INSERT INTO `creature` (
    `guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
    `position_x`, `position_y`, `position_z`, `orientation`,
    `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`
) VALUES
(9999201, 1756, 0, 1519, 10275, 1, 1, 1, -8280.54, 283.748, 126.833, 5.3847,
    300, 0, 0, 'Pale Reach intro: lower keep doorway guard, reconstructed from 0MqPfOJqF8w'),
(9999202, 1756, 0, 1519, 10275, 1, 1, 1, -8274.44, 288.748, 126.833, 5.3847,
    300, 0, 0, 'Pale Reach intro: lower keep doorway guard, reconstructed from 0MqPfOJqF8w');

UPDATE `creature` SET `MovementType` = 2, `wander_distance` = 0, `currentwaypoint` = 0
WHERE `guid` = 9960208 AND `id` = 164103;

DELETE FROM `creature_addon` WHERE `guid` = 9960208;
INSERT INTO `creature_addon` (`guid`, `path_id`, `bytes1`, `bytes2`, `emote`, `auras`)
VALUES (9960208, 99602080, 0, 1, 0, '');

DELETE FROM `waypoint_data` WHERE `id` = 99602080;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `move_type`)
VALUES
(99602080, 1, -8280.8, 294.8, 126.932, 0),
(99602080, 2, -8295.6, 313.4, 126.932, 0);
