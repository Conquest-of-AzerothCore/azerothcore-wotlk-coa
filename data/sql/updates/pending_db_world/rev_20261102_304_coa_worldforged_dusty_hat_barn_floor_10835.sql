-- Worldforged Dusty Hat (guid 6940395) was pinned to the terrain under its Alterac barn, 0.71 yd below the barn floor
-- and under it (#10835). Set it on the floor height measured by the harness at its position.
UPDATE `gameobject` SET `position_z` = 43.32
WHERE `guid` = 6940395 AND `id` = 95538 AND `map` = 0
  AND `position_x` BETWEEN 418.4 AND 418.6
  AND `position_y` BETWEEN 280.2 AND 280.4
  AND ABS(`position_z` - 42.6105) < 0.01;
