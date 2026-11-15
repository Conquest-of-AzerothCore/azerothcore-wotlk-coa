-- Worldforged Resonite Band (pickup 6942079, Stonetalon) was inside the Boulderslide rock wall: 0.15 yd from the nearest model, 59 yd under the ground the server finds there (#11136). Move it to the reporter's standing point (-38.77, 250.86, 85.97), which the server measures as ground.
UPDATE `gameobject` SET `position_x` = -38.77, `position_y` = 250.86, `position_z` = 85.97
WHERE `guid` = 6942079 AND `id` = 254230 AND `map` = 1 AND `position_z` BETWEEN 85.960 AND 85.980 AND `position_x` BETWEEN -36.510 AND -36.490 AND `position_y` BETWEEN 250.390 AND 250.410;
