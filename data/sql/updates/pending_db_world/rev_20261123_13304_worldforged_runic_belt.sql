-- #13304: Worldforged Runic Belt (6941870) sat 0.82 yd inside the Dustwind Cave floor and could not be selected; raise it onto the measured floor (z 31.326).
UPDATE `gameobject` SET `position_x` = 872.8, `position_y` = -4741.1, `position_z` = 31.326
WHERE `guid` = 6941870 AND `id` = 254581;
