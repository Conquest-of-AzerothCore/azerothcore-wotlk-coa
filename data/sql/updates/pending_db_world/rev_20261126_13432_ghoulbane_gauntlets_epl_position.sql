-- Ghoulbane Gauntlets (Chainmail Gauntlets, entry 90508, guid 6940538, Eastern Plaguelands)
-- was moved by 2026_09_23_05_worldforged_map.sql from realm-dump row 6900966
-- (2544.780, -4524.810, 79.515; -0.011 yd to .map terrain 79.526) to the 2-digit map pin
-- (2548.200, -4544.400, 79.515), where .map terrain is 80.660 (-1.145 yd underground) (#13432).
-- Restore the first-pass realm-dump coordinates from 2026_09_16_00_worldforged_pickups.sql:4216.
UPDATE `gameobject`
SET `position_x` = 2544.780,
    `position_y` = -4524.810,
    `position_z` = 79.515
WHERE `guid` = 6940538 AND `id` = 90508;
