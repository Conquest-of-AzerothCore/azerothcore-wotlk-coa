-- Worldforged Rune Circle (pickup 6940616, Searing Gorge, #11737) floated 0.55 yd at its centre: the realm-map pass
-- moved its x/y 7.1 yd and kept the first-pass height. New z: the server's ground height at its centre.
UPDATE `gameobject` SET `position_z` = 240.469
WHERE `guid` = 6940616 AND `id` = 68399 AND `map` = 0
  AND `position_x` BETWEEN -6858.41 AND -6858.39
  AND `position_y` BETWEEN -1036.21 AND -1036.19
  AND `position_z` BETWEEN 241.01 AND 241.02;
