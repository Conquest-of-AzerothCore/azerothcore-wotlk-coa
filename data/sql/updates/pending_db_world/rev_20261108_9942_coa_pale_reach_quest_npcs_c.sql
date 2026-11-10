-- Chieftain Saidarn (9961100) walked the Braicag Heights pond bed: half his 39-yard wander circle was water
-- (#10689). He now patrols the shore out and back through his six live sightings, west of the bare tree.
UPDATE `creature` SET `position_x` = -7695.8, `position_y` = 1667.3, `position_z` = 229.7, `orientation` = 0.8638,
    `MovementType` = 2, `wander_distance` = 0 WHERE `guid` = 9961100 AND `id` = 164342;
DELETE FROM `creature_addon` WHERE `guid` = 9961100;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
    `auras`) VALUES
(9961100, 99611000, 0, 0, 0, 0, 0, '');
DELETE FROM `waypoint_data` WHERE `id` = 99611000;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `delay`, `move_type`) VALUES
(99611000, 1, -7695.8, 1667.3, 229.7, 0, 0),
(99611000, 2, -7692.3, 1671.3, 229.55, 0, 0),
(99611000, 3, -7680, 1675, 228.77, 0, 0),
(99611000, 4, -7670, 1681, 228.58, 0, 0),
(99611000, 5, -7656, 1681, 227.9, 0, 0),
(99611000, 6, -7646, 1672, 228.06, 0, 0),
(99611000, 7, -7642.8, 1667.4, 227.81, 0, 0),
(99611000, 8, -7639.1, 1664.5, 229.1, 0, 0),
(99611000, 9, -7636, 1661.4, 229.79, 0, 0),
(99611000, 10, -7633.5, 1657.4, 229.19, 0, 0),
(99611000, 11, -7636, 1661.4, 229.79, 0, 0),
(99611000, 12, -7639.1, 1664.5, 229.1, 0, 0),
(99611000, 13, -7642.8, 1667.4, 227.81, 0, 0),
(99611000, 14, -7646, 1672, 228.06, 0, 0),
(99611000, 15, -7656, 1681, 227.9, 0, 0),
(99611000, 16, -7670, 1681, 228.58, 0, 0),
(99611000, 17, -7680, 1675, 228.77, 0, 0),
(99611000, 18, -7692.3, 1671.3, 229.55, 0, 0);
