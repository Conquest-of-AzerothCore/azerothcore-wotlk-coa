-- Worldforged Woodpaw Greatblade (pickup 6942441, Feralas) floated 7.80 yd above the ground at its x/y (#11603).
-- The ground where the reporter stood at (-4966.05, 653.459) measures 37.338, so move the pickup there.
UPDATE `gameobject` SET `position_x` = -4966.0503, `position_y` = 653.4586, `position_z` = 37.338
WHERE `guid` = 6942441 AND `id` = 96137 AND `map` = 1
  AND `position_x` BETWEEN -4968.1 AND -4967.9 AND `position_y` BETWEEN 649.6 AND 649.8
  AND `position_z` BETWEEN 43.8 AND 43.9;
