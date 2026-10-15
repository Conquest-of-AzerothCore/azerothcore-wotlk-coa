-- Brainless Stablemaster 161755 (An Unspeakable Secret 1660026) yells CoA's line when he is engaged (CoA footage,
-- transcribed by the playtester). SmartAI on AGGRO (4), say (12).
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 161755;
DELETE FROM `creature_text` WHERE `CreatureID` = 161755;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Probability`, `comment`)
VALUES
(161755, 0, 0, 'Back to your stalls! Back! You''ll not escape the whip, beast or man alike!', 12, 100, 'Brainless Stablemaster - aggro (CoA footage)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 161755 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(161755, 0, 0, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Brainless Stablemaster - On Aggro - Say Line 0');
