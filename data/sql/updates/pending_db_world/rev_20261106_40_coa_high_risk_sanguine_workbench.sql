-- Sanguine Workbench (High-Risk refining spell focus 1651), from the WDB gameobject cache (2026-09-05)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`,
    `Data0`, `Data1`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(967019, 8, 140000, 'Sanguine Workbench', '', '', '', 0.65, 1651, 1, '', '', 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
    `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`);
