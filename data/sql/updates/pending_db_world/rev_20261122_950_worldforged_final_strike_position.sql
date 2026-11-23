-- #13150: Worldforged pickup guid 6941213: the pickup floated 1.85 yd above the ground (measured spawn_ground_gap);
-- restore the first-pass x/y (row 6900794, 2026_09_16_00) on the altar, with the altar top measured there (1.01 yd
-- below the first-pass z)
UPDATE `gameobject` SET `position_x` = -7673.34, `position_y` = -2209.26, `position_z` = 152.514
WHERE `guid` = 6941213 AND `id` = 686914 AND `map` = 0
  AND `position_x` BETWEEN -7675.050 AND -7674.950
  AND `position_y` BETWEEN -2207.050 AND -2206.950
  AND `position_z` BETWEEN 153.479 AND 153.579;
