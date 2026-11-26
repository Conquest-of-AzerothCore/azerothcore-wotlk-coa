-- Bloodscalp Skullpiercer (#9984): 2026_09_23_05_worldforged_map.sql placed guid 6940154
-- (entry 95739, Bloodscalp Bow, item 415084) from the rounded 2-digit sidekick pin (0.25, 0.10)
-- at (-11592.1, 626.3, 50.549), 15.0 yd SW and 11.34 yd below the Bloodscalp camp. Restore the
-- authoritative first-pass realm-dump coordinates from 2026_09_16_00_worldforged_pickups.sql
-- (row 6901162: -11582.900, 638.158, 61.889) on Barrel02.m2 at camp level.

UPDATE `gameobject`
SET `position_x` = -11582.900, `position_y` = 638.158, `position_z` = 61.889
WHERE `guid` = 6940154 AND `id` = 95739 AND `map` = 0;
