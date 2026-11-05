-- Worldforged Shiv of Warm Greetings (pickup 6941072, The Stockpile) floated 1.09 yd above the floor since rev_20261030_41 restored 36.352 after the terrain-height value proved too low (#11036). Set it on the floor the server measures at its x/y (35.26).
UPDATE `gameobject` SET `position_z` = 35.26 WHERE `guid` = 6941072 AND `id` = 95880 AND `map` = 0 AND `position_z` BETWEEN 36.342 AND 36.362;
