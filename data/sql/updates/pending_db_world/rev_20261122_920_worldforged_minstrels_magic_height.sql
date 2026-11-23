-- #12716: Worldforged pickup guid 6941957 lay 1.88 yd under the ground (measured spawn_ground_gap) and its first-pass
-- spot (row 6900587, 2026_09_16_00) is under water; raise it to the ground at its current x/y
UPDATE `gameobject` SET `position_z` = 256.537
WHERE `guid` = 6941957 AND `id` = 517223 AND `map` = 1
  AND `position_x` BETWEEN 4141.65 AND 4141.75
  AND `position_y` BETWEEN -836.25 AND -836.15
  AND `position_z` BETWEEN 254.608 AND 254.708;
