-- Sage Nauchol asks "Have you brought everything we need for the disguise?" when a player carrying Death and Dishonor
-- 1660032, whose pendants lie by the Cruel Carrion Spirit in Hard Basin, comes back within 15 yd, at most once a
-- minute. The line is CoA's, as players recorded it. It adds his text group 2 and script row 6.
DELETE FROM `creature_text` WHERE `CreatureID` = 161819 AND `GroupID` = 2;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Probability`, `comment`) VALUES
(161819, 2, 0, 'Have you brought everything we need for the disguise?', 12, 100, 'Sage Nauchol - a player returns with Death and Dishonor (CoA)');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 161819 AND `source_type` = 0 AND `id` = 6;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`,
    `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`,
    `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`,
    `target_o`, `comment`) VALUES
(161819, 0, 6, 0, 10, 0, 100, 0, 1, 15, 60000, 60000, 1, 0, 1, 2, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Sage Nauchol - On a player in sight with Death and Dishonor - Say Line 2');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 7 AND `SourceEntry` = 161819 AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
    `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
    `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 7, 161819, 0, 0, 47, 0, 1660032, 10, 0, 0, 0, 0, '', 'Nauchol asks after the disguise only a player carrying Death and Dishonor');
