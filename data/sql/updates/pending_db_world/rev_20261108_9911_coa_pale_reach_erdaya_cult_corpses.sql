-- The Family Zealot and Cultist beside Enilith Naemyl in the Chambers of Erdaya are the bodies from her ambush: live
-- screenshots (071226-062536 to 062750) show both lying dead with grey nameplates. Permanent Feign Death, not
-- selectable, attackable or aggressive, as the Braicag Ealdir corpses are.
UPDATE `creature` SET `unit_flags` = 33555970 WHERE `guid` = 9960132 AND `id` = 164310;
UPDATE `creature` SET `unit_flags` = 33555970 WHERE `guid` = 9960133 AND `id` = 164312;

DELETE FROM `creature_addon` WHERE `guid` IN (9960132, 9960133);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960132, 0, 0, 0, 1, 0, 0, '29266'),
(9960133, 0, 0, 0, 1, 0, 0, '29266');
