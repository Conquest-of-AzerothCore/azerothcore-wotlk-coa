-- Worldforged Boulder Greaves (pickup 6941479, Stonetalon Mountains) sat 3.2 yd under the ground at its x/y (#11310):
-- the realm-map conversion kept a z below the terrain. The ground the server measures there is 177.68.
UPDATE `gameobject` SET `position_z` = 177.68
WHERE `guid` = 6941479 AND `id` = 1345017 AND `map` = 1
  AND `position_x` BETWEEN -241.4 AND -241.2 AND `position_y` BETWEEN 71.6 AND 71.8
  AND `position_z` BETWEEN 174.4 AND 174.5;
