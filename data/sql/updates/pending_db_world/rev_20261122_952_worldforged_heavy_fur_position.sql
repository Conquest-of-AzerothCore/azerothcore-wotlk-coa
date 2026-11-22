-- #13246: Worldforged pickup guid 6942437: the pickup sat in a Starfall Village doorway, 0.31 yd under the floor with
-- 0.01 yd headroom (measured); restore the first-pass position (row 6900676, 2026_09_16_00), which is grounded
UPDATE `gameobject` SET `position_x` = 7247.735, `position_y` = -4054.9
WHERE `guid` = 6942437 AND `id` = 518175 AND `map` = 1
  AND `position_x` BETWEEN 7247.950 AND 7248.050
  AND `position_y` BETWEEN -4062.750 AND -4062.650
  AND `position_z` BETWEEN 715.187 AND 715.287;
