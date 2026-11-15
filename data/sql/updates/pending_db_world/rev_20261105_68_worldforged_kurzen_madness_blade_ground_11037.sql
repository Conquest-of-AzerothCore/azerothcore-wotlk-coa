-- Worldforged Kurzen Madness Blade (pickup 6940688, Kurzen's Compound) hovered 1.2 yd above the floor after the recorded-heights pass raised it to a sighting 6.9 yd away (#11037). Set it on the floor the server measures at its x/y (32.99).
UPDATE `gameobject` SET `position_z` = 32.99 WHERE `guid` = 6940688 AND `id` = 515470 AND `map` = 0 AND `position_z` BETWEEN 34.183 AND 34.203;
