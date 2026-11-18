UPDATE `smart_scripts` SET `event_type` = 2, `event_flags` = 1, `event_param1` = 0, `event_param2` = 50, `event_param3` = 0, `event_param4` = 0,
    `comment` = 'Charlga Razorflank - Ascension kit - Between 0-50% Health - Cast ''Lightning Nova'' (No Repeat)'
WHERE `entryorguid` = 4421 AND `source_type` = 0 AND `id` = 9003 AND `action_type` = 11 AND `action_param1` = 2102774;
