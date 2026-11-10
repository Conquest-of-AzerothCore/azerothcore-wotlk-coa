-- Iron Deposit 12020892 (Thousand Needles) stood on rock at z 20.17 over a cave whose floor under it is z 15.20 (#9838).
UPDATE `gameobject` SET `position_z` = 15.2026
WHERE `guid` = 12020892 AND `id` = 1735 AND `map` = 1
  AND `position_x` BETWEEN -5611.98 AND -5611.96 AND `position_y` BETWEEN -1612.21 AND -1612.19
  AND ABS(`position_z` - 20.17) < 0.01;
