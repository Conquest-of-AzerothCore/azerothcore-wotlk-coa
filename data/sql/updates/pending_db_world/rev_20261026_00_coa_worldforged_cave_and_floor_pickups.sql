-- Worldforged pickups inside caves, mines and upper floors (#9232, #9223): back to the realm's hand-authored spots.
-- rev_20261014_95_worldforged_lootcollector_alignment wrote the open-ground height for these 13: cave and mine
-- pickups ended up above the rock or in the sky (Glinting Kobold Corpse 150 yd above Jasperlode Mine), and tower
-- pickups under the ground floor. The positions are the ones the world held before that pass, as
-- rev_20261024_98_coa_lexicon_of_azora_authored_spot already did for Lexicon of Azora - Part I.

-- Glinting Kobold Corpse, Jasperlode Mine
UPDATE `gameobject` SET `position_x` = -9054.57, `position_y` = -619.93, `position_z` = 53.7989, `orientation` = 2.04844, `rotation0` = 0.0448175, `rotation1` = 0.0272671, `rotation2` = 0.853133, `rotation3` = 0.519049
WHERE `guid` = 6940549 AND `id` = 90223;
-- Nethergarde Mining Cap, Swamp of Sorrows
UPDATE `gameobject` SET `position_x` = -10661.9, `position_y` = -3343.8, `position_z` = -8.976, `orientation` = 0.7336, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.35863, `rotation3` = 0.93348
WHERE `guid` = 6940803 AND `id` = 96193;
-- Stonesplitter, Stranglethorn Vale
UPDATE `gameobject` SET `position_x` = -13232.0, `position_y` = -471.7, `position_z` = 5.823, `orientation` = 3.29389, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.997102, `rotation3` = -0.076075
WHERE `guid` = 6941160 AND `id` = 95759;
-- Icon of Khan Maraudos, Desolace
UPDATE `gameobject` SET `position_x` = -1448.1, `position_y` = 3010.4, `position_z` = 116.951, `orientation` = 4.87219, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.648413, `rotation3` = -0.761289
WHERE `guid` = 6941854 AND `id` = 254307;
-- Yeti Napkin, Feralas
UPDATE `gameobject` SET `position_x` = -5174.7, `position_y` = 1810.1, `position_z` = 117.142, `orientation` = 4.40821, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.806074, `rotation3` = -0.591815
WHERE `guid` = 6942452 AND `id` = 96119;
-- Timbermaw Cache, Felwood
UPDATE `gameobject` SET `position_x` = 6999.5, `position_y` = -2105.2, `position_z` = 587.131, `orientation` = 5.78865, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.244756, `rotation3` = -0.969585
WHERE `guid` = 6942332 AND `id` = 517274;
-- Accursed Yeti Horn, Feralas
UPDATE `gameobject` SET `position_x` = -3941.1, `position_y` = 1671.9, `position_z` = 135.66, `orientation` = 0.50264, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.248683, `rotation3` = 0.968585
WHERE `guid` = 6941382 AND `id` = 96132;
-- Peculiar Gold Nugget, Westfall
UPDATE `gameobject` SET `position_x` = -10556.4, `position_y` = 1999.86, `position_z` = -6.88128, `orientation` = 2.95216, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.995518, `rotation3` = 0.094575
WHERE `guid` = 6940876 AND `id` = 90244;
-- Sentinel's Blade, Sentinel Hill
UPDATE `gameobject` SET `position_x` = -10510.2, `position_y` = 1028.88, `position_z` = 95.7615, `orientation` = 3.65916, `rotation0` = 0.0728429, `rotation1` = 0.588311, `rotation2` = 0.778531, `rotation3` = -0.206091
WHERE `guid` = 6941048 AND `id` = 95810;
-- Lexicon of Azora - Part II, Redridge
UPDATE `gameobject` SET `position_x` = -9295.91, `position_y` = -3311.97, `position_z` = 151.57, `orientation` = 3.77293, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.950588, `rotation3` = -0.310455
WHERE `guid` = 6940966 AND `id` = 90234;
-- Catacomb Grave Dirt Pile, Duskwood
UPDATE `gameobject` SET `position_x` = -10282.8, `position_y` = 180.025, `position_z` = 2.022, `orientation` = 2.00285, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.842241, `rotation3` = 0.539101
WHERE `guid` = 6940224 AND `id` = 90286;
-- Raptor Talon, Dustwallow Marsh
UPDATE `gameobject` SET `position_x` = -4336.0, `position_y` = -2601.8, `position_z` = 39.623, `orientation` = 3.97905, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.913607, `rotation3` = -0.406599
WHERE `guid` = 6942056 AND `id` = 515920;
-- Thule's Curse Parchment, Silverpine Forest
UPDATE `gameobject` SET `position_x` = 1008.52, `position_y` = 693.507, `position_z` = 77.5421, `orientation` = 3.83438, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.940603, `rotation3` = -0.339508
WHERE `guid` = 6941239 AND `id` = 90320;
