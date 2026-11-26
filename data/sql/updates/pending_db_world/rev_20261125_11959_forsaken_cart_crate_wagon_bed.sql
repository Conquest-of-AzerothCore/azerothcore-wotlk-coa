-- Worldforged Forsaken Cart Crate (object 517352, guid 6940805), Tirisfal Glades (#11959): the Tirisfal audit placed
-- it at z 35.5593, 0.21 yd below the Westfallwagon01.m2 cart bed top surface (35.7658) at (2042.55, 64.25).
-- Raise it to the VMap cart bed surface height there (matching first-pass row 6900623 at 35.749 on the same bed).
UPDATE `gameobject` SET `position_z` = 35.766
WHERE `guid` = 6940805 AND `id` = 517352 AND `map` = 0
  AND `position_x` BETWEEN 2042.50 AND 2042.60
  AND `position_y` BETWEEN 64.20 AND 64.30
  AND `position_z` BETWEEN 35.55 AND 35.57;
