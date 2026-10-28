UPDATE `creature`
SET `position_x` = -7788.8, `position_y` = 791.9, `position_z` = 150.653,
    `orientation` = 5.411, `MovementType` = 0, `wander_distance` = 0
WHERE `guid` = 9920339 AND `id` = 164027;

UPDATE `creature`
SET `position_x` = -7811, `position_y` = 792.5, `position_z` = 150.644,
    `orientation` = 0.464, `MovementType` = 2, `wander_distance` = 0
WHERE `guid` = 9920346 AND `id` = 164027;

UPDATE `creature`
SET `position_x` = -7771, `position_y` = 784, `position_z` = 149.966,
    `orientation` = 5.64, `MovementType` = 2, `wander_distance` = 0
WHERE `guid` = 9920347 AND `id` = 164027;

UPDATE `creature`
SET `position_x` = -7768, `position_y` = 787, `position_z` = 150.332,
    `orientation` = 2.977, `MovementType` = 0, `wander_distance` = 0
WHERE `guid` = 9960868 AND `id` = 164027;

UPDATE `creature`
SET `position_x` = -7795, `position_y` = 806, `position_z` = 148.995,
    `orientation` = 5.331, `MovementType` = 0, `wander_distance` = 0
WHERE `guid` = 9960869 AND `id` = 164027;

UPDATE `creature`
SET `position_x` = -7811, `position_y` = 796.5, `position_z` = 150.644,
    `orientation` = 3.283, `MovementType` = 0, `wander_distance` = 0
WHERE `guid` = 9960870 AND `id` = 164027;

UPDATE `creature`
SET `orientation` = 5.492, `MovementType` = 0, `wander_distance` = 0
WHERE `guid` = 9960878 AND `id` = 164027;

UPDATE `creature`
SET `orientation` = 0.7, `MovementType` = 0, `wander_distance` = 0
WHERE `guid` = 9920338 AND `id` = 164058;

DELETE FROM `creature_addon`
WHERE `guid` IN (9920339, 9920346, 9920347, 9960868, 9960869, 9960870, 9960878, 9920338);
INSERT INTO `creature_addon` (`guid`, `path_id`, `bytes1`, `bytes2`, `emote`, `auras`)
VALUES
(9920339, 0, 0, 1, 0, ''),
(9920346, 99203460, 0, 1, 0, ''),
(9920347, 99203470, 0, 1, 0, ''),
(9960868, 0, 0, 1, 0, ''),
(9960869, 0, 0, 0, 28, ''),
(9960870, 0, 0, 0, 68, ''),
(9960878, 0, 0, 0, 68, ''),
(9920338, 0, 0, 1, 0, '');

DELETE FROM `waypoint_data` WHERE `id` IN (99203460, 99203470);
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`,
    `move_type`, `action`, `action_chance`)
VALUES
(99203460, 1, -7811, 792.5, 150.644, 0.464, 3000, 0, 0, 100),
(99203460, 2, -7808, 794, 150.644, 0, 0, 0, 0, 100),
(99203460, 3, -7804, 794, 150.644, 5.64, 4000, 0, 0, 100),
(99203460, 4, -7800, 791, 150.644, 0, 0, 0, 0, 100),
(99203460, 5, -7799, 788, 150.644, 0, 0, 0, 0, 100),
(99203460, 6, -7801, 787, 150.644, 3.142, 5000, 0, 0, 100),
(99203460, 7, -7801, 791, 150.644, 0, 0, 0, 0, 100),
(99203460, 8, -7805, 792, 150.644, 0, 0, 0, 0, 100),
(99203460, 9, -7808, 792, 150.644, 0, 0, 0, 0, 100),
(99203470, 1, -7771, 784, 149.966, 3.0, 6000, 0, 0, 100),
(99203470, 2, -7767, 781, 150.273, 0, 0, 0, 0, 100),
(99203470, 3, -7765, 775, 150.677, 0, 0, 0, 0, 100),
(99203470, 4, -7766, 772, 150.724, 5.5, 5000, 0, 0, 100),
(99203470, 5, -7770, 777, 150.416, 0, 0, 0, 0, 100);
