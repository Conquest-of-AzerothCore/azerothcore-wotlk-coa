-- Invisible carriers tilt Road's statue traps downward: the trap rides seat 0 of vehicle 827 (pitch -0.75) or seat 2 of vehicle 375 (pitch -0.873).
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_flags`, `type`, `VehicleId`, `flags_extra`, `ScriptName`) VALUES (9937001,
'Venom Trap Carrier (43)', 60, 60, 35, 33554434, 10, 827, 128, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`), `VehicleId` = VALUES(`VehicleId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_flags`, `type`, `VehicleId`, `flags_extra`, `ScriptName`) VALUES (9937002,
'Venom Trap Carrier (50)', 60, 60, 35, 33554434, 10, 375, 128, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`), `VehicleId` = VALUES(`VehicleId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9937001, 9937002);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(9937001, 0, 11686, 1, 1, 12340),
(9937002, 0, 11686, 1, 1, 12340);
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (9937001, 9937002);
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(9937001, 0, 0, 1, 1),
(9937002, 0, 0, 1, 1);
-- The statue traps sit 1 yard lower, at the statues' mouths.
UPDATE `creature` SET `position_z` = `position_z` - 1 WHERE `id` = 162975 AND `guid` BETWEEN 9370601 AND 9370618;
