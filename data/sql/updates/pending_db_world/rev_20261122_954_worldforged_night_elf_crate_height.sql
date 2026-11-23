-- #13273: Worldforged pickup guid 6941757: the pickup floated 1.56 yd above the ground (measured spawn_ground_gap);
-- lower it to the ground
UPDATE `gameobject` SET `position_z` = 806.921
WHERE `guid` = 6941757 AND `id` = 518580 AND `map` = 1
  AND `position_x` BETWEEN 5693.150 AND 5693.250
  AND `position_y` BETWEEN -5002.050 AND -5001.950
  AND `position_z` BETWEEN 808.435 AND 808.535;
