-- The Cruel Carrion Spirit circles out of melee reach; it dives at players hunting it for Fighting Over Carrion.
DELETE FROM `creature_text` WHERE `CreatureID` = 161834 AND `GroupID` = 0;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`,
    `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(161834, 0, 0, 'The carrion spirit senses your soul.', 42, 0, 100, 0, 0, 0, 0, 0,
    'Cruel Carrion Spirit - Dives at a Fighting Over Carrion holder');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 161834 AND `source_type` = 0 AND `id` IN (2, 3);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`,
    `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`,
    `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`,
    `target_o`, `comment`) VALUES
(161834, 0, 2, 3, 10, 0, 100, 0, 2, 30, 5000, 5000, 1, 0, 49, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
    'Cruel Carrion Spirit - Out of Combat LoS - Attack Fighting Over Carrion holder'),
(161834, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
    'Cruel Carrion Spirit - Linked - Whisper Line 0 to the hunter');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 3 AND `SourceEntry` = 161834
    AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
    `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
    `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 3, 161834, 0, 0, 9, 0, 1660043, 0, 0, 0, 0, 0, '', 'Cruel Carrion Spirit dives only at Fighting Over Carrion holders');
