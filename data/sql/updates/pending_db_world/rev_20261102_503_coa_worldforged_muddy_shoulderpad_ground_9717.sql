-- Worldforged Muddy Shoulderpad (Loch Modan, guid 6941202) was 0.87 yd under the slope, leaving only its glint
-- visible (#9717). Raise it onto the terrain.
UPDATE `gameobject` SET `position_z` = 299.99711
WHERE `guid` = 6941202 AND `id` = 517338 AND `map` = 0
  AND `position_x` BETWEEN -5667.1 AND -5666.9 AND `position_y` BETWEEN -3292.9 AND -3292.7
  AND ABS(`position_z` - 299.128) < 0.01;
