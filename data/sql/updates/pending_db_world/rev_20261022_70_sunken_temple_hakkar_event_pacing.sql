-- Sunken Temple: the Avatar of Hakkar event no longer uses Hakkari Blood, so Hakkari Bloodkeepers stop dropping it,
-- the Shade of Hakkar sends a Bloodkeeper every 30 seconds instead of about every 55, and the Avatar of Hakkar waits
-- 10 seconds after it appears before it attacks.
DELETE FROM `creature_loot_template` WHERE `Entry` = 8438 AND `Item` = 10460;

UPDATE `smart_scripts` SET `event_param1` = 15000, `event_param2` = 15000, `event_param3` = 60000, `event_param4` = 60000 WHERE `entryorguid` = 8440 AND `source_type` = 0 AND `id` = 19;
UPDATE `smart_scripts` SET `event_param1` = 45000, `event_param2` = 45000, `event_param3` = 60000, `event_param4` = 60000 WHERE `entryorguid` = 8440 AND `source_type` = 0 AND `id` = 20;

UPDATE `smart_scripts` SET `event_param1` = 10000, `event_param2` = 10000 WHERE `entryorguid` = 8443 AND `source_type` = 0 AND `id` = 2;
UPDATE `smart_scripts` SET `event_param1` = 20000, `event_param2` = 20000 WHERE `entryorguid` = 8443 AND `source_type` = 0 AND `id` = 0;
