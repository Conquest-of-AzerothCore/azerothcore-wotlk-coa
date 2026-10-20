-- Brumbof Bramstum: live gossip pages, level and faction (#7422)
UPDATE `creature_template` SET `minlevel` = 14, `maxlevel` = 14, `faction` = 104 WHERE `entry` = 753513;

DELETE FROM `npc_text` WHERE `ID` IN (9010700, 9010701);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `lang0`, `Probability0`) VALUES
(9010700, '<The drummer is busy playing his drum. He doesn''t seem to notice you.>', '<The drummer is busy playing his drum. He doesn''t seem to notice you.>', 0, 1),
(9010701, 'I didn''t realize there was another drummer here at the Crossroads.$B$BI''ve got a spare drumstick, you can have it if you promise to introduce us after the party!', 'I didn''t realize there was another drummer here at the Crossroads.$B$BI''ve got a spare drumstick, you can have it if you promise to introduce us after the party!', 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` = 9010701;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(9010701, 9010701);

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 9010700;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`) VALUES
(9010700, 0, 0, 'Excuse me, friend. I need a drumstick for someone, do you have one you can spare?', 0, 1, 1, 9010701, 0, 0, 0, '', 0);

DELETE FROM `smart_scripts` WHERE `entryorguid` = 753513 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(753513, 0, 0, 0, 62, 0, 100, 0, 9010700, 0, 0, 0, 0, 0, 56, 355122, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Brumbof Bramstum - On Gossip Option 0 Selected - Add Drumstick');
