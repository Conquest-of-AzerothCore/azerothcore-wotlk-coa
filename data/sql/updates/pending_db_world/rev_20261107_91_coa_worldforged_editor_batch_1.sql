-- Worldforged pickups reviewed in the world editor (batch 1): positions, sizes and models checked against
-- LootCollector and the reports, and misplaced duplicate spawns hidden instead of deleted.

-- #4479
-- pickup 6942022 (Hanged Pelt) moved 17.1 yd across and 1.72 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 10026.0974, `position_y` = 285.1919, `position_z` = 1325.2444, `orientation` = 2.447056, `rotation0` = -0.225017, `rotation1` = -0.696164, `rotation2` = -0.206242, `rotation3` = 0.649759 WHERE `guid` = 6942022 AND `id` = 90551;

-- #4774
-- pickup 6942196 (Stuck Sword) moved 1.8 yd across and 3.40 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 1463.5571, `position_y` = -4701.4730, `position_z` = 4.9166, `orientation` = 1.330551, `rotation0` = -0.370696, `rotation1` = 0.47247, `rotation2` = 0.493572, `rotation3` = 0.629081 WHERE `guid` = 6942196 AND `id` = 95646;
