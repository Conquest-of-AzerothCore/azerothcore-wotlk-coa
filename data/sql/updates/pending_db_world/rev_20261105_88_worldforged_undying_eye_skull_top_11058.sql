-- Worldforged The Undying Eye (pickup 6942305, Desolace) was buried 1.7 yd inside the skeleton model, 0.03 yd from the nearest model surface, out of reach of both reporters (#11058, #11198). Set it on the top of the model at its x/y, which the server measures as ground (94.798).
UPDATE `gameobject` SET `position_z` = 94.798
WHERE `guid` = 6942305 AND `id` = 254294 AND `map` = 1 AND `position_z` BETWEEN 91.457 AND 91.477;
