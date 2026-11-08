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
