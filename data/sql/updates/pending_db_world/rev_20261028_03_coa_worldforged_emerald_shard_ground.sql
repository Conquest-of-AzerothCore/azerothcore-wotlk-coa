-- Worldforged Emerald Shard (#8761): a Duskwood map-editor pass sank the neck pickup
-- (gameobject guid 6940431, entry 90290) 0.48 yd under the stock terrain at its spawn XY
-- (confirmed with the gameplay harness's own ground probe: spawn_ground_gap -0.478962, terrain
-- 50.600). Raise it onto the ground; XY and orientation are unchanged.

UPDATE `gameobject`
SET `position_z` = 50.6
WHERE `guid` = 6940431 AND `id` = 90290 AND `map` = 0
  AND `position_x` BETWEEN -10867.2 AND -10866.2 AND `position_y` BETWEEN -427.5 AND -426.5;
