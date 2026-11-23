-- #13096: Worldforged pickup guid 6941263: the pickup floated 1.09 yd above the ground (measured spawn_ground_gap);
-- lower it to the ground
UPDATE `gameobject` SET `position_z` = 279.375
WHERE `guid` = 6941263 AND `id` = 518051 AND `map` = 0
  AND `position_x` BETWEEN -6605.150 AND -6605.050
  AND `position_y` BETWEEN -3418.750 AND -3418.650
  AND `position_z` BETWEEN 280.410 AND 280.510;
