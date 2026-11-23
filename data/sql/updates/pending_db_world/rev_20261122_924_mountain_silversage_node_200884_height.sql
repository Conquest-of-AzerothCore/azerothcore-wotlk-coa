-- #12188: Mountain Silversage node guid 200884: the herb node floated 24.97 yd above the ground (measured
-- spawn_ground_gap); lower it to the ground
UPDATE `gameobject` SET `position_z` = 85.972
WHERE `guid` = 200884 AND `id` = 176586 AND `map` = 0
  AND `position_x` BETWEEN 1507.14 AND 1507.24
  AND `position_y` BETWEEN -5424.63 AND -5424.53
  AND `position_z` BETWEEN 110.89 AND 110.99;
