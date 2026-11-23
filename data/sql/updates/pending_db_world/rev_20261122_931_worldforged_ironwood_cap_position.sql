-- #12906: Worldforged pickup guid 6941874: the pickup was under a liquid surface; restore the first-pass x/y (row
-- 6900599, 2026_09_16_00) with the ground height measured there (1.92 yd below the first-pass z)
UPDATE `gameobject` SET `position_x` = 6173.81, `position_y` = -1157.53, `position_z` = 368.331
WHERE `guid` = 6941874 AND `id` = 517263 AND `map` = 1
  AND `position_x` BETWEEN 6170.450 AND 6170.550
  AND `position_y` BETWEEN -1165.150 AND -1165.050
  AND `position_z` BETWEEN 367.728 AND 367.828;
