-- Wildcard Guardian of Ancient Kings 277875 (#10606) transforms into creature 80220, which the database lacked, so
-- SPELL_AURA_TRANSFORM fell back to the pink pig 16358. The live creature cache (ascension-data union
-- creaturecache, mode conquest-of-azeroth) records creature 80220 'Guardian of Ancient Kings' with display 35107
-- (CreatureDisplayInfo model 3647 AvengingAngel, scale 0.6), type 10.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`,
`faction`, `unit_class`, `type`) VALUES
(80220, 'Guardian of Ancient Kings', 1, 1, 35, 1, 10)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
`faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 80220;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(80220, 0, 35107, 1, 1);
