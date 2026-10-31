-- Jelena Goret walks a short circuit by her post, pausing at each end; route recorded in game with CoA World Edit.
UPDATE `creature` SET `MovementType` = 2, `wander_distance` = 0 WHERE `guid` = 9920211 AND `id` = 164982;

DELETE FROM `creature_addon` WHERE `guid` = 9920211;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9920211, 99202110, 0, 0, 1, 0, 0, '');

DELETE FROM `waypoint_data` WHERE `id` = 99202110;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`,
    `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(99202110, 1, -8372.987, 642.375, 95.258, 5.7036, 0, 10000, 0, 0, 0, 100, 0),
(99202110, 2, -8385.352, 650.530, 95.205, 2.5580, 0, 4000, 0, 0, 0, 100, 0),
(99202110, 3, -8385.352, 650.530, 95.205, 2.5580, 0, 8000, 0, 0, 0, 100, 0),
(99202110, 4, -8373.923, 650.416, 95.628, 5.3203, 0, 0, 0, 0, 0, 100, 0);
