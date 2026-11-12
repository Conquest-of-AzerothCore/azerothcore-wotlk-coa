-- Worldforged pickups reviewed in the world editor (batch 7): positions checked against the server floor
-- (maps + vmaps), the Ascension catalogue and LootCollector; missing Ascension props restored next to
-- their pickups; misplaced duplicate spawns hidden instead of deleted.

-- #12119
-- pickup 6942088 (Ridiculously Thick Web) moved 3.3 yd across and 0.63 yd down onto the cave floor at the LootCollector spot, checked in the editor
UPDATE `gameobject` SET `position_x` = 10947.1076, `position_y` = 884.3237, `position_z` = 1337.2487, `orientation` = 3.8209, `rotation0` = 0.21126571600859118, `rotation1` = -0.6455961588691098, `rotation2` = 0.6869038286281989, `rotation3` = -0.25833220300371124 WHERE `guid` = 6942088 AND `id` = 95614;
-- pickup 6941651 (Dripping Fang) moved 1.1 yd across and 134.61 yd down from 140 yd above the cave to its LootCollector spot in the Egg Chamber
UPDATE `gameobject` SET `position_x` = 10932.6, `position_y` = 933.4, `position_z` = 1340.61, `orientation` = 4.3301, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.828572, `rotation3` = -0.559882 WHERE `guid` = 6941651 AND `id` = 1345040;

-- #12100
-- pickup 6941017 (Garmet Supplies) moved 2.8 yd across and 0.10 yd up out of the ground, checked in the editor
UPDATE `gameobject` SET `position_x` = 2456.6999, `position_y` = -1685.6573, `position_z` = 103.3423, `orientation` = 0.1718, `rotation0` = 0, `rotation1` = 0, `rotation2` = -0.08578582856422419, `rotation3` = -0.9963136010401291 WHERE `guid` = 6941017 AND `id` = 340047;

-- #12098
-- pickup 6941019 (Slightly-Damaged Chest) moved 16.4 yd across and 6.22 yd down to the ground, checked in the editor
UPDATE `gameobject` SET `position_x` = 2087.626, `position_y` = -1530.4155, `position_z` = 66.256, `orientation` = 3.6325, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.970026, `rotation3` = -0.243001 WHERE `guid` = 6941019 AND `id` = 96243;

