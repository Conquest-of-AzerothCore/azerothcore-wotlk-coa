-- Worldforged Gloves of Patience (pickup 6941777, entry 254292, Desolace, #10469):
-- 2026_09_23_05_worldforged_map.sql replaced the first-pass realm-dump coordinates (6900082) with the
-- 2-digit Y sidekick pin (0.6092, 0.69 -> -1615.900, 1491.100), shifting the pickup 19.5 yd south,
-- and rev_20261105_67 (#11231) only lifted position_z at that wrong X/Y. Restore the authoritative
-- first-pass realm-dump coordinates (-1619.320, 1510.320, 57.310).
UPDATE `gameobject`
SET `position_x` = -1619.320, `position_y` = 1510.320, `position_z` = 57.310
WHERE `guid` = 6941777 AND `id` = 254292 AND `map` = 1
  AND `position_x` BETWEEN -1616.0 AND -1615.8
  AND `position_y` BETWEEN 1491.0 AND 1491.2;
