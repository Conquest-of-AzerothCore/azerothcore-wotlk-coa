-- Brainless Majordomo 161753 (An Unspeakable Secret 1660026), from CoA footage described by the playtester: a
-- Forsaken in plain brown everyday clothes who speaks when engaged. His CoA display is not in the client; he takes
-- the Forsaken Nicholas Atwood 2643 (brown shirt and trousers) (INFERRED). SmartAI on AGGRO (4), say (12).
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161753;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(161753, 0, 2643, 1, 1);
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 161753;
DELETE FROM `creature_text` WHERE `CreatureID` = 161753;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Probability`, `comment`)
VALUES
(161753, 0, 0, 'You... have not... been invited by Lord Cain!', 12, 100, 'Brainless Majordomo - aggro (CoA footage)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 161753 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(161753, 0, 0, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Brainless Majordomo - On Aggro - Say Line 0');
