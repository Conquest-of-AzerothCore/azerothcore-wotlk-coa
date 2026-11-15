-- Worldforged Demon Kickers (pickup 6940355, Blasted Lands) stood 0.87 yd under the ground the server measures
-- at its x/y, inside the ruined ballista model (#11652).
-- Raise it to the measured ground height, z 8.594.
UPDATE `gameobject` SET `position_z` = 8.594
WHERE `guid` = 6940355 AND `id` = 96210 AND `map` = 0
  AND `position_x` BETWEEN -11798.11 AND -11798.09
  AND `position_y` BETWEEN -2724.41 AND -2724.39
  AND `position_z` BETWEEN 7.71 AND 7.73;
