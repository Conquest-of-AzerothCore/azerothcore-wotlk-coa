-- #12240: Worldforged pickup guid 6940427: the pickup stood inside the castle wall (no ground under it); restore the
-- first-pass x/y (row 6900104, 2026_09_16_00) with the floor height measured there (2.01 yd below the old z)
UPDATE `gameobject` SET `position_x` = 477.037, `position_y` = -218.922, `position_z` = 145.367
WHERE `guid` = 6940427 AND `id` = 254318 AND `map` = 0
  AND `position_x` BETWEEN 475.15 AND 475.25
  AND `position_y` BETWEEN -221.85 AND -221.75
  AND `position_z` BETWEEN 147.326 AND 147.426;