-- #12097
-- pickup 6940496 (Foreman's Lightcap) moved 3.1 yd across and 2.12 yd up to its Ascension position on top of the crates
UPDATE `gameobject` SET `position_x` = -788.01, `position_y` = 68.039, `position_z` = 11.2038, `orientation` = 2.1028, `rotation0` = -0.04608232114189615, `rotation1` = 0.03148145269994918, `rotation2` = 0.8666500829296354, `rotation3` = 0.4957852070928823 WHERE `guid` = 6940496 AND `id` = 515403;
-- the Ascension pick axe next to the pickup was missing
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`) VALUES (3242246, 5, 1020314, 'Pick Axe', 1.5, 0, 0, '', '') ON DUPLICATE KEY UPDATE `type` = 5, `displayId` = 1020314, `name` = 'Pick Axe', `size` = 1.5, `Data0` = 0, `Data1` = 0, `AIName` = '', `ScriptName` = '';
-- Pick Axe
DELETE FROM `gameobject` WHERE `guid` = 6976011;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976011, 3242246, 0, 1, 1, -788.48, 67.559, 9.796, 5.4056, 0, 0, 0.424865, -0.905257, 300, 100, 1);
-- the pickup stands on crates in Ascension (no position data: two stacked under it and one beside)
-- Salvage Crate
DELETE FROM `gameobject` WHERE `guid` = 6976012;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976012, 188076, 0, 1, 1, -788.01, 68.039, 9.053, 5.4056, 0, 0, 0.424865, -0.905257, 300, 100, 1);
-- Salvage Crate
DELETE FROM `gameobject` WHERE `guid` = 6976013;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976013, 188076, 0, 1, 1, -788.01, 68.039, 10.083, 5.4056, 0, 0, 0.424865, -0.905257, 300, 100, 1);
-- Salvage Crate
DELETE FROM `gameobject` WHERE `guid` = 6976014;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976014, 188076, 0, 1, 1, -786.75, 69, 9.05, 5.4056, 0, 0, 0.424865, -0.905257, 300, 100, 1);

-- #12096
-- pickup 6941271 (Trapper's Lone Band) moved 5.3 yd across and 0.17 yd down into the nest, checked in the editor
UPDATE `gameobject` SET `position_x` = 101.9794, `position_y` = -4125.5704, `position_z` = 173.6403, `orientation` = 4.5647, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.757335, `rotation3` = -0.653026 WHERE `guid` = 6941271 AND `id` = 95797;
-- the Ascension nest and troll remains around the ring were missing (Ascension positions)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`) VALUES (96086, 5, 1017804, 'Nest Prop', 1, 0, 0, '', '') ON DUPLICATE KEY UPDATE `type` = 5, `displayId` = 1017804, `name` = 'Nest Prop', `size` = 1, `Data0` = 0, `Data1` = 0, `AIName` = '', `ScriptName` = '';
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`) VALUES (96087, 5, 1048715, 'Troll Skull Prop', 1, 0, 0, '', '') ON DUPLICATE KEY UPDATE `type` = 5, `displayId` = 1048715, `name` = 'Troll Skull Prop', `size` = 1, `Data0` = 0, `Data1` = 0, `AIName` = '', `ScriptName` = '';
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`) VALUES (96088, 5, 1044954, 'Troll Skull 2 Prop', 1, 0, 0, '', '') ON DUPLICATE KEY UPDATE `type` = 5, `displayId` = 1044954, `name` = 'Troll Skull 2 Prop', `size` = 1, `Data0` = 0, `Data1` = 0, `AIName` = '', `ScriptName` = '';
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`) VALUES (96089, 5, 1044955, 'Troll Skull 3 Prop', 1, 0, 0, '', '') ON DUPLICATE KEY UPDATE `type` = 5, `displayId` = 1044955, `name` = 'Troll Skull 3 Prop', `size` = 1, `Data0` = 0, `Data1` = 0, `AIName` = '', `ScriptName` = '';
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`) VALUES (96090, 5, 1044951, 'Troll Skeleton Prop', 1, 0, 0, '', '') ON DUPLICATE KEY UPDATE `type` = 5, `displayId` = 1044951, `name` = 'Troll Skeleton Prop', `size` = 1, `Data0` = 0, `Data1` = 0, `AIName` = '', `ScriptName` = '';
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`) VALUES (96091, 5, 1044343, 'Troll Skeleton Arm Prop', 1, 0, 0, '', '') ON DUPLICATE KEY UPDATE `type` = 5, `displayId` = 1044343, `name` = 'Troll Skeleton Arm Prop', `size` = 1, `Data0` = 0, `Data1` = 0, `AIName` = '', `ScriptName` = '';
-- Nest Prop
DELETE FROM `gameobject` WHERE `guid` = 6976015;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976015, 96086, 0, 1, 1, 101.928, -4125.439, 172.756, 4.5647, 0, 0, 0.757335, -0.653026, 300, 100, 1);
-- Troll Skull Prop
DELETE FROM `gameobject` WHERE `guid` = 6976016;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976016, 96087, 0, 1, 1, 101.359, -4125.56, 173.425, 4.5647, 0, 0, 0.757335, -0.653026, 300, 100, 1);
-- Troll Skull 2 Prop
DELETE FROM `gameobject` WHERE `guid` = 6976017;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976017, 96088, 0, 1, 1, 98.254, -4124.36, 172.931, 4.5647, 0, 0, 0.757335, -0.653026, 300, 100, 1);
-- Troll Skull 3 Prop
DELETE FROM `gameobject` WHERE `guid` = 6976018;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976018, 96089, 0, 1, 1, 104.197, -4126.83, 172.794, 4.5647, 0, 0, 0.757335, -0.653026, 300, 100, 1);
-- Troll Skeleton Prop
DELETE FROM `gameobject` WHERE `guid` = 6976019;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976019, 96090, 0, 1, 1, 104.035, -4124.86, 172.762, 4.5647, 0, 0, 0.757335, -0.653026, 300, 100, 1);
-- Troll Skeleton Arm Prop
DELETE FROM `gameobject` WHERE `guid` = 6976020;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976020, 96091, 0, 1, 1, 102.4749, -4124.6673, 173.6533, 4.5647, 0, 0, 0.757335, -0.653026, 300, 100, 1);

-- #12094
-- pickup 6940753 (Old Shoulderpad) moved 7.3 yd across and 0.01 yd up into the wrecked boat, next to its matching prop
UPDATE `gameobject` SET `position_x` = -107.0908, `position_y` = -1132.8808, `position_z` = 37.5963, `orientation` = 0.2297, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.114578, `rotation3` = 0.993414 WHERE `guid` = 6940753 AND `id` = 517314;
-- the Ascension wrecked boat, crate and matching left shoulderpad were missing (Ascension positions)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`) VALUES (95988, 5, 223, 'Wrecked Boat Prop', 1, 0, 0, '', '') ON DUPLICATE KEY UPDATE `type` = 5, `displayId` = 223, `name` = 'Wrecked Boat Prop', `size` = 1, `Data0` = 0, `Data1` = 0, `AIName` = '', `ScriptName` = '';
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`) VALUES (515580, 5, 3791, 'RPG PROP Damaged Crate', 1, 0, 0, '', '') ON DUPLICATE KEY UPDATE `type` = 5, `displayId` = 3791, `name` = 'RPG PROP Damaged Crate', `size` = 1, `Data0` = 0, `Data1` = 0, `AIName` = '', `ScriptName` = '';
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`) VALUES (517315, 5, 515521, 'Old Shoulderpad', 1, 0, 0, '', '') ON DUPLICATE KEY UPDATE `type` = 5, `displayId` = 515521, `name` = 'Old Shoulderpad', `size` = 1, `Data0` = 0, `Data1` = 0, `AIName` = '', `ScriptName` = '';
-- Wrecked Boat Prop
DELETE FROM `gameobject` WHERE `guid` = 6976021;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976021, 95988, 0, 1, 1, -107.5877, -1131.2096, 37.0567, 1.9922, 0.4844348845763111, 0.7367121377001131, 0.4021393310184849, 0.24670230485115327, 300, 100, 1);
-- RPG PROP Damaged Crate
DELETE FROM `gameobject` WHERE `guid` = 6976022;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976022, 515580, 0, 1, 1, -106.7629, -1132.4815, 37.3503, 0.2297, 0, 0, 0.114578, 0.993414, 300, 100, 1);
-- Old Shoulderpad
DELETE FROM `gameobject` WHERE `guid` = 6976023;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976023, 517315, 0, 1, 1, -107.1163, -1132.7348, 37.6179, 0.2297, -0.29011166199269955, -0.033460786749330625, 0.10958330385498313, 0.9501089931382484, 300, 100, 1);

