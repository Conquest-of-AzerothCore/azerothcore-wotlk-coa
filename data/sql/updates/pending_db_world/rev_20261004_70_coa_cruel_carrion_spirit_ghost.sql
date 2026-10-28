-- The Cruel Carrion Spirit wears the Ghost Visual 22650 like the Hyena Spirit. Its spawn's own addon row, which
-- carries its flight path, overrides the template's, so both carry the aura.
DELETE FROM `creature_template_addon` WHERE `entry` = 161834;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`,
    `visibilityDistanceType`, `auras`) VALUES
(161834, 0, 0, 0, 1, 0, 0, '22650');
UPDATE `creature_addon` SET `auras` = '22650' WHERE `guid` = 9011005;

-- It circles the rock formation at the western edge of Hard Basin (the tall spire Thousandrock14 and its smaller
-- neighbour) instead of the lake: 12 points 14 yd around (-3592, -1074) at height 219, 12-15 yd above the ground and
-- clear of the fallen tree, the smaller spire and the cliff ledges to the south-west.
UPDATE `creature` SET `position_x` = -3578.0, `position_y` = -1074.0, `position_z` = 219, `orientation` = 1.8326
    WHERE `guid` = 9011005;
DELETE FROM `waypoint_data` WHERE `id` = 90110050;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`,
    `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(90110050, 1, -3578.0, -1074.0, 219, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 2, -3579.9, -1067.0, 219, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 3, -3585.0, -1061.9, 219, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 4, -3592.0, -1060.0, 219, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 5, -3599.0, -1061.9, 219, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 6, -3604.1, -1067.0, 219, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 7, -3606.0, -1074.0, 219, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 8, -3604.1, -1081.0, 219, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 9, -3599.0, -1086.1, 219, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 10, -3592.0, -1088.0, 219, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 11, -3585.0, -1086.1, 219, NULL, 0, 0, 0, 0, 0, 100, 0),
(90110050, 12, -3579.9, -1081.0, 219, NULL, 0, 0, 0, 0, 0, 100, 0);

-- It stands neutral until attacked, like the Grimtotem Marauders, and has 526 health at level 4 as in video of it
-- (health modifier 6.1163 on the level 4 warrior base of 86).
UPDATE `creature_template` SET `faction` = 7, `HealthModifier` = 6.1163 WHERE `entry` = 161834;
