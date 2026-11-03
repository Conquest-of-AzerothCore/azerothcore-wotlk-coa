-- Floodworn Shoulderguards pickup (guid 6940491, Hinterlands) was 1.31 yd under the ground at its spot (#9706).
UPDATE `gameobject` SET `position_z` = 100.943
WHERE `guid` = 6940491 AND `id` = 95894 AND `map` = 0
  AND `position_x` BETWEEN -52.61 AND -52.59 AND `position_y` BETWEEN -3179.71 AND -3179.69
  AND ABS(`position_z` - 99.633) < 0.01;
