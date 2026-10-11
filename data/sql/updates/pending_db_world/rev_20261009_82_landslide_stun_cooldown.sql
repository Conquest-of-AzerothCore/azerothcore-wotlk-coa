-- Landslide (Maraudon): his Landslide (21808, an AoE stun) comes every 45 s instead of every 18-22 s.
UPDATE `smart_scripts` SET `event_param3` = 45000, `event_param4` = 45000
WHERE `entryorguid` = 12203 AND `source_type` = 0 AND `id` = 9004;
