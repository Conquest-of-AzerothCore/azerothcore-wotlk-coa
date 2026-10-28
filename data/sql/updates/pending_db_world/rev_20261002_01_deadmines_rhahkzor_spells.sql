-- Rhahk\'Zor (644): drop the vanilla Slam and add the Ascension Fierce Blow, Stunning Strike and Bladestorm
DELETE FROM `smart_scripts` WHERE `entryorguid` = 644 AND `source_type` = 0 AND `id` IN (1, 4, 5, 6);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(644, 0, 4, 0, 0, 0, 100, 0, 8400, 8400, 7800, 7800, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Rhahk\'Zor - In Combat - Cast Fierce Blow'),
(644, 0, 5, 0, 0, 0, 100, 0, 12000, 16000, 15000, 20000, 0, 0, 11, 2102553, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Rhahk\'Zor - In Combat - Cast Stunning Strike'),
(644, 0, 6, 0, 0, 0, 100, 0, 8000, 10000, 15000, 20000, 0, 0, 11, 2102554, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Rhahk\'Zor - In Combat - Cast Bladestorm');
