--
-- Ancient of War (504222, Wildcard 281261) transforms into creature 346922, which the database lacked.
-- The client's own Ancient of War form display 111212 (model 187113, scale 0.7) pairs with Ancient of Lore's
-- 111213 (creature 346852); the NPC display 1461 used until now has client scale 3.0.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`,
`faction`, `unit_class`, `type`) VALUES
(346922, 'Ancient of War', 1, 1, 35, 1, 7)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
`faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 346922;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(346922, 0, 111212, 1, 1);
