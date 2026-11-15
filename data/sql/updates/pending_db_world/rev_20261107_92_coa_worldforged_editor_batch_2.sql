-- Worldforged pickups reviewed in the world editor (batch 2): positions, sizes and models checked against
-- LootCollector and the reports, and misplaced duplicate spawns hidden instead of deleted.

-- #8412
-- pickup 6942411 (Water Seer's Headdress -> Mysterious Water Orb) moved 6.7 yd across and 1.70 yd up to the spot checked in the editor
UPDATE `gameobject` SET `id` = 90043, `position_x` = -211.3058, `position_y` = 2758.8038, `position_z` = 6.1927, `orientation` = 0, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0, `rotation3` = 1 WHERE `guid` = 6942411 AND `id` = 254278;

-- #8414
-- pickup 6942446 (Kodo Riding Harness) moved 22.72 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -7785.7000, `position_y` = -686.6000, `position_z` = -256.9326, `orientation` = 4.84991, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.656853, `rotation3` = -0.754019 WHERE `guid` = 6942446 AND `id` = 96174;

-- #8417
-- pickup 6941440 (Blackthorn Splitter) moved 8.8 yd across and 0.52 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -3977.9334, `position_y` = -2012.0263, `position_z` = 96.3491, `orientation` = 3.09538, `rotation0` = -0.43858, `rotation1` = 0.552432, `rotation2` = -0.545049, `rotation3` = -0.453197 WHERE `guid` = 6941440 AND `id` = 97114;

-- #8423
-- template 96152 (Singed Booklet): size 1 -> 0.2 (1 spawns)
UPDATE `gameobject_template` SET `size` = 0.2 WHERE `entry` = 96152;
-- pickup 6941642 (Singed Booklet) moved 6.6 yd across to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -4763.5591, `position_y` = -3658.5874, `position_z` = 47.7020, `orientation` = 1.29503, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.603206, `rotation3` = 0.797585 WHERE `guid` = 6941642 AND `id` = 96152;

-- #8430
-- pickup 6941830 (Old Blade) moved 7.0 yd across and 0.83 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 5113.2225, `position_y` = -519.2770, `position_z` = 334.9702, `orientation` = 4.016142, `rotation0` = -0.278552, `rotation1` = 0.59589, `rotation2` = 0.682339, `rotation3` = -0.318963 WHERE `guid` = 6941830 AND `id` = 517261;

-- #8432, #10476
-- template 254463 (Warbanner): size 1 -> 1.5 (2 spawns)
UPDATE `gameobject_template` SET `size` = 1.5 WHERE `entry` = 254463;
-- pickup 6942227 (Warbanner) moved 2.3 yd across and 4.53 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 3326.1057, `position_y` = -5664.3597, `position_z` = 13.0586, `orientation` = 3.624124, `rotation0` = 0.686988, `rotation1` = -0.0393853, `rotation2` = 0.725395, `rotation3` = 0.0172611 WHERE `guid` = 6942227 AND `id` = 254463;
-- pickup 6941134 (Warbanner) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6941134 AND `id` = 254463;

-- #8433
-- pickup 6940320 (Deadman's Dagger) moved 6.2 yd across and 3.73 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -612.1900, `position_y` = -1071.4953, `position_z` = 66.0557, `orientation` = 0.07712, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.03855, `rotation3` = 0.999257 WHERE `guid` = 6940320 AND `id` = 515385;
-- pickup 6940321 (Deadman's Dagger) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6940321 AND `id` = 515385;

-- #8465, #8706, #11074
-- pickup 6941970 (Moss Picker's Pouch) moved 2.0 yd across to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 10263.2379, `position_y` = 970.1101, `position_z` = 1341.2000, `orientation` = 6.088498, `rotation0` = 0.0102433, `rotation1` = -0.681456, `rotation2` = 5.8517e-05, `rotation3` = -0.731787 WHERE `guid` = 6941970 AND `id` = 1344099;
-- pickup 6941972 (Mossy Bag) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6941972 AND `id` = 90626;

-- #8513
-- template 515434 (Celestial Edge of Starfall): size 1 -> 1.3 (1 spawns)
UPDATE `gameobject_template` SET `size` = 1.3 WHERE `entry` = 515434;
-- pickup 6942238 (Celestial Edge of Starfall) moved 31.3 yd across and 22.24 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 9981.4921, `position_y` = 2007.3812, `position_z` = 1354.7006, `orientation` = 5.711063, `rotation0` = -0.651556, `rotation1` = -0.270598, `rotation2` = 0.57505, `rotation3` = -0.414209 WHERE `guid` = 6942238 AND `id` = 515434;

-- #8525
-- pickup 6941672 (Shiny Hammer) moved 7.0 yd across and 1.30 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 580.5571, `position_y` = -4547.9254, `position_z` = 41.4276, `orientation` = 5.65093, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.310888, `rotation3` = -0.950446 WHERE `guid` = 6941672 AND `id` = 254633;

-- #8528
-- pickup 6940101 (Bag of Folding) moved 1.4 yd across to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -11151.8681, `position_y` = -1963.5067, `position_z` = 35.7490, `orientation` = 6.10981, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.086579, `rotation3` = -0.996245 WHERE `guid` = 6940101 AND `id` = 254413;
-- pickup 6941424 (Bag of Folding) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6941424 AND `id` = 254413;

-- #8678
-- pickup 6940954 (Reverent Ring) moved turned to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -10977.5358, `position_y` = -1752.4602, `position_z` = 140.6754, `orientation` = 4.62174, `rotation0` = 0.477314, `rotation1` = 0.501466, `rotation2` = 0.532841, `rotation3` = -0.486604 WHERE `guid` = 6940954 AND `id` = 254506;
-- pickup 6940955 (Reverent Ring) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6940955 AND `id` = 254506;

-- #8736
-- pickup 6941178 (Scorched Knife) moved 4.5 yd across and 0.31 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -6766.9369, `position_y` = -3131.2577, `position_z` = 241.8665, `orientation` = 4.885609, `rotation0` = -0.532331, `rotation1` = 0.43372, `rotation2` = 0.475126, `rotation3` = -0.550241 WHERE `guid` = 6941178 AND `id` = 518098;

-- #8822, #11405
-- template 254233 (Crimson Dragonscale): size 1 -> 1.6 (1 spawns)
UPDATE `gameobject_template` SET `size` = 1.6 WHERE `entry` = 254233;
-- pickup 6940273 (Crimson Dragonscale) moved 5.8 yd across and 2.89 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -4057.3253, `position_y` = -3456.0894, `position_z` = 284.6397, `orientation` = 1.864571, `rotation0` = -0.245373, `rotation1` = 0.395313, `rotation2` = -0.657469, `rotation3` = -0.592667 WHERE `guid` = 6940273 AND `id` = 254233;

-- #8830
-- pickup 6941021 (Scarlet Shield) moved 0.08 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 1791.3300, `position_y` = 1333.7500, `position_z` = 89.9502, `orientation` = 5.73666, `rotation0` = 0, `rotation1` = 0, `rotation2` = -0.269872, `rotation3` = 0.962896 WHERE `guid` = 6941021 AND `id` = 254164;
-- pickup 6941022 (Scarlet Shield) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6941022 AND `id` = 254164;

-- #8910, #9394, #11292
-- pickup 6960003 (Bloodied Axe) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6960003 AND `id` = 93008;

-- #9035
-- pickup 6960209 (Shadow Cowl) moved 2.35 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 6007.9000, `position_y` = -55.0000, `position_z` = 24.6030, `orientation` = 1.24088, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.581391, `rotation3` = 0.813624 WHERE `guid` = 6960209 AND `id` = 1345125;

-- #9069, #10491
-- pickup 6940491 (Floodworn Shoulderguards) moved 0.2 yd across and 0.10 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -52.6875, `position_y` = -3179.5643, `position_z` = 101.0433, `orientation` = 5.2851, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.478585, `rotation3` = -0.878041 WHERE `guid` = 6940491 AND `id` = 95894;
-- pickup 6940490 (Floodworn Shoulderguards) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6940490 AND `id` = 95894;

-- #9077
-- pickup 6941580 (Conscription Supplies) moved 3.6 yd across to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 177.0061, `position_y` = -3596.2594, `position_z` = 27.1879, `orientation` = 3.89401, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.930064, `rotation3` = -0.367397 WHERE `guid` = 6941580 AND `id` = 95829;
-- pickup 6941581 (Conscription Supplies) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6941581 AND `id` = 95829;

-- #9147
-- pickup 6941387 (Affray Cuirras) moved 1.0 yd across to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -1643.3418, `position_y` = -4367.4108, `position_z` = 6.7520, `orientation` = 2.428011, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.937023, `rotation3` = 0.349269 WHERE `guid` = 6941387 AND `id` = 1345000;

-- #9194, #10674
-- pickup 6942183 (Silt Covered Ring) moved 3.2 yd across and 0.39 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 1439.6139, `position_y` = -4735.6322, `position_z` = -16.6884, `orientation` = 4.20163, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.862798, `rotation3` = -0.505549 WHERE `guid` = 6942183 AND `id` = 95645;

-- #9225
-- pickup 6975030 (Apothecary's Lantern) moved 0.76 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -7189.7000, `position_y` = -3793.6000, `position_z` = 9.7738, `orientation` = 0, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0, `rotation3` = 1 WHERE `guid` = 6975030 AND `id` = 1345004;

-- #9295
-- pickup 6942241 (Steelrider Girdle) moved 3.3 yd across and 1.49 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 276.0405, `position_y` = -3038.1650, `position_z` = 97.5888, `orientation` = 4.84623, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.658239, `rotation3` = -0.752809 WHERE `guid` = 6942241 AND `id` = 1345138;

-- #9351
-- pickup 6940588 (Hammerspine's Fallen Hammer) moved 1.7 yd across to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -5576.3670, `position_y` = -1729.7324, `position_z` = 354.1330, `orientation` = 5.471822, `rotation0` = 0.615358, `rotation1` = -0.501728, `rotation2` = 0.3452, `rotation3` = 0.50044 WHERE `guid` = 6940588 AND `id` = 95616;
-- pickup 6941132 (Hammerspine's Fallen Hammer) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6941132 AND `id` = 95616;
