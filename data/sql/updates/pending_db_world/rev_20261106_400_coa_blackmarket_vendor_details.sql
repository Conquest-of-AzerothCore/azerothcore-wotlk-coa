-- Black Market Artisan Supplies vendors (#11341): ranks, levels and health from the live WDB captures
-- (C:\CoA\SUB\WDB, up to 2026-09-05) and db.exil.es, and the displays the client carries for ten of them.
UPDATE `creature_template` SET `rank` = 1 WHERE `entry` IN (970000, 970034);
UPDATE `creature_template` SET `minlevel` = 61, `maxlevel` = 61 WHERE `entry` = 970034;
UPDATE `creature_template` SET `minlevel` = 40, `maxlevel` = 40 WHERE `entry` = 970038;
UPDATE `creature_template` SET `HealthModifier` = 1.512 WHERE `entry` IN (970001, 970013, 970031);
UPDATE `creature_template` SET `HealthModifier` = 1 WHERE `entry` = 970020;

DELETE FROM `creature_template_model`
WHERE `CreatureID` IN (970000, 970002, 970004, 970006, 970011, 970020, 970022, 970024, 970034, 970042);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(970000, 0, 102251, 1, 1, 0),
(970002, 0, 102253, 1, 1, 0),
(970004, 0, 8249, 1, 1, 0),
(970006, 0, 8803, 1, 1, 0),
(970011, 0, 6825, 1, 1, 0),
(970020, 0, 11265, 1, 1, 0),
(970022, 0, 27756, 1, 1, 0),
(970024, 0, 93323, 1, 1, 0),
(970034, 0, 15560, 1, 1, 0),
(970034, 1, 15559, 1, 1, 0),
(970034, 2, 15558, 1, 1, 0),
(970042, 0, 102250, 1, 1, 0);

-- Nine spawns stood 0.6 to 2 yd above or below the ground the server finds at their points.
UPDATE `creature` SET `position_z` = 48.29 WHERE `guid` = 9700009 AND `id` = 970009;
UPDATE `creature` SET `position_z` = -185.31 WHERE `guid` = 9700018 AND `id` = 970018;
UPDATE `creature` SET `position_z` = 761.1 WHERE `guid` = 9700023 AND `id` = 970023;
UPDATE `creature` SET `position_z` = 83.76 WHERE `guid` = 9700028 AND `id` = 970028;
UPDATE `creature` SET `position_z` = 6.02 WHERE `guid` = 9700029 AND `id` = 970029;
UPDATE `creature` SET `position_z` = 34.81 WHERE `guid` = 9700030 AND `id` = 970030;
UPDATE `creature` SET `position_z` = 33.83 WHERE `guid` = 9700034 AND `id` = 970034;
UPDATE `creature` SET `position_z` = 62.39 WHERE `guid` = 9700035 AND `id` = 970035;
UPDATE `creature` SET `position_z` = 34.97 WHERE `guid` = 9700041 AND `id` = 970041;
