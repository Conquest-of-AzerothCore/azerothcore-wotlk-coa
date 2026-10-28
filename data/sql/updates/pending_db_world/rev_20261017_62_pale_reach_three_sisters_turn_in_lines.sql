-- The Three Sisters' Wisdom (175203): handing the quest in at the Three Sisters' cauldron makes Maiden, Mother and Crone each
-- say where Carden's curse lives, as on live (the user's gameplay screenshot). The cauldron, its visibility and the quest
-- links stay as they are; the sisters' greeting (group 0) is left untouched and the turn-in line is added as group 1.
DELETE FROM `creature_text` WHERE `CreatureID` IN (164588, 164589, 164590) AND `GroupID` = 1;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(164588, 1, 0, 'Carden''s Cardinal Sin dwells within the sanctified flesh of Hallow Wind''s first abbot, Cardinal Royce. Kill him, and the curse will die with him.', 12, 0, 100, 0, 0, 0, 0, 0, 'Maiden - The Three Sisters'' Wisdom turned in'),
(164589, 1, 0, 'Carden''s Cardinal Sin dwells within the sanctified flesh of Hallow Wind''s first abbot, Cardinal Royce. Kill him, and the curse will die with him.', 12, 0, 100, 0, 0, 0, 0, 0, 'Mother - The Three Sisters'' Wisdom turned in'),
(164590, 1, 0, 'Carden''s Cardinal Sin dwells within the sanctified flesh of Hallow Wind''s first abbot, Cardinal Royce. Kill him, and the curse will die with him.', 12, 0, 100, 0, 0, 0, 0, 0, 'Crone - The Three Sisters'' Wisdom turned in');
UPDATE `gameobject_template` SET `AIName` = 'SmartGameObjectAI' WHERE `entry` = 2300715;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 2300715 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300715, 1, 0, 0, 20, 0, 100, 0, 175203, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 10, 9920732, 164588, 0, 0, 0, 0, 0, 0, 'The Three Sisters - On The Three Sisters'' Wisdom rewarded - Maiden says line 1'),
(2300715, 1, 1, 0, 20, 0, 100, 0, 175203, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 10, 9920733, 164589, 0, 0, 0, 0, 0, 0, 'The Three Sisters - On The Three Sisters'' Wisdom rewarded - Mother says line 1'),
(2300715, 1, 2, 0, 20, 0, 100, 0, 175203, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 10, 9920731, 164590, 0, 0, 0, 0, 0, 0, 'The Three Sisters - On The Three Sisters'' Wisdom rewarded - Crone says line 1');
