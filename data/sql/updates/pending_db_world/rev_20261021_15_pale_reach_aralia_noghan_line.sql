-- Aralia Dolmen (164044) grieves aloud once Senseless Death, Shattered Hearts (175040) is turned in, as on the realm.
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 164044;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 164044 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164044, 0, 0, 0, 20, 0, 100, 0, 175040, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Aralia Dolmen - On Quest Senseless Death, Shattered Hearts Rewarded - Say Line 0');

DELETE FROM `creature_text` WHERE `CreatureID` = 164044;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(164044, 0, 0, 'Oh, Noghan. It is almost for the best that you did not live to see the day one son died at the hands of the other.', 12, 0, 100, 0, 0, 0, 0, 0, 'Aralia Dolmen - after Senseless Death, Shattered Hearts');
