-- #13417: the Sparkshard Necklace pickup sat inside the Eastern Crystal Pylon, 0.88 yd under the terrain.
-- Restore the x/y of first-pass row 6901422 (2026_09_16_00, the realm dump spot); the height is kept.
UPDATE `gameobject` SET `position_x` = -7198.7, `position_y` = -2324.69
WHERE `guid` = 6942222 AND `id` = 96188 AND `map` = 1
  AND `position_x` BETWEEN -7199.550 AND -7199.450 AND `position_y` BETWEEN -2321.950 AND -2321.850 AND `position_z` BETWEEN -227.608 AND -227.508;
