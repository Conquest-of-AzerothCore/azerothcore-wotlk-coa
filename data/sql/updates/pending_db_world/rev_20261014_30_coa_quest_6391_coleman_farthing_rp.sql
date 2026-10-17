-- Brill: Coleman Farthing (1500) plays his turn-in RP for 'Deaths in the Family' (354) again (#6391).
--
-- creature_text 1500 groups 0/1 (broadcast 2631/2632) existed with nothing to trigger them. The rows below follow
-- TrinityCore 3.3.5 sql/old/3.3.5a/world/63_2018_02_19/2017_09_26_12_world_335.sql: on rewarding 354 he drops his
-- questgiver flag, yells line 0 after 1 s, says line 1 to the player 5 s later and restores the flag 4 s after that.
-- Entry scope (not guid 29801) so the gameplay fixture of 1500 runs the same script as the world spawn.
--
-- Idempotent: delete of the exact keys followed by the insert.

UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 1500;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 1500 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(1500, 0, 0, 0, 20, 0, 100, 0, 354, 0, 0, 0, 0, 0, 80, 150000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Coleman Farthing - On Quest \'Deaths in the Family\' Finished - Run Script');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 150000 AND `source_type` = 9;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(150000, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Coleman Farthing - On Script - Remove Npc Flag Questgiver'),
(150000, 9, 1, 0, 0, 0, 100, 0, 1000, 1000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Coleman Farthing - On Script - Say Line 0'),
(150000, 9, 2, 0, 0, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Coleman Farthing - On Script - Say Line 1'),
(150000, 9, 3, 0, 0, 0, 100, 0, 4000, 4000, 0, 0, 0, 0, 82, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Coleman Farthing - On Script - Add Npc Flag Questgiver');
