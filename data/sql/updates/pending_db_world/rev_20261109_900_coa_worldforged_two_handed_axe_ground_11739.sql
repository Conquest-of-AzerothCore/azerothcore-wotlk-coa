-- Worldforged Two-Handed Axe (pickup 6940260, Searing Gorge) floated 1.02 yd above the ground the server measures
-- at its x/y (#11739).
-- Lower it to the measured ground height, z 240.010.
UPDATE `gameobject` SET `position_z` = 240.010
WHERE `guid` = 6940260 AND `id` = 158309 AND `map` = 0
  AND `position_x` BETWEEN -6829.21 AND -6829.19
  AND `position_y` BETWEEN -1218.81 AND -1218.79
  AND `position_z` BETWEEN 241.02 AND 241.04;
