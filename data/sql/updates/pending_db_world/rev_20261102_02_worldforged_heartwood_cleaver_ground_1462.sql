-- Worldforged Heartwood Cleaver (#1462): the pickup in lower Feralas by the fallen log (gameobject guid
-- 6941818, entry 96102, item 515146) floats 1.11 yd above the ground. Its X/Y is the recorded Ascension
-- find position (sidekick zone-122 pin 0.81/0.3967 converts through WorldMapArea bounds to world
-- -4204.3, -187.7), so only the height is wrong: the realm-map pass kept a z of 58.693. Measured with
-- spawn_ground_gap against the live map/vmap data; lower it onto the measured ground.
UPDATE `gameobject` SET `position_z` = 57.587
 WHERE `guid` = 6941818 AND `id` = 96102 AND `map` = 1
   AND `position_x` BETWEEN -4205.3 AND -4203.3 AND `position_y` BETWEEN -188.7 AND -186.7
   AND ABS(`position_z` - 58.693) < 0.01;
