-- Worldforged Biggs's Spare Equipment (pickup 6940119, Swamp of Sorrows) stood inside the Replacecrate02 model
-- at its x/y, 0.45 yd under the crate surface the server measures there (#11725).
-- Raise it to the measured ground height, z 23.509.
UPDATE `gameobject` SET `position_z` = 23.509
WHERE `guid` = 6940119 AND `id` = 254380 AND `map` = 0
  AND `position_x` BETWEEN -10535.11 AND -10535.09
  AND `position_y` BETWEEN -2840.71 AND -2840.69
  AND `position_z` BETWEEN 22.74 AND 22.77;
