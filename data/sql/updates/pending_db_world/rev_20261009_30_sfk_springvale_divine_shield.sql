-- Shadowfang Keep: Commander Springvale casts Divine Shield once, at 33 % health, instead of every
-- 20-22 seconds.
UPDATE `smart_scripts` SET `event_type` = 2, `event_flags` = 1, `event_param1` = 0, `event_param2` = 33,
    `event_param3` = 0, `event_param4` = 0,
    `comment` = 'Commander Springvale - Ascension kit - Between 0-33% Health - Cast ''Divine Shield'' (No Repeat)'
WHERE `entryorguid` = 4278 AND `source_type` = 0 AND `id` = 9004;
