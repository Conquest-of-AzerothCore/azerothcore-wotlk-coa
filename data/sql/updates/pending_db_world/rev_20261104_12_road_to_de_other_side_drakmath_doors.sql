-- Drak'math's web doors stand where the arena's entrance and exit are and cannot be clicked (GO_FLAG_NOT_SELECTABLE).
UPDATE `gameobject` SET `position_x` = 266.99, `position_y` = 159.03, `position_z` = 251.3, `orientation` = 2.921, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.993924, `rotation3` = 0.110073 WHERE `guid` = 9370008;
UPDATE `gameobject` SET `position_x` = 309.77, `position_y` = 159.25, `position_z` = 250.0, `orientation` = 0.325, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.161786, `rotation3` = 0.986826 WHERE `guid` = 9370009;
DELETE FROM `gameobject_template_addon` WHERE `entry` IN (2300575, 2300583);
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`, `mingold`, `maxgold`, `artkit0`, `artkit1`, `artkit2`, `artkit3`) VALUES
(2300575, 0, 16, 0, 0, 0, 0, 0, 0),
(2300583, 0, 16, 0, 0, 0, 0, 0, 0);
