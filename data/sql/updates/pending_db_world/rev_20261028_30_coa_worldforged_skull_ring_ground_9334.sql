-- Worldforged Skull Ring (Durotar, guid 6942195) stands 3.44 yd under the terrain at its realm-map spot;
-- restore it to the terrain height so the chest is on the ground, not buried (#9334).
UPDATE `gameobject` SET `position_z` = 27.36
WHERE `guid` = 6942195 AND `id` = 95645 AND `map` = 1
  AND `position_x` BETWEEN 1349.4 AND 1350.4 AND `position_y` BETWEEN -4606.5 AND -4605.5
  AND ABS(`position_z` - 23.925) < 0.01;
