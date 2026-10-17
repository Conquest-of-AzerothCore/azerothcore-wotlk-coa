-- Kharadol Supplies (175058): the props the user placed on Kharadol Bridge become the quest pick-ups, keeping each prop's model.
-- Scattered crates = Medical Supplies, red ammo boxes = Guard Ammunition, the dropped guns = Kharadol Blunderbuss.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data3`, `Data8`, `Data10`, `Data12`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(2300803, 3, 335, 'Medical Supplies', '', '', '', 1, 1689, 2300803, 1, 175058, 1, 1, '', '', 0),
(2300805, 3, 6611, 'Guard Ammunition', '', '', '', 1, 1689, 2300805, 1, 175058, 1, 1, '', '', 0),
(2300806, 3, 5512, 'Guard Ammunition', '', '', '', 1, 1689, 2300805, 1, 175058, 1, 1, '', '', 0),
(2300807, 3, 515034, 'Kharadol Blunderbuss', '', '', '', 1, 1689, 2300804, 1, 175058, 1, 1, '', '', 0) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data3` = VALUES(`Data3`), `Data8` = VALUES(`Data8`), `Data10` = VALUES(`Data10`), `Data12` = VALUES(`Data12`);
UPDATE `gameobject` SET `id` = 2300803, `spawntimesecs` = 30 WHERE `guid` IN (9963471, 9963486, 9963487, 9963488, 9963489, 9963490, 9963491);
UPDATE `gameobject` SET `id` = 2300805, `spawntimesecs` = 30 WHERE `guid` IN (9963468, 9963472, 9963492, 9963493, 9963494, 9963495, 9963496, 9963497, 9963498, 9963499);
UPDATE `gameobject` SET `id` = 2300806, `spawntimesecs` = 30 WHERE `guid` = 9963467;
UPDATE `gameobject` SET `id` = 2300804, `spawntimesecs` = 30 WHERE `guid` IN (9963482, 9963483, 9963484, 9963485);
UPDATE `gameobject` SET `id` = 2300807, `spawntimesecs` = 30 WHERE `guid` = 9963470;
