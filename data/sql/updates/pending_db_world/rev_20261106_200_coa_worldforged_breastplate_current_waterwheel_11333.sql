-- Worldforged Breastplate of the Current (pickup 6941493, Cragpool Lake, Stonetalon Mountains) hung 17 yd above the
-- ground at its realm-map x/y (#11333, #11334): the earlier fix kept that x/y and took only z from the archive
-- sighting.
-- Move it to the archive sighting x/y (1610.07, 178.852), where the ground the server measures is 104.67.
UPDATE `gameobject` SET `position_x` = 1610.07, `position_y` = 178.852, `position_z` = 104.67
WHERE `guid` = 6941493 AND `id` = 95662 AND `map` = 1
  AND `position_x` BETWEEN 1613.9 AND 1614.1 AND `position_y` BETWEEN 169.2 AND 169.4
  AND `position_z` BETWEEN 104.4 AND 104.5;
