-- The client tilts a passenger down for a positive seat pitch: the carriers use vehicle 249 seat 3 (0.785), 808 seat 1 (0.9) and 522 seat 0 (0.611).
DELETE FROM `creature_template` WHERE `entry` IN (9937001, 9937002, 9937003);
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_flags`, `type`, `VehicleId`, `flags_extra`, `ScriptName`) VALUES
(9937001, 'Venom Trap Carrier (45)', 60, 60, 35, 33554434, 10, 249, 128, ''),
(9937002, 'Venom Trap Carrier (52)', 60, 60, 35, 33554434, 10, 808, 128, ''),
(9937003, 'Venom Trap Carrier (35)', 60, 60, 35, 33554434, 10, 522, 128, '');
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9937001, 9937002, 9937003);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(9937001, 0, 11686, 1, 1, 12340),
(9937002, 0, 11686, 1, 1, 12340),
(9937003, 0, 11686, 1, 1, 12340);
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (9937001, 9937002, 9937003);
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(9937001, 0, 0, 1, 1),
(9937002, 0, 0, 1, 1),
(9937003, 0, 0, 1, 1);
