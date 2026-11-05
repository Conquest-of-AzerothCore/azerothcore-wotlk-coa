-- Worldforged Hunter's Lockbox (#10903, guid 6941846) floated 0.67 yd above the Ashenvale terrain; the terrain
-- under it is 148.392.
UPDATE `gameobject` SET `position_z` = 148.392
WHERE `guid` = 6941846 AND `id` = 387854 AND `map` = 1
  AND `position_x` BETWEEN 2442.6 AND 2443.6 AND `position_y` BETWEEN -2682.7 AND -2681.7
  AND `position_z` BETWEEN 149.0 AND 149.1;
