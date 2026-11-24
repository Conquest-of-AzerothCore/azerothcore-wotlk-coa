-- #13234: Worldforged pickup guid 6941879: the pickup floated 3.04 yd above the floor of Shadow Hold (measured
-- spawn_ground_gap); lower it to the floor
UPDATE `gameobject` SET `position_z` = 297.801
WHERE `guid` = 6941879 AND `id` = 517237 AND `map` = 1
  AND `position_x` BETWEEN 5048.150 AND 5048.250
  AND `position_y` BETWEEN -539.050 AND -538.950
  AND `position_z` BETWEEN 300.790 AND 300.890;
