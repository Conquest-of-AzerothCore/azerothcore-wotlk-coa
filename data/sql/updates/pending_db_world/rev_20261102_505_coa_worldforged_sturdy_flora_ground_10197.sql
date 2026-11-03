-- Worldforged Sturdy Flora (Darkshore, guid 6941700) was 4.02 yd under the terrain with open sky above (#10197).
-- Raise it onto the ground.
UPDATE `gameobject` SET `position_z` = 38.83333
WHERE `guid` = 6941700 AND `id` = 515408 AND `map` = 1
  AND `position_x` BETWEEN 7983.5 AND 7983.7 AND `position_y` BETWEEN -1171.9 AND -1171.7
  AND ABS(`position_z` - 34.814) < 0.01;
