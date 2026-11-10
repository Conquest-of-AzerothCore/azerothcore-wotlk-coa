-- Worldforged Carefully Folded Cloak (#8721): the pickup in The Hinterlands (gameobject guid 6941113,
-- entry 95898) stands 1.94 yd above the ground at its spawn XY (spawn_ground_gap). Lower it onto that
-- ground; XY, orientation and size are unchanged.
UPDATE `gameobject` SET `position_z` = 118.683
WHERE `guid` = 6941113 AND `id` = 95898 AND `map` = 0
  AND `position_x` BETWEEN 464.8 AND 465.8 AND `position_y` BETWEEN -3616.0 AND -3615.0
  AND ABS(`position_z` - 120.626) < 0.01;
