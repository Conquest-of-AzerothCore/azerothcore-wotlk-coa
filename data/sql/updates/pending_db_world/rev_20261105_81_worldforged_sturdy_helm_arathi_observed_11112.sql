-- Worldforged Suprisingly Sturdy Helm (pickup 6941179, Arathi Highlands) was placed 12.8 yd from the first-pass observed position (-1250.94, -1608.29), 14.9 yd from the reporter standing 3.4 yd from it (#11112). Move it to the observed x/y, on the ground the server measures there (50.052).
UPDATE `gameobject` SET `position_x` = -1250.94, `position_y` = -1608.29, `position_z` = 50.052
WHERE `guid` = 6941179 AND `id` = 95865 AND `map` = 0 AND `position_z` BETWEEN 48.800 AND 48.820 AND `position_x` BETWEEN -1257.410 AND -1257.390 AND `position_y` BETWEEN -1619.110 AND -1619.090;
