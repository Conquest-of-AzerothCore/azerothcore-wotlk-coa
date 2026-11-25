-- #13343: Worldforged Reclaimed Circlet (6942069) floated 0.90 yd above the crane platform at the Thalassian Base Camp; lower it onto the measured platform (z 132.890).
UPDATE `gameobject` SET `position_x` = 4326.7, `position_y` = -6116.2, `position_z` = 132.89
WHERE `guid` = 6942069 AND `id` = 254449;
