-- Graysky Royal Guards (164222) carry their swords sheathed (sheath state 0), as the user set: a template addon covers
-- the spawns without their own addon row, and the patrolling spawns' rows drop their drawn-weapon state. Any addon row
-- keeps the default "weapons ready" sheath from being applied, so bytes2 0 leaves them sheathed.
DELETE FROM `creature_template_addon` WHERE `entry` = 164222;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
    `auras`) VALUES
(164222, 0, 0, 0, 0, 0, 0, '');
UPDATE `creature_addon` SET `bytes2` = 0 WHERE `guid` IN (9920766, 9920767, 9960264, 9960836);

-- The Graysky Royal Guard in Coldmere Keep, spawn 9960234, walks a loop through the keep that the user laid out in game:
-- from the upper hall down the stairs to the lower floor and back up, about 200 yards in 85 seconds with a 5-second
-- stop at the start. Every node lies on the keep's floor. He wandered in place before.
UPDATE `creature` SET `position_x` = -7233.632, `position_y` = 1257.112, `position_z` = 337.985, `orientation` = 1.9022,
    `MovementType` = 2, `wander_distance` = 0 WHERE `guid` = 9960234 AND `id` = 164222;
DELETE FROM `creature_addon` WHERE `guid` = 9960234;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
    `auras`) VALUES
(9960234, 99602340, 0, 0, 0, 0, 0, '');
DELETE FROM `waypoint_data` WHERE `id` = 99602340;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`,
    `smoothTransition`, `move_type`) VALUES
(99602340, 1, -7233.632, 1257.112, 337.985, 1.9022, 5000, 0, 0),
(99602340, 2, -7225.209, 1233.594, 337.985, 5.0673, 0, 0, 0),
(99602340, 3, -7222.324, 1225.809, 333.688, 5.0673, 0, 0, 0),
(99602340, 4, -7213.949, 1228.690, 333.688, 0.3903, 0, 0, 0),
(99602340, 5, -7213.346, 1231.469, 333.688, 1.7922, 0, 0, 0),
(99602340, 6, -7217.649, 1243.318, 329.492, 1.9257, 0, 0, 0),
(99602340, 7, -7221.277, 1252.544, 324.869, 1.9532, 0, 0, 0),
(99602340, 8, -7229.112, 1271.745, 324.869, 1.9179, 0, 0, 0),
(99602340, 9, -7238.159, 1271.462, 324.869, 3.3984, 0, 0, 0),
(99602340, 10, -7246.302, 1264.399, 324.869, 4.1798, 0, 0, 0),
(99602340, 11, -7242.795, 1255.174, 324.869, 5.0477, 0, 0, 0),
(99602340, 12, -7239.722, 1245.129, 324.869, 5.0752, 0, 0, 0),
(99602340, 13, -7235.565, 1233.599, 329.492, 5.0595, 0, 0, 0),
(99602340, 14, -7231.300, 1223.027, 333.688, 5.9156, 0, 0, 0),
(99602340, 15, -7222.730, 1225.502, 333.688, 1.8472, 0, 0, 0),
(99602340, 16, -7224.809, 1233.261, 338.067, 1.9375, 0, 0, 0);
