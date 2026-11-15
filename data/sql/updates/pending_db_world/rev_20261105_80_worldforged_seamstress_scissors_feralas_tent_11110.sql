-- Worldforged Seamstress Scissors (pickup 6942149, Feralas) was placed 14.2 yd from the first-pass observed position (-4629.715, -383.775) and sat 1.8 yd under the ground at its x/y (#11110). Move it back to the observed x/y and onto the ground the server measures there (133.044).
UPDATE `gameobject` SET `position_x` = -4629.715, `position_y` = -383.775, `position_z` = 133.044
WHERE `guid` = 6942149 AND `id` = 515845 AND `map` = 1 AND `position_z` BETWEEN 134.096 AND 134.116 AND `position_x` BETWEEN -4636.710 AND -4636.690 AND `position_y` BETWEEN -396.210 AND -396.190;
