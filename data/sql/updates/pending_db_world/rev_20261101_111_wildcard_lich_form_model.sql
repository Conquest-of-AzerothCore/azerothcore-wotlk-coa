-- Wildcard Lich Form 280535 (#10609) transforms into creature 735821, which had no template, so the core showed
-- the pink pig 16358. The spell belongs to the Necromancer, whose Lich Form shows shapeshift form 50
-- (SpellShapeshiftForm.dbc modelID_A 223570); the Wildcard copy now shows the same Lich display.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`,
`BaseAttackTime`, `RangeAttackTime`) VALUES
(735821, 'Lich Form', 1, 1, 35, 1, 6, 2000, 2000)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
`faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`),
`BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 735821;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(735821, 0, 223570, 1, 1);
