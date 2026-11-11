-- Worldforged pickups reviewed in the world editor (batch 1): positions, sizes and models checked against
-- LootCollector and the reports, and misplaced duplicate spawns hidden instead of deleted.

-- #4479
-- pickup 6942022 (Hanged Pelt) moved 17.1 yd across and 1.72 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 10026.0974, `position_y` = 285.1919, `position_z` = 1325.2444, `orientation` = 2.447056, `rotation0` = -0.225017, `rotation1` = -0.696164, `rotation2` = -0.206242, `rotation3` = 0.649759 WHERE `guid` = 6942022 AND `id` = 90551;

-- #4774
-- pickup 6942196 (Stuck Sword) moved 1.8 yd across and 3.40 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 1463.5571, `position_y` = -4701.4730, `position_z` = 4.9166, `orientation` = 1.330551, `rotation0` = -0.370696, `rotation1` = 0.47247, `rotation2` = 0.493572, `rotation3` = 0.629081 WHERE `guid` = 6942196 AND `id` = 95646;

-- #4784
-- template 340118 (Abomination Hook): size 1 -> 0.8 (1 spawns)
UPDATE `gameobject_template` SET `size` = 0.8 WHERE `entry` = 340118;
-- pickup 6940486 (Abomination Hook) moved 3.1 yd across and 2.61 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 1406.4193, `position_y` = -1282.6190, `position_z` = 63.6974, `orientation` = 0.8782, `rotation0` = -0.0210407, `rotation1` = -0.50058, `rotation2` = 0.255601, `rotation3` = 0.826829 WHERE `guid` = 6940486 AND `id` = 340118;

-- #4816
-- pickup 6942360 (Embedded Sword) moved 10.0 yd across and 8.14 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -217.3840, `position_y` = -5310.0917, `position_z` = 0.4372, `orientation` = 4.463721, `rotation0` = 0.113488, `rotation1` = -0.711815, `rotation2` = 0.227171, `rotation3` = -0.654853 WHERE `guid` = 6942360 AND `id` = 95622;