-- #12093
-- second Ol' Blunderbuss; 6940826 is the one at the LootCollector and Ascension spot
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` IN (6940827) AND `id` IN (95527);

-- #12092
-- pickup 6940251 (Chok'sul's Basket) moved 4.2 yd across and 86.78 yd down to the lower floor where the LootCollector spot is
UPDATE `gameobject` SET `position_x` = -4774.7238, `position_y` = -4145.2983, `position_z` = 304.5644, `orientation` = 4.1254, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.881447, `rotation3` = -0.472283 WHERE `guid` = 6940251 AND `id` = 95529;
-- duplicate Ogre Loincloth 1 yd from 6940251
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` IN (6940824) AND `id` IN (95529);

-- #12091
-- pickup 6941185 (Sword of Stone) moved 2.8 yd across and 0.77 yd down to the rock, checked in the editor
UPDATE `gameobject` SET `position_x` = -5605.7082, `position_y` = -3010.7274, `position_z` = 388.4308, `orientation` = 1.8763, `rotation0` = 0.024881996438814044, `rotation1` = 0.6924965616933979, `rotation2` = 0.2951423079295177, `rotation3` = 0.6578148800126664 WHERE `guid` = 6941185 AND `id` = 95524;

-- #12089
-- pickup 6940950 (Bear Left Overs) moved 0.42 yd up out of the ground
UPDATE `gameobject` SET `position_x` = -5814.6, `position_y` = -258.2, `position_z` = 353.21, `orientation` = 6.0879, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.097473, `rotation3` = -0.995238 WHERE `guid` = 6940950 AND `id` = 95681;

-- #12088
-- pickup 6941321 (Warm Whoolies) moved 3.3 yd across and 0.78 yd up onto the ground, checked in the editor
UPDATE `gameobject` SET `position_x` = -5746.8358, `position_y` = -371.4732, `position_z` = 366.9209, `orientation` = 5.0409, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.581969, `rotation3` = -0.813211 WHERE `guid` = 6941321 AND `id` = 95679;

-- #12080
-- pickup 6941197 (Black Powder Sack) moved 17.1 yd across and 20.89 yd up from under the ship into it, at its Ascension position
UPDATE `gameobject` SET `position_x` = -14928.543, `position_y` = 84.57, `position_z` = 3.46, `orientation` = 1.86, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.801611, `rotation3` = 0.597846 WHERE `guid` = 6941197 AND `id` = 95762;

-- #12078
-- pickup 6941280 (Tribal Runners) moved 15.9 yd across and 0.01 yd down to its Ascension position on the ground
UPDATE `gameobject` SET `position_x` = -12625.549, `position_y` = -108.174, `position_z` = 15.875, `orientation` = 0.0947, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.047347, `rotation3` = 0.998878 WHERE `guid` = 6941280 AND `id` = 95764;

-- #12075
-- Wreckage Piece copy in Northshire; 6941035 in Loch Modan is the Ascension one
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` IN (6941036) AND `id` IN (95531);
