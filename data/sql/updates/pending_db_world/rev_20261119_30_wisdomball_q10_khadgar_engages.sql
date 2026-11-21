DELETE FROM `smart_scripts` WHERE `entryorguid` = 9417004 AND `source_type` = 0 AND `id` = 21;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(9417004, 0, 21, 0, 17, 1, 100, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 'Khadgar (Escort) - Escorting, summoned an ambush mob - Attack it at once');
UPDATE `smart_scripts` SET `event_param1` = 0, `event_param2` = 500 WHERE `entryorguid` = 9417004 AND `source_type` = 0 AND `id` = 17;
UPDATE `smart_scripts` SET `event_param1` = 4000, `event_param2` = 5000 WHERE `entryorguid` = 9417004 AND `source_type` = 0 AND `id` = 18;
