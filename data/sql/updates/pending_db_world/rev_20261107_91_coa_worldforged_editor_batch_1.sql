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
-- template 515828 (Captain\'s Compass): size 1 -> 0.7 (1 spawns)
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
