-- Watcher's Mantle (entry 515750, guid 6942407, Tanaris) was moved by
-- 2026_09_23_05_worldforged_map.sql 5.03 yd south-west from realm-dump row 6900504
-- (-9622.309, -2828.916, 11.903; +0.005 yd above .map terrain 11.899) to
-- (-9623.500, -2833.800, 11.903), where .map terrain is 13.688 (-1.785 yd underground) (#13433).
-- Restore the first-pass realm-dump coordinates from 2026_09_16_00_worldforged_pickups.sql:3748.
UPDATE `gameobject`
SET `position_x` = -9622.309,
    `position_y` = -2828.916,
    `position_z` = 11.903
WHERE `guid` = 6942407 AND `id` = 515750;
