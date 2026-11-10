-- Worldforged Ring of Accurate Endeavors pickup (guid 6940963) was 1.85 yd under the terrain at the reported map spot (#10155).
-- Raise it onto the ground.
UPDATE `gameobject` SET `position_z` = 10.456
WHERE `guid` = 6940963 AND `id` = 254343
  AND `position_x` BETWEEN -14220.8 AND -14220.6 AND `position_y` BETWEEN 124.7 AND 124.9
  AND ABS(`position_z` - 8.61) < 0.01;
