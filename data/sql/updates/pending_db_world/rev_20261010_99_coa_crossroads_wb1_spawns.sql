-- Patch-WB1 rebuilt the Crossroads: the inn, the smithy and Darsok's tower moved and new buildings went up.
-- Quest NPCs move to their client QuestSuperTrack points; spawns inside the moved buildings move with them.
UPDATE `creature` SET `position_x` = -446.088, `position_y` = -2570.020, `position_z` = 99.210
WHERE `guid` = 13982 AND `id` = 3390;
UPDATE `creature` SET `position_x` = -516.888, `position_y` = -2597.390, `position_z` = 129.469
WHERE `guid` = 14415 AND `id` = 3449;
UPDATE `creature` SET `position_x` = -517.348, `position_y` = -2641.890, `position_z` = 95.789
WHERE `guid` = 14348 AND `id` = 3432;
UPDATE `creature` SET `position_x` = -346.630, `position_y` = -2566.440, `position_z` = 97.360
WHERE `guid` = 15096 AND `id` = 3483;
UPDATE `creature` SET `position_x` = -447.605, `position_y` = -2696.820, `position_z` = 97.414
WHERE `guid` = 15104 AND `id` = 3489;
UPDATE `creature` SET `position_x` = -541.919, `position_y` = -2664.000, `position_z` = 95.787
WHERE `guid` = 14411 AND `id` = 3448;
UPDATE `creature` SET `position_x` = -481.527, `position_y` = -2594.870, `position_z` = 103.450
WHERE `guid` = 14344 AND `id` = 3429;
UPDATE `creature` SET `position_x` = -546.279, `position_y` = -2640.230, `position_z` = 96.011
WHERE `guid` = 15097 AND `id` = 3484;
UPDATE `creature` SET `position_x` = -340.379, `position_y` = -2560.455, `position_z` = 97.941, `orientation` = 3.27332
WHERE `guid` = 15086 AND `id` = 3477;
UPDATE `creature` SET `position_x` = -337.583, `position_y` = -2577.492, `position_z` = 97.670, `orientation` = 3.01152
WHERE `guid` = 15087 AND `id` = 3478;
UPDATE `creature` SET `position_x` = -398.454, `position_y` = -2643.520, `position_z` = 96.298, `orientation` = 3.38173
WHERE `guid` = 14139 AND `id` = 3934;
UPDATE `creature` SET `position_x` = -384.422, `position_y` = -2640.589, `position_z` = 96.298, `orientation` = 3.20720
WHERE `guid` = 20944 AND `id` = 5871;
UPDATE `creature` SET `position_x` = -512.311, `position_y` = -2591.056, `position_z` = 129.536, `orientation` = 2.04802
WHERE `guid` = 19424 AND `id` = 3501;
UPDATE `gameobject` SET `position_x` = -337.850, `position_y` = -2570.223, `position_z` = 95.787,
`orientation` = 3.35186, `rotation2` = 0.994478, `rotation3` = -0.104942 WHERE `guid` = 13155 AND `id` = 50983;
UPDATE `gameobject` SET `position_x` = -336.024, `position_y` = -2576.091, `position_z` = 97.692,
`orientation` = 1.25747, `rotation2` = 0.588122, `rotation3` = 0.808772 WHERE `guid` = 15739 AND `id` = 51702;
UPDATE `gameobject` SET `position_x` = -336.574, `position_y` = -2562.502, `position_z` = 97.961,
`orientation` = 5.32409, `rotation2` = 0.461378, `rotation3` = -0.887203 WHERE `guid` = 15741 AND `id` = 51703;
UPDATE `gameobject` SET `position_x` = -396.258, `position_y` = -2643.264, `position_z` = 96.210,
`orientation` = 3.31191, `rotation2` = 0.996376, `rotation3` = -0.085058 WHERE `guid` = 13171 AND `id` = 149038;
UPDATE `gameobject` SET `position_x` = -414.383, `position_y` = -2665.926, `position_z` = 95.893,
`orientation` = 4.55109, `rotation2` = 0.761773, `rotation3` = -0.647844 WHERE `guid` = 13320 AND `id` = 3662;
UPDATE `gameobject` SET `position_x` = -394.498, `position_y` = -2631.425, `position_z` = 96.348,
`orientation` = 6.21789, `rotation2` = 0.032643, `rotation3` = -0.999467 WHERE `guid` = 13359 AND `id` = 106325;
UPDATE `gameobject` SET `position_x` = -389.770, `position_y` = -2655.911, `position_z` = 96.348,
`orientation` = 5.43249, `rotation2` = 0.412638, `rotation3` = -0.910895 WHERE `guid` = 13361 AND `id` = 106326;
UPDATE `gameobject` SET `position_x` = -383.526, `position_y` = -2634.690, `position_z` = 96.348,
`orientation` = 6.21789, `rotation2` = 0.032643, `rotation3` = -0.999467 WHERE `guid` = 13364 AND `id` = 106327;
UPDATE `gameobject` SET `position_x` = -404.873, `position_y` = -2655.547, `position_z` = 96.348,
`orientation` = 5.43249, `rotation2` = 0.412638, `rotation3` = -0.910895 WHERE `guid` = 13386 AND `id` = 106335;
UPDATE `gameobject` SET `position_x` = -381.757, `position_y` = -2644.957, `position_z` = 96.348,
`orientation` = 0.26631, `rotation2` = 0.132763, `rotation3` = 0.991148 WHERE `guid` = 13387 AND `id` = 106336;
UPDATE `gameobject` SET `position_x` = -402.677, `position_y` = -2647.768, `position_z` = 96.033,
`orientation` = 6.22661, `rotation2` = 0.028282, `rotation3` = -0.999600 WHERE `guid` = 6942191 AND `id` = 520698;
UPDATE `gameobject` SET `position_x` = -415.030, `position_y` = -2633.988, `position_z` = 95.677,
`orientation` = 0.15995, `rotation2` = 0.079889, `rotation3` = 0.996804 WHERE `guid` = 7905402 AND `id` = 402001;
