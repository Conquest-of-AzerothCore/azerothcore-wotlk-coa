-- Hound of House Cain 161836 (I'm Home 1660042) sank below ground (issues 5862, 5931): he wandered 3 yd around his
-- grave (ST8718), which lies at the manor's back wall above its cellar, and random movement could take him onto
-- the cellar's walkable floor beneath. He now patrols the back of the house above ground instead, along the house
-- line past his grave in both directions: from his grave north to the manor's north corner, back past the grave
-- to the south corner, and back, pausing 6 s at the grave and at each end. The line is a shortest walkable path
-- 1 yd clear of the wall (surface.standable) that keeps 1.8 yd from the grave mound and its tombstone (INFERRED
-- route; playtest).
UPDATE `creature` SET `wander_distance` = 0, `MovementType` = 2 WHERE `guid` = 9010012 AND `id` = 161836;
DELETE FROM `creature_addon` WHERE `guid` = 9010012;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9010012, 90100120, 0, 0, 0, 0, 0, '');
DELETE FROM `waypoint_data` WHERE `id` = 90100120;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(90100120, 1, 1942.72, 1985.06, 156.079, NULL, 0, 6000, 0, 0, 0, 100, 0),
(90100120, 2, 1943.5, 1985.5, 156.164, NULL, 0, 0, 0, 0, 0, 100, 0),
(90100120, 3, 1947.5, 1985.5, 156.43, NULL, 0, 0, 0, 0, 0, 100, 0),
(90100120, 4, 1950.5, 1982.5, 156.183, NULL, 0, 0, 0, 0, 0, 100, 0),
(90100120, 5, 1954.0, 1979.5, 156.103, NULL, 0, 0, 0, 0, 0, 100, 0),
(90100120, 6, 1955.0, 1978.5, 156.001, NULL, 0, 6000, 0, 0, 0, 100, 0),
(90100120, 7, 1954.0, 1979.5, 156.103, NULL, 0, 0, 0, 0, 0, 100, 0),
(90100120, 8, 1950.5, 1982.5, 156.183, NULL, 0, 0, 0, 0, 0, 100, 0),
(90100120, 9, 1947.5, 1985.5, 156.43, NULL, 0, 0, 0, 0, 0, 100, 0),
(90100120, 10, 1943.5, 1985.5, 156.164, NULL, 0, 0, 0, 0, 0, 100, 0),
(90100120, 11, 1939.5, 1985.5, 155.968, NULL, 0, 0, 0, 0, 0, 100, 0),
(90100120, 12, 1935.5, 1987.0, 155.918, NULL, 0, 0, 0, 0, 0, 100, 0),
(90100120, 13, 1931.5, 1987.0, 156.132, NULL, 0, 0, 0, 0, 0, 100, 0),
(90100120, 14, 1928.0, 1985.0, 156.243, NULL, 0, 0, 0, 0, 0, 100, 0),
(90100120, 15, 1924.0, 1983.5, 156.83, NULL, 0, 6000, 0, 0, 0, 100, 0),
(90100120, 16, 1928.0, 1985.0, 156.243, NULL, 0, 0, 0, 0, 0, 100, 0),
(90100120, 17, 1931.5, 1987.0, 156.132, NULL, 0, 0, 0, 0, 0, 100, 0),
(90100120, 18, 1935.5, 1987.0, 155.918, NULL, 0, 0, 0, 0, 0, 100, 0),
(90100120, 19, 1939.5, 1985.5, 155.968, NULL, 0, 0, 0, 0, 0, 100, 0);
