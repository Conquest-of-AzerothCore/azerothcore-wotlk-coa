-- #12563: Worldforged pickup guid 6941951: the pickup lay 7.73 yd under the ground; restore the first-pass x/y (row
-- 6900210, 2026_09_16_00), where the same height is on the ground
UPDATE `gameobject` SET `position_x` = 3768.64, `position_y` = -5296.82, `position_z` = 84.636
WHERE `guid` = 6941951 AND `id` = 254458 AND `map` = 1
  AND `position_x` BETWEEN 3768.75 AND 3768.85
  AND `position_y` BETWEEN -5305.05 AND -5304.95
  AND `position_z` BETWEEN 84.586 AND 84.686;
