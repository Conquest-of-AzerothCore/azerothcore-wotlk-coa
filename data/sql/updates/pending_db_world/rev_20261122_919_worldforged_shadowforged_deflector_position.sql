-- #12652: Worldforged pickup guid 6941054: the pickup stood 87 yd above Angor Fortress; restore the first-pass x/y
-- (row 6900639, 2026_09_16_00) with the ground height measured there (0.62 yd below the recorded z)
UPDATE `gameobject` SET `position_x` = -6312.594, `position_y` = -3093.305, `position_z` = 301.113
WHERE `guid` = 6941054 AND `id` = 518010 AND `map` = 0
  AND `position_x` BETWEEN -6319.19 AND -6319.09
  AND `position_y` BETWEEN -3097.23 AND -3097.13
  AND `position_z` BETWEEN 388.125 AND 388.225;
