-- Grimtotem Marauders stand neutral, as players recall them on CoA, and sometimes call out when a fight begins; the
-- four lines are CoA's, as players recorded them. The Patrols stay hostile.
UPDATE `creature_template` SET `faction` = 7, `AIName` = 'SmartAI' WHERE `entry` = 161809;

DELETE FROM `creature_text` WHERE `CreatureID` = 161809;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Probability`, `comment`) VALUES
(161809, 0, 0, 'Another skull for Malgorm''s collection!', 12, 25, 'Grimtotem Marauder - aggro (CoA)'),
(161809, 0, 1, 'Let the weaker of us die!', 12, 25, 'Grimtotem Marauder - aggro (CoA)'),
(161809, 0, 2, 'Come! I''ll show you why the Grimtotem are the most feared of all tauren!', 12, 25, 'Grimtotem Marauder - aggro (CoA)'),
(161809, 0, 3, 'At last, a real challenge! I was growing tired of hunting mere beasts.', 12, 25, 'Grimtotem Marauder - aggro (CoA)');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 161809 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`,
    `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`,
    `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`,
    `target_o`, `comment`) VALUES
(161809, 0, 0, 0, 4, 0, 30, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Marauder - On Aggro - Say Line 0 (30%)');
