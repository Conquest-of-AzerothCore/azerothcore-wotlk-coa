-- Handros gives Smoke on the Horizon (1660066) after Death and Justice (1660033), wears plains leather (Morin
-- Cloudstalker's display) in place of black plate, and sends the player up to the Iris Sanctuary on accepting it.
UPDATE `quest_template_addon` SET `PrevQuestID` = 1660033 WHERE `ID` = 1660066;

UPDATE `creature_template_model` SET `CreatureDisplayID` = 1624 WHERE `CreatureID` = 162902 AND `Idx` = 0;

DELETE FROM `creature_text` WHERE `CreatureID` = 162902;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(162902, 0, 0, 'Catch your breath and steel yourself before you climb to the Iris Sanctuary. The ascent can be... unforgiving.', 12, 0, 100, 0, 0, 0, 0, 0, 'Handros - Smoke on the Horizon accepted');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 162902 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(162902, 0, 0, 0, 19, 0, 100, 0, 1660066, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Handros - On Quest Smoke on the Horizon Accepted - Say Line 0');

UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 162902;
