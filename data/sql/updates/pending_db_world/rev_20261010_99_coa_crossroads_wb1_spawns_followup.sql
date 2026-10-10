-- Spawns that patch-WB1 geometry encloses move to the nearest free floor; spawns facing a wall turn to open ground.
UPDATE `creature` SET `position_x` = -384.722, `position_y` = -2620.500, `position_z` = 96.132
WHERE `guid` = 15077 AND `id` = 5774;
UPDATE `creature` SET `position_x` = -380.531, `position_y` = -2624.695, `position_z` = 96.133
WHERE `guid` = 15078 AND `id` = 5774;
UPDATE `creature` SET `position_x` = -451.520, `position_y` = -2686.506, `position_z` = 96.114, `orientation` = 0.34907
WHERE `guid` = 15091 AND `id` = 3480;
UPDATE `creature` SET `orientation` = 1.48353 WHERE `guid` = 15098 AND `id` = 3485;
UPDATE `creature` SET `position_x` = -539.841, `position_y` = -2671.980, `position_z` = 95.784
WHERE `guid` = 15099 AND `id` = 3486;
UPDATE `creature` SET `position_x` = -550.864, `position_y` = -2673.950, `position_z` = 96.036
WHERE `guid` = 15101 AND `id` = 3487;
UPDATE `creature` SET `position_x` = -518.717, `position_y` = -2604.890, `position_z` = 111.419, `orientation` = 0.08727
WHERE `guid` = 19425 AND `id` = 3501;
UPDATE `creature` SET `orientation` = 1.74533 WHERE `guid` = 9950008 AND `id` = 642827;
UPDATE `creature` SET `position_x` = -446.847, `position_y` = -2583.061, `position_z` = 96.055, `orientation` = 2.79253
WHERE `guid` = 9950044 AND `id` = 342828;

-- Patch-WB1 moved the Crossroads signpost (yaw +9.845 degrees) and scaled it by 2055/1024; its arms follow.
UPDATE `gameobject_template` SET `size` = 2 WHERE `entry` IN (4097, 4098, 4099, 4100, 4104, 4105, 4106);
UPDATE `gameobject` SET `position_x` = -453.471, `position_y` = -2653.385, `position_z` = 102.378,
`orientation` = 1.74263, `rotation2` = 0.765175, `rotation3` = 0.643822 WHERE `guid` = 12670 AND `id` = 4097;
UPDATE `gameobject` SET `position_x` = -451.556, `position_y` = -2649.998, `position_z` = 102.287,
`orientation` = 3.31342, `rotation2` = 0.996312, `rotation3` = -0.085807 WHERE `guid` = 12684 AND `id` = 4098;
UPDATE `gameobject` SET `position_x` = -456.823, `position_y` = -2651.421, `position_z` = 102.301,
`orientation` = 0.17183, `rotation2` = 0.085808, `rotation3` = 0.996312 WHERE `guid` = 12690 AND `id` = 4099;
UPDATE `gameobject` SET `position_x` = -454.767, `position_y` = -2648.172, `position_z` = 102.305,
`orientation` = 4.88421, `rotation2` = 0.643825, `rotation3` = -0.765173 WHERE `guid` = 12692 AND `id` = 4100;
UPDATE `gameobject` SET `position_x` = -451.555, `position_y` = -2650.018, `position_z` = 100.616,
`orientation` = 3.31342, `rotation2` = 0.996312, `rotation3` = -0.085807 WHERE `guid` = 12701 AND `id` = 4104;
UPDATE `gameobject` SET `position_x` = -456.894, `position_y` = -2651.433, `position_z` = 100.737,
`orientation` = 0.17183, `rotation2` = 0.085808, `rotation3` = 0.996312 WHERE `guid` = 12702 AND `id` = 4105;
UPDATE `gameobject` SET `position_x` = -456.874, `position_y` = -2651.409, `position_z` = 99.066,
`orientation` = 0.17183, `rotation2` = 0.085808, `rotation3` = 0.996312 WHERE `guid` = 12707 AND `id` = 4106;

-- Positions estimated from live CoA footage (YouTube 0FWGFa6FoJI, MCSLacOIU58, avKfRYJK8JY; minimap quest icons
-- matched per frame, captured 2026-10-10).
UPDATE `creature` SET `position_x` = -441.500, `position_y` = -2592.500, `position_z` = 95.840, `orientation` = 3.7001
WHERE `guid` = 13419 AND `id` = 3615;
UPDATE `creature` SET `position_x` = -425.530, `position_y` = -2642.490, `position_z` = 95.750
WHERE `guid` = 15029 AND `id` = 3464;
UPDATE `creature` SET `position_x` = -363.500, `position_y` = -2576.200, `position_z` = 96.010
WHERE `guid` = 15096 AND `id` = 3483;
UPDATE `creature` SET `position_x` = -387.300, `position_y` = -2543.800, `position_z` = 97.450, `orientation` = 4.71239
WHERE `guid` = 14334 AND `id` = 3428;
