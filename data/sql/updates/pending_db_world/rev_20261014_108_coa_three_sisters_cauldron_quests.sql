-- At the Three Sisters' cauldron: "The Three Sisters' Wisdom" is handed in to the cauldron, whereupon Maiden, Mother and
-- Crone each tell where Carden's curse lives, and "Cardinal Sin" is then picked up from (and later handed back to) the
-- cauldron (gameplay video youtu.be/4sr1-RP6DhI?t=74 and the user's screenshots).
DELETE FROM `gameobject_questender` WHERE `id` = 2300801 AND `quest` = 175203;
INSERT INTO `gameobject_questender` (`id`, `quest`) VALUES
(2300801, 175203);
DELETE FROM `gameobject_queststarter` WHERE `id` = 2300801 AND `quest` = 175204;
INSERT INTO `gameobject_queststarter` (`id`, `quest`) VALUES
(2300801, 175204);

DELETE FROM `creature_text` WHERE `CreatureID` IN (164588, 164589, 164767) AND `GroupID` = 0;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(164588, 0, 0, 'Carden''s Cardinal Sin dwells within the sanctified flesh of Hallow Wind''s first abbot, Cardinal Royce. Kill him, and the curse will die with him.', 12, 0, 100, 0, 0, 0, 0, 0, 'Maiden - The Three Sisters'' Wisdom handed in'),
(164589, 0, 0, 'Carden''s Cardinal Sin dwells within the sanctified flesh of Hallow Wind''s first abbot, Cardinal Royce. Kill him, and the curse will die with him.', 12, 0, 100, 0, 0, 0, 0, 0, 'Mother - The Three Sisters'' Wisdom handed in'),
(164767, 0, 0, 'Carden''s Cardinal Sin dwells within the sanctified flesh of Hallow Wind''s first abbot, Cardinal Royce. Kill him, and the curse will die with him.', 12, 0, 100, 0, 0, 0, 0, 0, 'Crone - The Three Sisters'' Wisdom handed in');

UPDATE `gameobject_template` SET `AIName` = 'SmartGameObjectAI' WHERE `entry` = 2300801;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 2300801 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300801, 1, 0, 0, 20, 0, 100, 0, 175203, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 10, 9920732, 164588, 0, 0, 0, 0, 0, 0, 'The Three Sisters - On Quest ''The Three Sisters'' Wisdom'' Rewarded - Maiden Says Line 0'),
(2300801, 1, 1, 0, 20, 0, 100, 0, 175203, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 10, 9920733, 164589, 0, 0, 0, 0, 0, 0, 'The Three Sisters - On Quest ''The Three Sisters'' Wisdom'' Rewarded - Mother Says Line 0'),
(2300801, 1, 2, 0, 20, 0, 100, 0, 175203, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 10, 9920731, 164767, 0, 0, 0, 0, 0, 0, 'The Three Sisters - On Quest ''The Three Sisters'' Wisdom'' Rewarded - Crone Says Line 0');
