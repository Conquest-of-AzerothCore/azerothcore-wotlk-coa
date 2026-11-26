-- #13348: Worldforged Darnell's Blade (6941613) floated 0.71 yd above the ground; lower it onto the measured ground (z 3.745).
UPDATE `gameobject` SET `position_x` = -7291.4, `position_y` = 1157.8, `position_z` = 3.745
WHERE `guid` = 6941613 AND `id` = 638836;
