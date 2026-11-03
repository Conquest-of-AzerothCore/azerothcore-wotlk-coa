-- Worldforged Thunder Hide Tailspike (#4810): gameobject guid 6942318 (entry 95624) in Durotar sat 1.521 yd
-- below the ground and clipped through it. Measured with spawn_ground_gap against the live map/vmap data;
-- raise it onto the measured ground.
UPDATE `gameobject` SET `position_z` = -6.073
 WHERE `guid` = 6942318 AND `id` = 95624 AND `map` = 1
   AND `position_x` BETWEEN 961.2 AND 963.2 AND `position_y` BETWEEN -4289.7 AND -4287.7
   AND ABS(`position_z` - -7.594) < 0.01;
