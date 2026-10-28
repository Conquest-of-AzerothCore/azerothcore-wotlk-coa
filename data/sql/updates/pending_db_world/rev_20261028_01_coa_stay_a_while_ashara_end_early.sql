-- Stay a While (1660054): Dark Priestess Ashara's sermon in Brill ran for almost a minute with no way to end it, while
-- Aliscar Lend's lesson (1660060) offers "Thank you, I've heard enough." During the sermon her gossip menu now switches
-- to that option, which closes the window and credits the listener; the sermon menu returns when she finishes.
DELETE FROM `gossip_menu` WHERE `MenuID` = 932418;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(932418, 85157);

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 932418;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`) VALUES
(932418, 0, 0, 'Thank you, I''ve heard enough.', 0, 1, 1, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 932418;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(15, 932418, 0, 0, 0, 9, 0, 1660054, 0, 0, 0, 0, 0, '', 'Dark Priestess Ashara - Show the early ending only while Stay a While is taken');

UPDATE `smart_scripts` SET `action_type` = 240, `action_param1` = 932418, `comment` = 'Dark Priestess Ashara - Linked - Offer to end the sermon early'
    WHERE `entryorguid` = 162847 AND `source_type` = 0 AND `id` = 1;
UPDATE `smart_scripts` SET `action_type` = 240, `action_param1` = 932415, `comment` = 'Dark Priestess Ashara sermon - Restore the sermon menu'
    WHERE `entryorguid` = 16284700 AND `source_type` = 9 AND `id` = 6;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 162847 AND `source_type` = 0 AND `id` IN (3, 4);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(162847, 0, 3, 4, 62, 0, 100, 0, 932418, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Priestess Ashara - On heard enough - Close Gossip'),
(162847, 0, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Priestess Ashara - Linked - Credit listening to her');
