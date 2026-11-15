-- Worldforged Shadowpounce Cowl (pickup 6941058, Shaul'watha, The Hinterlands) stood 8.66 yd above the terrain
-- at its x/y and 0.12 yd from a wall model (#11362). The floor the reporter stood on at
-- (74.623, -4380.05) measures 130.07, so move the pickup onto it.
UPDATE `gameobject` SET `position_x` = 74.623, `position_y` = -4380.05, `position_z` = 130.07
WHERE `guid` = 6941058 AND `id` = 95792 AND `map` = 0
  AND `position_x` BETWEEN 78.5 AND 78.7 AND `position_y` BETWEEN -4381.4 AND -4381.2
  AND `position_z` BETWEEN 128.5 AND 128.55;
