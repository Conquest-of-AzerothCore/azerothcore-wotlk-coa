-- Worldforged Tiki Shield (pickup 6941251, Lard's Lunch island, The Hinterlands) floated 8.63 yd above the seabed
-- at its x/y, off the island (#11516). The island top where the reporter stood at (414.762, -4830.559)
-- measures 11.258, so move the pickup onto it.
UPDATE `gameobject` SET `position_x` = 414.762, `position_y` = -4830.559, `position_z` = 11.258
WHERE `guid` = 6941251 AND `id` = 515918 AND `map` = 0
  AND `position_x` BETWEEN 420.3 AND 420.5 AND `position_y` BETWEEN -4849.5 AND -4849.3
  AND `position_z` BETWEEN 0.7 AND 0.8;
