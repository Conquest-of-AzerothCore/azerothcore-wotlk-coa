-- Worldforged pickups reviewed in the world editor (batch 5): positions checked against the Ascension
-- catalogue, LootCollector and the reports; misplaced duplicate spawns hidden instead of deleted.

-- #6735 #7864
-- copies of other zones' pickups imported to Dun Morogh: 6940023 (Old Crossbow), 6941286 (Ulag's Other Cleaver), 6941330 (Floating Barrel), 6941331 (Floating Barrel), 6940804 (Forsaken Cart Crate) hidden, not deleted
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` IN (6940023, 6941286, 6941330, 6941331, 6940804) AND `id` IN (95803, 515405, 517351, 517352);

-- #7237
-- pickup 6941417 (Teldrassil Skewer) moved 12.0 yd across and 0.50 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 5200.8114, `position_y` = 255.5983, `position_z` = 34.926, `orientation` = 2.805369, `rotation0` = 0.116328, `rotation1` = 0.685437, `rotation2` = 0.708647, `rotation3` = 0.120267 WHERE `guid` = 6941417 AND `id` = 518305;
-- the merchant cart and crate the skewer leaned on were missing (Ascension positions, adjusted in the editor)
-- Elf Crate 01 next to the skewer
DELETE FROM `gameobject` WHERE `guid` = 6976004;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976004, 179971, 1, 1, 1, 5200.440471, 255.580729, 34.086, 1.486536, 0, 0, 0.676698, 0.736261, 300, 100, 1);
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`) VALUES (3297126, 5, 1029654, 'Night Elf Cart', 1, 0, 0, '', '') ON DUPLICATE KEY UPDATE `type` = 5, `displayId` = 1029654, `name` = 'Night Elf Cart', `size` = 1;
DELETE FROM `gameobject` WHERE `guid` = 6976003;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976003, 3297126, 1, 1, 1, 5201.485306, 256.8455, 34.117395, 1.553366, 0, 0, 0.700917, 0.713242, 300, 100, 1);

-- #8420
-- pickup 6942306 (The Wingman) moved 8.9 yd across and 0.79 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -10083.3, `position_y` = -4170.7, `position_z` = 2.6922, `orientation` = 2.01255, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.844845, `rotation3` = 0.535011 WHERE `guid` = 6942306 AND `id` = 515801;

-- #10478
-- pickup 6941033 (Fishing Box) moved 11.9 yd across and 0.41 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 1299.087, `position_y` = -2188.949, `position_z` = 53.106, `orientation` = 5.81458, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.232165, `rotation3` = -0.972676 WHERE `guid` = 6941033 AND `id` = 340115;

