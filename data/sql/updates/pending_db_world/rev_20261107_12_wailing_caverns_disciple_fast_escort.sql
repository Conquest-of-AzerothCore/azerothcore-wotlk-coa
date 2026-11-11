-- Wailing Caverns: the Disciple of Naralex also offers a fast escort, as on Ascension (#11468). The second option starts the same event, but he runs his path instead of walking it.
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 201 AND `OptionID` = 1;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(201, 1, 0, 'I don''t have much time left. Let''s hurry!', 0, 1, 1, 0, 0, 0, 0, '', 0, 0);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 201 AND `SourceEntry` = 1 AND `SourceId` = 0 AND `ElseGroup` = 0 AND `ConditionTypeOrReference` = 13 AND `ConditionTarget` = 0 AND `ConditionValue1` = 5 AND `ConditionValue2` = 1 AND `ConditionValue3` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(15, 201, 1, 0, 0, 13, 0, 5, 1, 0, 1, 0, 0, '', 'Disciple of Naralex - Hide fast event start in a Wailing Caverns wing that ends before Mutanus');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 3678 AND `source_type` = 0 AND `id` IN (37, 38, 39, 40);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(3678, 0, 37, 38, 62, 0, 100, 512, 201, 1, 0, 0, 0, 0, 2, 250, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Disciple of Naralex - On Gossip Option 1 Selected - Set Faction 250'),
(3678, 0, 38, 39, 61, 0, 100, 512, 0, 0, 0, 0, 0, 0, 48, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Disciple of Naralex - On Gossip Option 1 Selected - Set Active On'),
(3678, 0, 39, 40, 61, 0, 100, 512, 0, 0, 0, 0, 0, 0, 53, 2, 3678, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Disciple of Naralex - On Gossip Option 1 Selected - Start Waypoint (run)'),
(3678, 0, 40, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 0, 8, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Disciple of Naralex - On Gossip Option 1 Selected - Set Reactstate Aggressive');
