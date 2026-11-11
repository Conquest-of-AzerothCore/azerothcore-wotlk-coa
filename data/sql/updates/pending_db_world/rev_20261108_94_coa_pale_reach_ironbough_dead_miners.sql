-- The two Miners on the path to Ironbough Mine lie dead and cannot be selected or attacked (SlF-lzlpaGg at 11:07 and
-- 11:16). The Rockrend Miners share the template and keep standing.
UPDATE `creature` SET `unit_flags` = 33555202 WHERE `guid` IN (9960106, 9960113) AND `id` = 164028;
DELETE FROM `creature_addon` WHERE `guid` IN (9960106, 9960113);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960106, 0, 0, 0, 1, 0, 0, '29266'),
(9960113, 0, 0, 0, 1, 0, 0, '29266');