-- #10604
-- second Gravesword left after the first was moved: 6941265 (Gravesword) hidden, not deleted
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` IN (6941265) AND `id` IN (518052);

-- #10923
-- pickup 6940028 (Ladel) moved 25.8 yd across and 18.07 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -13781.7138, `position_y` = -214.3342, `position_z` = 28.4171, `orientation` = 5.36533, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.442987, `rotation3` = -0.896528 WHERE `guid` = 6940028 AND `id` = 515466;

-- #11145
-- pickup 6942005 (Precious Ring) moved 5.5 yd across and 0.00 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -7131.33, `position_y` = -1267.74, `position_z` = -198.349, `orientation` = 3.18828, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.999728, `rotation3` = -0.023342 WHERE `guid` = 6942005 AND `id` = 95934;

-- #11426
-- pickup 6941234 (Blackrock Smuggled Goods) moved 4.4 yd across and 6.81 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -9614.424, `position_y` = -3008.34, `position_z` = 52.878, `orientation` = 4.32816, `rotation0` = -0.053369, `rotation1` = 0.035988, `rotation2` = 0.82739, `rotation3` = -0.557928 WHERE `guid` = 6941234 AND `id` = 90262;

-- #11435
-- pickup 6941817 (Worshipped Warpwood Growth) moved 21.9 yd across and 85.96 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 6439.7, `position_y` = -1725.53, `position_z` = 418.171, `orientation` = 4.18642, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.866617, `rotation3` = -0.498973 WHERE `guid` = 6941817 AND `id` = 96155;

-- #11491
-- pickup 6940546 (Gilnean Crate) moved 9.1 yd across and 3.97 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 851.152, `position_y` = 1909.88, `position_z` = -5.198, `orientation` = 5.74223, `rotation0` = 0, `rotation1` = 0, `rotation2` = -0.267192, `rotation3` = 0.963643 WHERE `guid` = 6940546 AND `id` = 90328;

-- #11526
-- pickup 6940791 (Empty Bag) moved 9.9 yd across and 0.17 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 3244.2393, `position_y` = -3834.5845, `position_z` = 141.1332, `orientation` = 5.799426, `rotation0` = 0.053581, `rotation1` = 0.217181, `rotation2` = 0.233458, `rotation3` = -0.946287 WHERE `guid` = 6940791 AND `id` = 96239;

-- #11535
-- pickup 6940923 (Radiant Helmet) moved 1.4 yd across and 2.00 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -5888.99, `position_y` = 478.711, `position_z` = 535.981, `orientation` = 1.93339, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.823013, `rotation3` = 0.568023 WHERE `guid` = 6940923 AND `id` = 520704;

-- #11541
-- pickup 6940225 (Catacombs Relic Torch) moved 1.6 yd across and 2.51 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -10335.8241, `position_y` = 410.7642, `position_z` = 18.567, `orientation` = 6.032167, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.12518, `rotation3` = -0.992134 WHERE `guid` = 6940225 AND `id` = 90282;
-- copy outside the catacombs: 6940226 (Catacombs Relic Torch) hidden, not deleted
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` IN (6940226) AND `id` IN (90282);

-- #11561
-- leftover copy of the Embedded Sword: 6942359 (Embedded Sword) hidden, not deleted
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` IN (6942359) AND `id` IN (95622);

-- #11584
-- pickup 6940745 (Ritual Tome) moved 22.1 yd across and 29.89 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -13091.4, `position_y` = -607.342, `position_z` = 58.3065, `orientation` = 0.77223, `rotation0` = -0.597578, `rotation1` = -0.242928, `rotation2` = 0.287763, `rotation3` = 0.707869 WHERE `guid` = 6940745 AND `id` = 95755;

-- #11586
-- pickup 6942187 (Silverhand Spaulder) moved 6.9 yd across and 0.00 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 5201.5, `position_y` = -571.654, `position_z` = 289.32, `orientation` = 1.35445, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.626633, `rotation3` = 0.779315 WHERE `guid` = 6942187 AND `id` = 517234;

-- #11591
-- pickup 6942080 (Scorched Equipment Cache) moved 13.4 yd across and 0.89 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 578.082, `position_y` = -4113.61, `position_z` = 18.2154, `orientation` = 3.80281, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.945845, `rotation3` = -0.324619 WHERE `guid` = 6942080 AND `id` = 95633;

-- #11597
-- pickup 6942318 (Broken Tail Spike) moved 3.9 yd across and 0.37 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 968.932, `position_y` = -4278.434, `position_z` = -7.1, `orientation` = 0.8309, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.403602, `rotation3` = 0.914935 WHERE `guid` = 6942318 AND `id` = 95624;
-- template 95624 (Broken Tail Spike) was smaller than the reported model
UPDATE `gameobject_template` SET `size` = 0.7 WHERE `entry` = 95624;

-- #11601
-- pickup 6941557 (Lost Shipment) moved 28.8 yd across and 0.00 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 749.815, `position_y` = 1413.85, `position_z` = -14.223, `orientation` = 1.70245, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.752088, `rotation3` = 0.659062 WHERE `guid` = 6941557 AND `id` = 97108;
