-- First-Class Experimental Teleporter (gameobject 323232): an 8 gold goblin teleporter beside the capitals'
-- Call Boards, in Ironforge and Darnassus, and in Booty Bay, Gadgetzan and Everlook.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data14`, `Data15`, `Data19`,
`Data20`, `ScriptName`) VALUES
(323232, 10, 2047, 'First-Class Experimental Teleporter', 1, 65535, 65535, 61004, 1, 'go_coa_experimental_teleporter')
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
`size` = VALUES(`size`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data19` = VALUES(`Data19`),
`Data20` = VALUES(`Data20`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `npc_text` WHERE `ID` = 61004;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `Probability0`) VALUES
(61004, 'Welcome to the First-Class Experimental Teleporter! $B$BFor a modest fee, this marvel of goblin engineering will hurl you across Azeroth in the blink of an eye. $B$BSimply select your destination and hold on tight. Management is not responsible for unexpected detours, rough landings, or spontaneous combustion.', 'Welcome to the First-Class Experimental Teleporter! $B$BFor a modest fee, this marvel of goblin engineering will hurl you across Azeroth in the blink of an eye. $B$BSimply select your destination and hold on tight. Management is not responsible for unexpected detours, rough landings, or spontaneous combustion.', 1);

DELETE FROM `gossip_menu` WHERE `MenuID` = 61004;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(61004, 61004);

DELETE FROM `gameobject` WHERE `guid` BETWEEN 7905410 AND 7905416;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
`position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
`animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(7905410, 323232, 0, 0, 0, 1, 1, -8806.96, 622.632, 94.746, 3.92699, 0, 0, 0.9238797, -0.3826829, 0, 100, 1, '', 0,
'First-Class Experimental Teleporter (Stormwind)'),
(7905411, 323232, 1, 0, 0, 1, 1, 1579.26, -4421.08, 8.04226, 3.14159, 0, 0, 1, 0, 0, 100, 1, '', 0,
'First-Class Experimental Teleporter (Orgrimmar)'),
(7905412, 323232, 1, 0, 0, 1, 1, 9968.133, 2342.439, 1330.776, 1.86767, 0, 0, 0.8039081, 0.5947536, 0, 100, 1, '', 0,
'First-Class Experimental Teleporter (Darnassus)'),
(7905413, 323232, 0, 0, 0, 1, 1, -4917.143, -984.885, 501.449, 2.44025, 0, 0, 0.9391427, 0.3435274, 0, 100, 1, '', 0,
'First-Class Experimental Teleporter (Ironforge)'),
(7905414, 323232, 0, 0, 0, 1, 1, -14293.148, 516.857, 8.953, 3.32458, 0, 0, 0.9958174, -0.091367, 0, 100, 1, '', 0,
'First-Class Experimental Teleporter (Booty Bay)'),
(7905415, 323232, 1, 0, 0, 1, 1, -7162.376, -3783.913, 8.807, 2.9584, 0, 0, 0.995808, 0.0914683, 0, 100, 1, '', 0,
'First-Class Experimental Teleporter (Gadgetzan)'),
(7905416, 323232, 1, 0, 0, 1, 1, 6710.468, -4623.654, 722.114, 5.99887, 0, 0, 0.1416774, -0.9899129, 0, 100, 1, '', 0,
'First-Class Experimental Teleporter (Everlook)');
