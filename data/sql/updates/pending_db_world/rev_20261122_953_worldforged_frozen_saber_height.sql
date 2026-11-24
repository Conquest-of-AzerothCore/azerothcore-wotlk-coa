-- #13268: Worldforged pickup guid 6941754: the pickup floated 0.80 yd above the ice (measured spawn_ground_gap);
-- lower it to the ice
UPDATE `gameobject` SET `position_z` = 658.367
WHERE `guid` = 6941754 AND `id` = 518564 AND `map` = 1
  AND `position_x` BETWEEN 6554.050 AND 6554.150
  AND `position_y` BETWEEN -3998.150 AND -3998.050
  AND `position_z` BETWEEN 659.114 AND 659.214;
