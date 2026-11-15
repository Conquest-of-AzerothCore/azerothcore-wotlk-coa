-- Uldaman: The Lost Dwarves (Baelog 6906, Eric "The Swift" 6907, Olaf 6908) carry faction template 122 (Ironforge),
-- hostile to the Horde and friendly to the Alliance, so an Alliance player in a mixed CoA group could not fight them
-- (#9641). Once a fight starts they turn on everyone (14) and take their own faction back when they evade (rows 20, 21);
-- the other rows are their current blocks unchanged.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 6906 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(6906, 0, 0, 0, 0, 0, 100, 16, 0, 0, 2300, 3900, 0, 0, 11, 15620, 64, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Baelog - In Combat - Cast Shoot'),
(6906, 0, 1, 0, 0, 0, 100, 16, 4000, 7000, 9000, 13000, 0, 0, 11, 14516, 1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Baelog - In Combat - Cast Strike'),
(6906, 0, 20, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Baelog - On Aggro - Set Faction Monster'),
(6906, 0, 21, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Baelog - On Evade - Restore Faction'),
(6906, 0, 9000, 0, 0, 0, 100, 0, 1000, 1500, 2900, 3400, 0, 0, 11, 2100156, 64, 0, 0, 0, 0, 5, 0, 1, 0, 0, 0, 0, 0, 0, 'Baelog - Ascension kit - In Combat (first 1-1.5 s, then every 2.9-3.4 s) - Cast ''Shoot'''),
(6906, 0, 9001, 0, 0, 0, 100, 0, 4600, 5100, 5900, 6400, 0, 0, 11, 383936, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Baelog - Ascension kit - In Combat (first 4.6-5.1 s, then every 5.9-6.4 s) - Cast ''Strike''');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 6907 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(6907, 0, 0, 0, 0, 0, 100, 0, 0, 0, 7000, 9000, 0, 0, 11, 6268, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Eric "The Swift" - In Combat - Cast Rushing Charge'),
(6907, 0, 20, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Eric "The Swift" - On Aggro - Set Faction Monster'),
(6907, 0, 21, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Eric "The Swift" - On Evade - Restore Faction');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 6908 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(6908, 0, 0, 0, 0, 0, 100, 0, 3000, 5000, 8000, 11000, 0, 0, 11, 8242, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Olaf - In Combat - Cast Shield Slam'),
(6908, 0, 20, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Olaf - On Aggro - Set Faction Monster'),
(6908, 0, 21, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Olaf - On Evade - Restore Faction');
