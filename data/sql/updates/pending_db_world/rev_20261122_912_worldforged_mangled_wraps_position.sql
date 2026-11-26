-- #12304: Worldforged pickup guid 6940741: the pickup lay 4.32 yd under the ground; restore the first-pass x/y (row
-- 6901145, 2026_09_16_00) with the ground height measured there (0.47 yd below the recorded z)
UPDATE `gameobject` SET `position_x` = -13668.127, `position_y` = 652.498, `position_z` = 1.662
WHERE `guid` = 6940741 AND `id` = 95722 AND `map` = 0
  AND `position_x` BETWEEN -13677.95 AND -13677.85
  AND `position_y` BETWEEN 624.95 AND 625.05
  AND `position_z` BETWEEN 2.082 AND 2.182;
