-- Kharadol Bridge: the five Graysky Soldiers there lie dead (Permanent Feign Death), as in the live game.
DELETE FROM `creature_addon` WHERE `guid` IN (9981393, 9981394, 9981395, 9981396, 9981397);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9981393, 0, 0, 0, 1, 0, 0, '29266'),
(9981394, 0, 0, 0, 1, 0, 0, '29266'),
(9981395, 0, 0, 0, 1, 0, 0, '29266'),
(9981396, 0, 0, 0, 1, 0, 0, '29266'),
(9981397, 0, 0, 0, 1, 0, 0, '29266');
