-- #10061: Lord Alexei Barov's "In Combat - Cast Veil of Shadows" event used event_flags = 16
-- (SMART_EVENT_FLAG_DIFFICULTY_3), unreachable on a 3-mode (Normal/Heroic/Mythic) dungeon, so the cast
-- never fired on any difficulty. Clear the flag so the event is unrestricted again.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 10504 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(10504, 0, 0, 0, 25, 0, 100, 528, 0, 0, 0, 0, 0, 0, 11, 17467, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Lord Alexei Barov - On Reset - Cast Unholy Aura'),
(10504, 0, 1, 0, 0, 0, 100, 16, 3000, 12000, 14000, 21000, 0, 0, 11, 20294, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Lord Alexei Barov - In Combat - Cast Immolate'),
(10504, 0, 2, 0, 0, 0, 100, 0, 5000, 12000, 15000, 25000, 0, 0, 11, 17820, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Lord Alexei Barov - In Combat - Cast Veil of Shadows'),
(10504, 0, 3, 0, 6, 0, 100, 512, 0, 0, 0, 0, 0, 0, 34, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Lord Alexei Barov - On Death - Set Instance Data'),
(10504, 0, 9000, 0, 0, 0, 100, 0, 10000, 12000, 15000, 17000, 0, 0, 11, 2100252, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Lord Alexei Barov - Ascension kit - In Combat (first 10-12 s, then every 15-17 s) - Cast ''Veil of Shadow'''),
(10504, 0, 9001, 0, 0, 0, 100, 0, 10000, 12000, 10000, 11000, 0, 0, 11, 2100356, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Lord Alexei Barov - Ascension kit - In Combat (first 10-12 s, then every 10-11 s) - Cast ''Shadow Cleave'''),
(10504, 0, 9002, 0, 0, 0, 100, 0, 8000, 10000, 8000, 9000, 0, 0, 218, 975011, 2, 200, 0, 0, 0, 2, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Lord Alexei Barov - Ascension kit - In Combat (first 8-10 s, then every 8-9 s) - Custom Cast ''Fierce Blow'' (200)');
