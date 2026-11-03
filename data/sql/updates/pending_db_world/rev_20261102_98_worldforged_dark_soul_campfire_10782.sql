-- Worldforged The Dark Soul (#10782): gameobject guid 6941212 (entry 95822) stood 0.56 yd from the stock Roaring Fire
-- guid 14074 and inside its model. Move it 1.7 yd from the fire, directly away from it, onto the measured ground.
UPDATE `gameobject` SET `position_x` = -10445.09, `position_y` = -810.27, `position_z` = 50.46
 WHERE `guid` = 6941212 AND `id` = 95822 AND `map` = 0
   AND `position_x` BETWEEN -10446.2 AND -10446 AND `position_y` BETWEEN -809.85 AND -809.65
   AND ABS(`position_z` - 50.461) < 0.01;
