-- #12773: Worldforged pickup guid 6940624: the pickup floated 1.92 yd above the ground (measured spawn_ground_gap);
-- lower it to the ground
UPDATE `gameobject` SET `position_z` = 122.071
WHERE `guid` = 6940624 AND `id` = 95889 AND `map` = 0
  AND `position_x` BETWEEN -22.35 AND -22.25
  AND `position_y` BETWEEN -2807.05 AND -2806.95
  AND `position_z` BETWEEN 123.94 AND 124.04;
