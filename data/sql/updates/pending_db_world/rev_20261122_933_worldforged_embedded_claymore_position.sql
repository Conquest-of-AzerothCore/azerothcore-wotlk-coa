-- #13023: Worldforged pickup guid 6941438: the pickup lay on the road under the overhead log (7.46 yd headroom);
-- restore the first-pass x/y (row 6900605, 2026_09_16_00) on the log, 0.91 yd below the first-pass z that floated in
-- #10464
UPDATE `gameobject` SET `position_x` = 6070.41, `position_y` = -716.721, `position_z` = 414.903
WHERE `guid` = 6941438 AND `id` = 517276 AND `map` = 1
  AND `position_x` BETWEEN 6070.850 AND 6070.950
  AND `position_y` BETWEEN -715.550 AND -715.450
  AND `position_z` BETWEEN 397.339 AND 397.439;
