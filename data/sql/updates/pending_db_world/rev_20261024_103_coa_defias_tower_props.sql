-- Defias Tower, Westfall (#8981): the realm's top-floor props and the tower fixes the release-day footage
-- (YouTube 2HEuXunIEbk 07:56-07:58) and the realm-dump sightings support. Prop templates are the WDB cache
-- records; the three Hellfire Supplies displays are inferred from their model names. Prop facings are unknown
-- except where set in game against the footage: the rug, the far crate stack and the table the poison cases
-- stand on (the realm's Inn Table prop 98022; the dump did not record its spot here).
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`,
  `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`,
  `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
(97493, 5, 8408, 'Hellfire Supplies 5 RPG Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(97494, 5, 8361, 'Hellfire Supplies 6 RPG Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(97495, 5, 1016092, 'Human Storehouse Cratestack 2 RPG Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(97496, 5, 8407, 'Hellfire Supplies 4 RPG Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(97497, 5, 1009367, 'Necromancer Rug 2 RPG Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(97498, 5, 63224, 'Inn Bench RPG Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(97499, 5, 1032287, 'Rogue Lockpicking Junk 1 RPG Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(97500, 5, 1032277, 'Rogue Smokebomb Crate 3 RPG Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(97501, 5, 1032284, 'Rogue Poison Case 1 RPG Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(97502, 5, 1032286, 'Rogue Poison Vial RPG Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(97503, 5, 1032285, 'Rogue Poison Case 3 RPG Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(97504, 5, 1037826, 'Rogue Poison Case 2 RPG Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(97505, 5, 98121, 'Human Pulley Crates RPG Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(97506, 5, 8359, 'Northrend Torch RPG Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(98022, 5, 221, 'Inn Table RPG Prop', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
  `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `unk1` = VALUES(`unk1`),
  `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`),
  `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`),
  `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`),
  `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`),
  `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`),
  `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`),
  `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`),
  `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `gameobject` WHERE `guid` BETWEEN 9950300 AND 9950314;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9950300, 97497, 0, 0, 0, 1, 1, -10259.701, 1780.790, 73.768, 1.5708, 0, 0, 0.7071081, 0.7071055, 120, 100, 1, '', 0, 'Defias Tower top floor (realm dump)'),
(9950301, 97493, 0, 0, 0, 1, 1, -10265.883, 1788.572, 73.892, 5.98, 0, 0, -0.1510127, 0.9885318, 120, 100, 1, '', 0, 'Defias Tower top floor (realm dump)'),
(9950302, 97495, 0, 0, 0, 1, 1, -10254.262, 1781.714, 73.807, 0, 0, 0, 0, 1, 120, 100, 1, '', 0, 'Defias Tower top floor (realm dump)'),
(9950303, 97494, 0, 0, 0, 1, 1, -10264.842, 1763.562, 73.837, 0, 0, 0, 0, 1, 120, 100, 1, '', 0, 'Defias Tower top floor (realm dump)'),
(9950304, 97496, 0, 0, 0, 1, 1, -10256.309, 1759.084, 73.843, 0, 0, 0, 0, 1, 120, 100, 1, '', 0, 'Defias Tower top floor (realm dump)'),
(9950305, 97500, 0, 0, 0, 1, 1, -10250.361, 1788.892, 73.802, 0, 0, 0, 0, 1, 120, 100, 1, '', 0, 'Defias Tower top floor (realm dump)'),
(9950306, 97498, 0, 0, 0, 1, 1, -10251.094, 1784.495, 73.552, 0, 0, 0, 0, 1, 120, 100, 1, '', 0, 'Defias Tower top floor (realm dump)'),
(9950307, 97503, 0, 0, 0, 1, 1, -10257.217, 1773.135, 74.802, 0, 0, 0, 0, 1, 120, 100, 1, '', 0, 'Defias Tower top floor (realm dump)'),
(9950308, 97504, 0, 0, 0, 1, 1, -10256.557, 1773.895, 74.883, 0, 0, 0, 0, 1, 120, 100, 1, '', 0, 'Defias Tower top floor (realm dump)'),
(9950309, 97502, 0, 0, 0, 1, 1, -10257.592, 1772.315, 74.834, 0, 0, 0, 0, 1, 120, 100, 1, '', 0, 'Defias Tower top floor (realm dump)'),
(9950310, 97501, 0, 0, 0, 1, 1, -10259.479, 1769.801, 74.885, 0, 0, 0, 0, 1, 120, 100, 1, '', 0, 'Defias Tower top floor (realm dump)'),
(9950311, 97499, 0, 0, 0, 1, 1, -10250.600, 1787.081, 74.876, 0, 0, 0, 0, 1, 120, 100, 1, '', 0, 'Defias Tower top floor (realm dump)'),
(9950312, 97505, 0, 0, 0, 1, 1, -10249.773, 1771.814, 42.169, 0, 0, 0, 0, 1, 120, 100, 1, '', 0, 'Defias Tower ground floor (realm dump)'),
(9950313, 97506, 0, 0, 0, 1, 1, -10256.027, 1763.869, 38.848, 0, 0, 0, 0, 1, 120, 100, 1, '', 0, 'Defias Tower ground floor (realm dump)'),
(9950314, 98022, 0, 0, 0, 1, 1, -10258.02, 1771.85, 73.819, 5.664, 0, 0, -0.3046707, 0.9524578, 120, 100, 1, '', 0, 'Defias Tower top floor: table under the poison cases (estimated)');

-- Lenore stood 0.94 yd above the top floor; the Westfall Supply Cache returns to the realm dump's point.
UPDATE `creature` SET `position_z` = 73.892 WHERE `guid` = 9950107 AND `id` = 991515;
UPDATE `gameobject` SET `position_x` = -10251.334, `position_y` = 1757.995, `position_z` = 73.902
WHERE `guid` = 6940698 AND `id` = 518321;

-- A stock Goretusk spawned under the tower's ground floor (2.9 yd headroom) and wandered through it.
DELETE FROM `creature` WHERE `guid` = 86197 AND `id` = 157;
