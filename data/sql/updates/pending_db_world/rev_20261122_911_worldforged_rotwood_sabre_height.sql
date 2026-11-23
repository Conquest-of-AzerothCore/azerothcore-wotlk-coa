-- #12284: Worldforged pickup guid 6942104: the pickup floated 2.62 yd above the ground (measured spawn_ground_gap);
-- lower it to the ground
UPDATE `gameobject` SET `position_z` = 474.832
WHERE `guid` = 6942104 AND `id` = 517277 AND `map` = 1
  AND `position_x` BETWEEN 6570.25 AND 6570.35
  AND `position_y` BETWEEN -834.55 AND -834.45
  AND `position_z` BETWEEN 477.405 AND 477.505;
