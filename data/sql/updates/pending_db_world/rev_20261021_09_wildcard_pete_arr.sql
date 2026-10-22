-- Pete Arr <Plunder Trade Representative (PTR)>, a pirate quartermaster for test realms. The template has no
-- spawns: with Wildcard.FreeScrolls = 1 the worldserver places him beside Silas Darkmoon in Stormwind and
-- Orgrimmar (npc_wildcard_pete_arr), and his gossip opens a free vendor list built by the script.
SET @GREETING := 'Ahoy, $N! Pete Arr, Plunder Trade Representative. On the PTR me plunder be free for the taking.';
CREATE TEMPORARY TABLE `wildcard_pete_arr` ENGINE=InnoDB AS
    SELECT * FROM `creature_template` WHERE `entry` = 2500;
UPDATE `wildcard_pete_arr` SET `entry` = 642829, `name` = 'Pete Arr', `subname` = 'Plunder Trade Representative (PTR)',
    `minlevel` = 60, `maxlevel` = 60, `faction` = 35, `npcflag` = 129, `gossip_menu_id` = 0,
    `ScriptName` = 'npc_wildcard_pete_arr';
INSERT INTO `creature_template` SELECT * FROM `wildcard_pete_arr`
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`), `subname` = VALUES(`subname`), `minlevel` = VALUES(`minlevel`),
    `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`),
    `gossip_menu_id` = VALUES(`gossip_menu_id`), `ScriptName` = VALUES(`ScriptName`);
DROP TEMPORARY TABLE `wildcard_pete_arr`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 642829;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(642829, 0, 797, 1, 1);
DELETE FROM `npc_text` WHERE `ID` = 642829;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `Probability0`) VALUES
(642829, @GREETING, @GREETING, 1);
