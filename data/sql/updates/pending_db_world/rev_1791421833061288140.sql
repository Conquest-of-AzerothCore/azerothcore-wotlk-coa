-- Golem Form 805335 transforms through visual-only creature 52808.
-- ascension-data snapshot b615898e8f48b9d00ce1d35d94f7bacab28df8c9617563dc9c943d3e6106c10c,
-- enUS/conquest-of-azeroth creaturecache: Wildshape, sole display 137630, one source, capture date unspecified.
-- Payload SHA256: 2cd76ba21fbdd6dd28118d6c6cddec8b43622ae9556d6edaca9849081090776f.
-- CreatureDisplayInfo confirms model 111010 and scale 1; no spawned-creature geometry is inferred.
START TRANSACTION;
INSERT INTO `creature_template` (`entry`, `name`, `faction`, `unit_class`, `type`) VALUES
(52808, 'Wildshape', 35, 1, 0) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 52808;
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(52808, 0, 137630, 1, 1);
COMMIT;
