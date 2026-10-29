-- Uldaman: The Lost Dwarves (Baelog 6906, Eric "The Swift" 6907, Olaf 6908) carry faction template 122 (Ironforge),
-- hostile to the Horde and friendly to the Alliance, so an Alliance player in a mixed CoA group could not fight them
-- (#9641). Once a fight starts they turn on everyone (14) and take their own faction back when they evade.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (6906, 6907, 6908) AND `source_type` = 0 AND `id` IN (20, 21);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(6906, 0, 20, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Baelog - On Aggro - Set Faction Monster'),
(6906, 0, 21, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Baelog - On Evade - Restore Faction'),
(6907, 0, 20, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Eric "The Swift" - On Aggro - Set Faction Monster'),
(6907, 0, 21, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Eric "The Swift" - On Evade - Restore Faction'),
(6908, 0, 20, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Olaf - On Aggro - Set Faction Monster'),
(6908, 0, 21, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Olaf - On Evade - Restore Faction');
