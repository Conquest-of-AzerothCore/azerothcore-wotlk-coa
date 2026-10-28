-- Copy the authored patrol routes onto the path ids the rekeyed spawns use. The rows are
-- copied in SQL so no id or point value can be mangled in transit.
START TRANSACTION;
DELETE FROM `waypoint_data` WHERE `id` = 99162270;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) SELECT `id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid` FROM `waypoint_data` WHERE `id` = 99992670;
UPDATE `waypoint_data` SET `id` = 99162270 WHERE `id` = 99992670 AND 1 = 0;
DELETE FROM `waypoint_data` WHERE `id` = 99162280;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) SELECT `id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid` FROM `waypoint_data` WHERE `id` = 99992680;
UPDATE `waypoint_data` SET `id` = 99162280 WHERE `id` = 99992680 AND 1 = 0;
UPDATE `creature_addon` SET `path_id` = 99162270 WHERE `guid` = 9916227;
UPDATE `creature_addon` SET `path_id` = 99162280 WHERE `guid` = 9916228;
COMMIT;
