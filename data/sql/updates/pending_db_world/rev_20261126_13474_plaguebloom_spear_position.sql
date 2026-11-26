-- Plaguebloom Spear (Encrusted Spear, entry 90532, guid 6940891, Eastern Plaguelands,
-- drops item 410154) was placed by 2026_09_23_05_worldforged_map.sql:943 at
-- (2782.000, -4556.500, 95.589), 938.7 yd north-east of its first-pass realm-dump row
-- 6900976 (1867.550, -4768.510, 114.497, Plaguelandstump02.m2) where LootCollector and
-- the reporter (33.08 yd away) look for it (#13474).
-- Restore the first-pass realm-dump coordinates from 2026_09_16_00_worldforged_pickups.sql:4226.
UPDATE `gameobject`
SET `position_x` = 1867.550,
    `position_y` = -4768.510,
    `position_z` = 114.497
WHERE `guid` = 6940891 AND `id` = 90532;
