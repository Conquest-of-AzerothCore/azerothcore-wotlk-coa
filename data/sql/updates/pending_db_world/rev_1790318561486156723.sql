INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`,
`BaseAttackTime`, `RangeAttackTime`, `flags_extra`) VALUES
(100481, 'Spectral Warden', 1, 1, 35, 1, 6, 2000, 2000, 64)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`),
`maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`),
`type` = VALUES(`type`), `BaseAttackTime` = VALUES(`BaseAttackTime`),
`RangeAttackTime` = VALUES(`RangeAttackTime`), `flags_extra` = VALUES(`flags_extra`);

DELETE FROM `creature_model_info` WHERE `DisplayID` = 211120;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES
(211120, 0.6111109852790833, 2.031280040740967, 2, 0);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 100481;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(100481, 0, 211120, 1, 1);
