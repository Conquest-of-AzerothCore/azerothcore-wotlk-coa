-- Storm Ascendance's linked transform 681187 uses visual-only creature 161579.
-- ascension-data CoA enUS creaturecache, captured 2026-09-04, has its sole display 101201.
-- CreatureDisplayInfo.dbc confirms model 12849 and scale 1.0; no spawn geometry is inferred.
START TRANSACTION;
INSERT INTO `creature_template` (`entry`, `name`, `faction`, `unit_class`, `type`) VALUES
(161579, 'Storm Elemental', 35, 1, 4) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161579;
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(161579, 0, 101201, 1, 1);
COMMIT;
