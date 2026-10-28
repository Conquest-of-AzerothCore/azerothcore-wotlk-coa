-- Restless Family Members 1660025: each relative speaks CoA's line when its remains summon it (CoA footage,
-- transcribed by the playtester). SmartAI on JUST_SUMMONED (54), say (12). Cousin Salem is a woman in CoA: the
-- female Spectral Citizen 10486 (grey cloth, translucent), the same Stratholme set as the male 10483 she had.
-- Mother is a ghost in civilian clothes too: the other female Spectral Citizen 10485, replacing the dark-robed
-- 11835 (playtest). CoA's own displays (652013-652015) are not in the client DBCs. Father keeps 3222 at player size:
-- 3222 draws at 1.2x, 11835 drew at 1.25x.
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` IN (161762, 161763, 161764, 161765);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161762, 161763, 161764);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(161762, 0, 10485, 1, 1),
(161763, 0, 3222, 0.8333, 1),
(161764, 0, 10486, 1, 1);
DELETE FROM `creature_text` WHERE `CreatureID` IN (161762, 161763, 161764, 161765);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Probability`, `comment`)
VALUES
(161762, 0, 0, 'The mansion lies in ruins.... overrun with monsters... My children... where are my children?', 12, 100, 'Mother - summoned (CoA footage)'),
(161763, 0, 0, 'My estate... my legacy.... all in ruins! Why can I not escape this torment?', 12, 100, 'Father - summoned (CoA footage)'),
(161764, 0, 0, 'I cannot find the Light. Only darkness. Only the fall. And I have no voice left to scream...', 12, 100, 'Cousin Salem - summoned (CoA footage)'),
(161765, 0, 0, 'I always knew... my niece would bring us to ruin. This must be her witchcraft!', 12, 100, 'Uncle Abel - summoned (CoA footage)');
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (161762, 161763, 161764, 161765) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(161762, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Mother - Just Summoned - Say Line 0'),
(161763, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Father - Just Summoned - Say Line 0'),
(161764, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Cousin Salem - Just Summoned - Say Line 0'),
(161765, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Uncle Abel - Just Summoned - Say Line 0');
