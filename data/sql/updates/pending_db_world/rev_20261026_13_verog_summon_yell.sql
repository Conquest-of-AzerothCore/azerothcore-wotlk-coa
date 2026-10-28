-- COA-7214: Verog the Dervish (3395) is summoned by the Kolkar centaurs' SmartAI (3274, 3275, 3397), but his
-- "I am summoned!" line was on SMART_EVENT_RESPAWN (11), which a summoned creature never raises. Use
-- SMART_EVENT_JUST_SUMMONED (54) instead.
UPDATE `smart_scripts` SET `event_type` = 54, `comment` = 'Verog the Dervish - On Just Summoned - Say Line 0 (No Repeat)'
WHERE `entryorguid` = 3395 AND `source_type` = 0 AND `id` = 2;
