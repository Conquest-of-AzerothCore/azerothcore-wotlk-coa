-- Samuel Crowe (164996) wore a borrowed look with a chef's hat. On the live realm he is a dark-haired man in a black
-- ankle-length robe, lighter at the chest, walking the yard along the abbey's outer wall with empty hands (video
-- fppvzzEmIX8 00:31:48-00:31:57, 00:32:43; identified by the contributor, who recalls two braids and a Gilnean robe
-- with matching gloves). He wears the black Gilnean robe set with its gloves, belt and boots, and the braided hair.
-- He paces the yard between two points set in game, 38 yd apart on a line through his captured spawn, at a walk,
-- and stands for five seconds at each end.
UPDATE `creature_display_preset` SET `skin` = 1, `face` = 8, `hair` = 4, `haircolor` = 0, `facialhair` = 0,
`item_head` = 0, `item_shoulders` = 0, `item_body` = 0, `item_chest` = 54839, `item_waist` = 54820, `item_legs` = 0,
`item_feet` = 61815, `item_wrists` = 0, `item_hands` = 54823, `item_back` = 0, `item_tabard` = 0
WHERE `entry` = 164996 AND `display_id` = 49;
UPDATE `creature` SET `position_x` = -6946.34, `position_y` = 1720.67, `position_z` = 318.72, `orientation` = 2.555,
`MovementType` = 2, `wander_distance` = 0 WHERE `guid` = 9960637 AND `id` = 164996;
DELETE FROM `creature_addon` WHERE `guid` = 9960637;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960637, 99606370, 0, 0, 0, 0, 0, '');
DELETE FROM `waypoint_data` WHERE `id` = 99606370;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `delay`, `move_type`) VALUES
(99606370, 1, -6946.34, 1720.67, 318.72, 5000, 0),
(99606370, 2, -6954.35, 1725.99, 318.69, 0, 0),
(99606370, 3, -6962.35, 1731.31, 318.59, 0, 0),
(99606370, 4, -6970.36, 1736.63, 318.51, 0, 0),
(99606370, 5, -6978.37, 1741.95, 318.5, 5000, 0),
(99606370, 6, -6970.36, 1736.63, 318.51, 0, 0),
(99606370, 7, -6962.35, 1731.31, 318.59, 0, 0),
(99606370, 8, -6954.35, 1725.99, 318.69, 0, 0);
