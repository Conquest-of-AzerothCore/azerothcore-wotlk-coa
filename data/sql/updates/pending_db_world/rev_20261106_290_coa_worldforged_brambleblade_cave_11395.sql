-- Worldforged Brambleblade (pickup 6941487, Brambleblade Ravine) stood 40.8 yd under the terrain with no cave floor
-- at its x/y (#11395).
-- Move it to the reporter's position in the cave, where the server measures the floor at z 85.30.
UPDATE `gameobject` SET `position_x` = -3107.24, `position_y` = -1198.35, `position_z` = 85.3
WHERE `guid` = 6941487 AND `id` = 90336 AND `map` = 1
  AND `position_x` BETWEEN -3106.81 AND -3106.79
  AND `position_y` BETWEEN -1209.41 AND -1209.39
  AND `position_z` BETWEEN 85.37 AND 85.39;
