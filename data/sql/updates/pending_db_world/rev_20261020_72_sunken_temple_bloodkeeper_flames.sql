-- Sunken Temple: each Hakkari Bloodkeeper the Shade of Hakkar summons counts toward the Avatar of Hakkar when it dies,
-- so the event needs no Hakkari Blood on the Eternal Flames, as on Ascension.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (148418, 148419, 148420, 148421) AND `source_type` = 1 AND `id` = 2;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 8438 AND `source_type` = 0 AND `id` = 4;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(8438, 0, 4, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 63, 1, 1, 0, 0, 0, 0, 19, 8440, 100, 0, 0, 0, 0, 0, 0, 'Hakkari Bloodkeeper - On Death - Set Counter 1 on Shade of Hakkar');
