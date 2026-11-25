UPDATE `smart_scripts` SET `event_flags` = (`event_flags` & ~2) | 12,
    `comment` = 'Earthborer - In Combat - Cast Earthborer Acid (Heroic and Mythic)'
WHERE `entryorguid` = 11320 AND `source_type` = 0 AND `id` = 0 AND `action_type` = 11 AND `action_param1` = 18070;
