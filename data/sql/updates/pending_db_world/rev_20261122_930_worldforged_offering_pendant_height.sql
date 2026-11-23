-- #12903: Worldforged pickup guid 6940816: the pickup sat 0.44 yd under the ground (measured spawn_ground_gap); raise
-- it to the ground
UPDATE `gameobject` SET `position_z` = 50.055
WHERE `guid` = 6940816 AND `id` = 1345101 AND `map` = 0
  AND `position_x` BETWEEN -922.650 AND -922.550
  AND `position_y` BETWEEN -3094.450 AND -3094.350
  AND `position_z` BETWEEN 49.565 AND 49.665;
