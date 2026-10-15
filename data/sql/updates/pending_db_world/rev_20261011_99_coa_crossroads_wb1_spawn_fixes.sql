-- Spawns left inside patch-WB1 walls, steps and tower pillars stand on clear floor.
UPDATE `creature` SET `position_x` = -451.500, `position_y` = -2682.300, `position_z` = 96.421, `orientation` = 1.57080
WHERE `guid` = 15091 AND `id` = 3480;
UPDATE `creature` SET `position_x` = -532.000, `position_y` = -2670.000, `position_z` = 95.788
WHERE `guid` = 15098 AND `id` = 3485;
UPDATE `creature` SET `position_x` = -540.600, `position_y` = -2677.500, `position_z` = 96.040, `orientation` = 3.14159
WHERE `guid` = 15099 AND `id` = 3486;
UPDATE `creature` SET `position_x` = -553.500, `position_y` = -2677.500, `position_z` = 96.040, `orientation` = 0
WHERE `guid` = 15101 AND `id` = 3487;
UPDATE `creature` SET `position_x` = -518.700, `position_y` = -2604.900, `position_z` = 123.000, `orientation` = 3.14159
WHERE `guid` = 19425 AND `id` = 3501;
UPDATE `creature` SET `position_x` = -442.662, `position_y` = -2591.550, `position_z` = 95.858, `orientation` = 5.98544
WHERE `guid` = 13419 AND `id` = 3615;

-- The Riding Wolves leave the inn foundation for the stalls of the patch-WB1 kennel.
UPDATE `creature` SET `position_x` = -509.200, `position_y` = -2705.500, `position_z` = 95.285, `orientation` = 4.71239
WHERE `guid` = 15077 AND `id` = 5774;
UPDATE `creature` SET `position_x` = -514.800, `position_y` = -2720.500, `position_z` = 94.855, `orientation` = 1.57080
WHERE `guid` = 15078 AND `id` = 5774;

-- The Alchemical Implements follow Apothecary Helbrim onto the plank table beside him.
UPDATE `gameobject` SET `position_x` = -447.278, `position_y` = -2570.732, `position_z` = 100.460,
`orientation` = 0.49900, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.246924, `rotation3` = 0.969035
WHERE `guid` = 13292 AND `id` = 4166;

-- Spawns left above or below the patch-WB1 terrain rest on the ground again.
UPDATE `gameobject` SET `position_z` = 95.338 WHERE `guid` = 13449 AND `id` = 143982;
UPDATE `gameobject` SET `position_z` = 98.653 WHERE `guid` = 13504 AND `id` = 3705;
UPDATE `creature` SET `position_z` = 95.421 WHERE `guid` = 19414 AND `id` = 3501;
UPDATE `creature` SET `position_z` = 95.881 WHERE `guid` = 19423 AND `id` = 3501;
UPDATE `creature` SET `position_z` = 96.585 WHERE `guid` = 19429 AND `id` = 3501;

-- The Silverleaf node under the longhouse floor grows behind its south wall.
UPDATE `gameobject` SET `position_x` = -560.510, `position_y` = -2704.870, `position_z` = 94.034
WHERE `guid` = 213150 AND `id` = 3725;

-- The Campfire left in the patch-WB1 walkway wall burns on open ground north of it.
UPDATE `gameobject` SET `position_x` = -389.500, `position_y` = -2709.500, `position_z` = 97.320
WHERE `guid` = 15112 AND `id` = 123328;
