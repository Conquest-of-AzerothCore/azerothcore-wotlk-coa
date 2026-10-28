-- Belorite Sprites (175095): picking a Belorita flower while on the quest calls up a Belorite Sprite that attacks the picker,
-- as on live (user); it leaves after a minute out of combat.
UPDATE `gameobject_template` SET `AIName` = 'SmartGameObjectAI' WHERE `entry` = 2300686;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 2300686 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300686, 1, 0, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 164306, 4, 60000, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Belorita - On Use - Summon Belorite Sprite (attacks the picker)');
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` = 2300686 AND `SourceId` = 1;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 2300686, 1, 0, 9, 0, 175095, 0, 0, 0, 0, 0, '', 'Belorita - sprite only while on Belorite Sprites');
