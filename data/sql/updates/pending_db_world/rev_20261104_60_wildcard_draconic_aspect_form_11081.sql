--
-- Wildcard Draconic Aspect (280600) transforms into creature 379386, which the database lacked, so the transform
-- fell back to the pig display (#11081). The Pyromancer Draconic Aspect (802117) shows dracthyr display 142067;
-- the form creature carries that display.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`,
`faction`, `unit_class`, `type`) VALUES
(379386, 'Draconic Aspect', 1, 1, 35, 1, 2)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
`faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 379386;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(379386, 0, 142067, 1, 1);
