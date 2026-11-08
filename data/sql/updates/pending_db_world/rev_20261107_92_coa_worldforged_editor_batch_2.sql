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
