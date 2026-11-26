-- #13056: Worldforged pickup guid 6942126: the pickup floated 1.30 yd above the ground (measured spawn_ground_gap);
-- restore the first-pass position (row 6900557, 2026_09_16_00), which is grounded
UPDATE `gameobject` SET `position_x` = -8053.58, `position_y` = -3925.17
WHERE `guid` = 6942126 AND `id` = 515901 AND `map` = 1
  AND `position_x` BETWEEN -8041.650 AND -8041.550
  AND `position_y` BETWEEN -3939.250 AND -3939.150
  AND `position_z` BETWEEN 10.310 AND 10.410;
