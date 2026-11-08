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
