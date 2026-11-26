-- Rosebud Ring (Ring of Druidic Whispers, entry 90389, guid 6942102, Ashenvale) was moved by
-- 2026_09_23_05_worldforged_map.sql from realm-dump row 6900940 (2781.930, -1550.850, 263.640;
-- flat 0.6 deg ground beside Kalidartreestump02.m2) to the 2-digit map pin
-- (2788.900, -1529.000, 282.281), 18.64 yd higher up a 71.6 deg cliff face where players cannot
-- reach it (#13242). Restore the first-pass realm-dump coordinates from
-- 2026_09_16_00_worldforged_pickups.sql:4190.
UPDATE `gameobject`
SET `position_x` = 2781.930,
    `position_y` = -1550.850,
    `position_z` = 263.640
WHERE `guid` = 6942102 AND `id` = 90389;
