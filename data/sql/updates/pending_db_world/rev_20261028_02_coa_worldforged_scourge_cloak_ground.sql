-- Worldforged Scourge Cloak (#8741): the Eastern Plaguelands pickup (gameobject guid 6941032,
-- entry 90617) stood 0.29 yd under the stock terrain at its spawn XY (confirmed with the
-- gameplay harness's own ground probe: spawn_ground_gap -0.289764, terrain 128.070). Raise it
-- onto the ground; XY and orientation are unchanged.

UPDATE `gameobject`
SET `position_z` = 128.07
WHERE `guid` = 6941032 AND `id` = 90617 AND `map` = 0 AND `position_z` BETWEEN 127.7 AND 127.9;