-- #4823
-- pickup 6941411 (Apprentice's Harpoon) moved 2.8 yd across and 0.05 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -1058.4698, `position_y` = -4777.9313, `position_z` = 17.2490, `orientation` = 4.26674, `rotation0` = -0.0998524, `rotation1` = -0.701235, `rotation2` = -0.194933, `rotation3` = 0.678455 WHERE `guid` = 6941411 AND `id` = 95640;

-- #4851
-- pickup 6941861 (Idol of the Ocean's Depths) moved 18.9 yd across and 33.51 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 4007.5049, `position_y` = -7129.8877, `position_z` = 24.8407, `orientation` = 2.919134, `rotation0` = 0.00531745, `rotation1` = -0.000593907, `rotation2` = 0.993806, `rotation3` = 0.110998 WHERE `guid` = 6941861 AND `id` = 1345076;

-- #4894
-- pickup 6942249 (Stormscale Supplies) moved 9.1 yd across to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 7363.5514, `position_y` = -920.2340, `position_z` = 10.2180, `orientation` = 4.720023, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.704403, `rotation3` = -0.709801 WHERE `guid` = 6942249 AND `id` = 375327;

-- #5190
-- pickup 6940643 (Idol of the Aerie) moved 4.1 yd across and 3.39 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -46.6779, `position_y` = -4898.2940, `position_z` = 23.3699, `orientation` = 5.559157, `rotation0` = -0.726603, `rotation1` = 0.0346161, `rotation2` = 0.686185, `rotation3` = 0.000635621 WHERE `guid` = 6940643 AND `id` = 95794;

-- #5579
-- pickup 6940876 (Peculiar Gold Nugget) moved 8.8 yd across and 7.21 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -10558.0607, `position_y` = 1991.1986, `position_z` = -14.0901, `orientation` = 2.95216, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.995518, `rotation3` = 0.094575 WHERE `guid` = 6940876 AND `id` = 90244;

-- #6089
-- pickup 6940055 (Sunken Stash) moved 6.5 yd across and 1.60 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 28.7522, `position_y` = -3775.9517, `position_z` = 136.9218, `orientation` = 0.23541, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.117433, `rotation3` = 0.993081 WHERE `guid` = 6940055 AND `id` = 254573;

-- #6522
-- pickup 6942045 (Feeding Pile) moved 17.7 yd across and 8.58 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -8214.7939, `position_y` = -1592.7333, `position_z` = -203.0017, `orientation` = 5.642196, `rotation0` = 0.161805, `rotation1` = 0.00107755, `rotation2` = 0.318537, `rotation3` = -0.933998 WHERE `guid` = 6942045 AND `id` = 95937;

-- #6558
-- template 515828 (Captain's Compass): size 1 -> 0.7 (1 spawns)
UPDATE `gameobject_template` SET `size` = 0.7 WHERE `entry` = 515828;
-- pickup 6941523 (Captain's Compass) moved 10.1 yd across and 1.73 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -8015.3655, `position_y` = -5193.8004, `position_z` = 14.8455, `orientation` = 1.67885, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.744259, `rotation3` = 0.667891 WHERE `guid` = 6941523 AND `id` = 515828;

-- #6735
-- pickup 6940734 (Rusty Shotgun) moved 10.5 yd across and 2.62 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 2911.9517, `position_y` = 375.5602, `position_z` = 32.7246, `orientation` = 4.711447, `rotation0` = -0.101454, `rotation1` = 0.0307977, `rotation2` = 0.706768, `rotation3` = -0.699456 WHERE `guid` = 6940734 AND `id` = 517353;
-- pickup 6940021 (Agamand Dresser) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6940021 AND `id` = 515370;
-- pickup 6940732 (Rusty Shotgun) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6940732 AND `id` = 517353;

-- #7370
-- pickup 6960004 (Bloodied Axe) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6960004 AND `id` = 93008;

-- #7488
-- pickup 6942243 (Hanging Ogre Pouch) moved 4.6 yd across and 1.46 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -4001.4296, `position_y` = 304.4279, `position_z` = 59.7854, `orientation` = 0.22169, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.110618, `rotation3` = 0.993863 WHERE `guid` = 6942243 AND `id` = 96103;

-- #7700
-- template 1345084 (Libram of Resolute Light): size 1 -> 0.7 (1 spawns)
UPDATE `gameobject_template` SET `size` = 0.7 WHERE `entry` = 1345084;
-- pickup 6940703 (Libram of Resolute Light) moved 11.8 yd across and 109.76 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -685.9327, `position_y` = -3783.5016, `position_z` = 229.0637, `orientation` = 1.95887, `rotation0` = 0.394944, `rotation1` = 0.588126, `rotation2` = 0.585928, `rotation3` = 0.393467 WHERE `guid` = 6940703 AND `id` = 1345084;

-- #7702
-- template 1345163 (Wand of the Broodbound): size 1 -> 0.5 (1 spawns)
UPDATE `gameobject_template` SET `size` = 0.5 WHERE `entry` = 1345163;
-- pickup 6941320 (Wand of the Broodbound) moved 14.7 yd across and 65.81 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -760.6532, `position_y` = -3791.7767, `position_z` = 234.7217, `orientation` = 3.904247, `rotation0` = 0.406178, `rotation1` = -0.557785, `rotation2` = 0.714832, `rotation3` = -0.113622 WHERE `guid` = 6941320 AND `id` = 1345163;

-- #7741
-- pickup 6940495 (Forbidden Fruit) moved 1.6 yd across and 0.10 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 1552.5447, `position_y` = -3811.4318, `position_z` = 115.9059, `orientation` = 6.23936, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.021911, `rotation3` = -0.99976 WHERE `guid` = 6940495 AND `id` = 90480;
-- pickup 6941743 (Forbidden Fruit) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6941743 AND `id` = 90480;
-- pickup 6940494 (Forbidden Fruit) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6940494 AND `id` = 90480;

-- #7742
-- pickup 6941906 (Magnify Glass) moved 7.8 yd across and 4.10 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -6728.4526, `position_y` = -4716.7856, `position_z` = 24.7109, `orientation` = 0.253263, `rotation0` = -0.739137, `rotation1` = -0.0819755, `rotation2` = 0.0976903, `rotation3` = 0.661373 WHERE `guid` = 6941906 AND `id` = 515835;

-- #7856, #10853
-- pickup 6941179 (Intact Plate Helm) moved 1.1 yd across and 0.87 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -1251.9875, `position_y` = -1607.9724, `position_z` = 50.9242, `orientation` = 1.12556, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.533539, `rotation3` = 0.845775 WHERE `guid` = 6941179 AND `id` = 95865;
-- skeleton wearing the Intact Plate Helm, own template so its size never touches the other Sitting Skeleton 01 spawns
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(9900048, 5, 7308, 'Sitting Skeleton 01', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `size` = VALUES(`size`);
DELETE FROM `gameobject` WHERE `guid` = 6976000;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(6976000, 9900048, 0, 0, 0, 1, 1, -1252.0372, -1607.9080, 50.06, 1.128609, 0, 0, 0.534828, 0.844961, 300, 100, 1, '', NULL, 'Skeleton under the Intact Plate Helm');
-- template 95865 (Intact Plate Helm): size 1 -> 1.25 so the helm sits over the skull
UPDATE `gameobject_template` SET `size` = 1.25 WHERE `entry` = 95865;

-- #7862, #7864
-- pickup 6940532 (Shallow Grave) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6940532 AND `id` = 517354;
-- pickup 6940846 (Wheel) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6940846 AND `id` = 515345;
-- pickup 6940847 (Wheel) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6940847 AND `id` = 515345;

-- #7886
-- pickup 6942434 (Highborne Momento) moved 15.5 yd across and 5.25 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 6340.7366, `position_y` = -3869.7164, `position_z` = 687.8125, `orientation` = 0.66858, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.328099, `rotation3` = 0.944643 WHERE `guid` = 6942434 AND `id` = 96226;

-- #7889
-- pickup 6941505 (Adventurer's Backpack) moved 6.8 yd across and 5.25 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -5375.5455, `position_y` = 270.3399, `position_z` = 25.7813, `orientation` = 1.20845, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.568124, `rotation3` = 0.822943 WHERE `guid` = 6941505 AND `id` = 96141;

-- #7902
-- pickup 6940536 (Ghoul-Stitched Shoulders) moved 3.8 yd across and 0.27 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 1590.6304, `position_y` = -914.4513, `position_z` = 64.7401, `orientation` = 3.31423, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.996277, `rotation3` = -0.086212 WHERE `guid` = 6940536 AND `id` = 735901;

-- #7964
-- template 90387 (Elune Tear Fragment): size 1 -> 0.2 (1 spawns)
UPDATE `gameobject_template` SET `size` = 0.2 WHERE `entry` = 90387;
-- pickup 6941681 (Elune Tear Fragment) moved 12.2 yd across and 3.19 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 2904.0117, `position_y` = -971.6407, `position_z` = 202.3337, `orientation` = 2.27933, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.908494, `rotation3` = 0.417899 WHERE `guid` = 6941681 AND `id` = 90387;

-- #8057
-- pickup 6940195 (Boom Barrel) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6940195 AND `id` = 95526;

-- #8172
-- template 3244513 (Jar of Spiders): size 1 -> 0.2 (2 spawns)
UPDATE `gameobject_template` SET `size` = 0.2 WHERE `entry` = 3244513;

-- #8188
-- pickup 6941410 (Apprentice Staff) moved 0.8 yd across and 1.21 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -296.5522, `position_y` = -4331.1618, `position_z` = 58.8337, `orientation` = 5.434536, `rotation0` = 0.336952, `rotation1` = 0.466957, `rotation2` = 0.407561, `rotation3` = -0.708737 WHERE `guid` = 6941410 AND `id` = 95670;

-- #8328
-- template 520071 (Vulture Effigy): displayId 188302 -> 1044834; size 1 -> 0.9 (1 spawns)
UPDATE `gameobject_template` SET `displayId` = 1044834, `size` = 0.9 WHERE `entry` = 520071;
-- pickup 6942392 (Vulture Effigy) moved 2.9 yd across and 2.01 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 10602.6398, `position_y` = 462.9497, `position_z` = 1394.8924, `orientation` = 3.244403, `rotation0` = -0.00131207, `rotation1` = 0.000437435, `rotation2` = 0.998678, `rotation3` = -0.0513817 WHERE `guid` = 6942392 AND `id` = 520071;

-- #8329
-- pickup 6941543 (Carrion Eye) moved 1.3 yd across to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 10837.5602, `position_y` = 524.2728, `position_z` = 1398.2700, `orientation` = 5.51525, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.374602, `rotation3` = -0.927186 WHERE `guid` = 6941543 AND `id` = 520067;
