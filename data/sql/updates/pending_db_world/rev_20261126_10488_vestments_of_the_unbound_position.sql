-- Worldforged Vestments of the Unbound (pickup 6941300, entry 387852, Wetlands, #10488):
-- 2026_09_23_05_worldforged_map.sql replaced the first-pass realm-dump coordinates (6900377) with the
-- 2-digit sidekick pin (0.48, 0.26 -> -2863.800, -2374.300), shifting the pickup 3.78 yd north into
-- the Wetlands Mercenary Camp building. Restore the authoritative first-pass realm-dump coordinates.
UPDATE `gameobject`
SET `position_x` = -2863.744, `position_y` = -2378.078, `position_z` = 36.725
WHERE `guid` = 6941300 AND `id` = 387852 AND `map` = 0
  AND `position_x` BETWEEN -2863.9 AND -2863.7
  AND `position_y` BETWEEN -2374.4 AND -2374.2;
