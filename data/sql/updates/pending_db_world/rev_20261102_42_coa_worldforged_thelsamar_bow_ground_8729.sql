-- Worldforged Thelsamar Bow (#8729): the pickup in the Wetlands (gameobject guid 6941227, entry 387872)
-- stands 1.12 yd above the ground at its spawn XY (spawn_ground_gap). Lower it onto that ground; XY and
-- orientation are unchanged.
UPDATE `gameobject` SET `position_z` = 10.676
WHERE `guid` = 6941227 AND `id` = 387872 AND `map` = 0
  AND `position_x` BETWEEN -3025.6 AND -3024.6 AND `position_y` BETWEEN -2409.1 AND -2408.1
  AND ABS(`position_z` - 11.799) < 0.01;
