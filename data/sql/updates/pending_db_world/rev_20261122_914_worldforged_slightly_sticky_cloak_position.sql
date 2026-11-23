-- #12458: Worldforged pickup guid 6942203: the pickup lay 1.08 yd under the ground; restore the first-pass x/y (row
-- 6901456, 2026_09_16_00), where the same height is on the ground
UPDATE `gameobject` SET `position_x` = -6846.32, `position_y` = -1250.34, `position_z` = -273.395
WHERE `guid` = 6942203 AND `id` = 96222 AND `map` = 1
  AND `position_x` BETWEEN -6854.15 AND -6854.05
  AND `position_y` BETWEEN -1242.55 AND -1242.45
  AND `position_z` BETWEEN -273.445 AND -273.345;
