-- #3996 Blood Covenant: the summoning stone and its rune from the live client cache (AscensionDB/Exiles 2026-09-13).
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`,
`Data0`, `Data1`, `Data2`, `Data5`, `Data6`) VALUES
(194111, 18, 720007, 'Blood Covenant', 0.05, 3, 1200014, 18539, 1, 1),
(194114, 23, 1012585, 'Blood Covenant Rune', 1.5, 15, 255, 0, 0, 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
`size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`),
`Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`);
