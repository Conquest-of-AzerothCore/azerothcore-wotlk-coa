-- Worldforged pickups reviewed in the world editor (batch 3): positions, sizes and models checked against
-- LootCollector and the reports, and misplaced duplicate spawns hidden instead of deleted.

-- #10465
-- pickup 6970018 (Champion's Band) moved 2.2 yd across to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 6136.2900, `position_y` = -1517.9923, `position_z` = 440.8850, `orientation` = 0, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0, `rotation3` = 1 WHERE `guid` = 6970018 AND `id` = 9900020;
-- pickup 6940796 (Shining Necklace) moved 3.6 yd across and 0.52 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 6135.3237, `position_y` = -1516.6354, `position_z` = 441.3366, `orientation` = 1.148519, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.543213, `rotation3` = 0.839595 WHERE `guid` = 6940796 AND `id` = 96161;

-- #10483
-- pickup 6940646 (Totem of the Flowing River) moved 1.6 yd across and 1.44 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 321.0562, `position_y` = -1465.9578, `position_z` = 43.9157, `orientation` = 3.048732, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.998922, `rotation3` = 0.0464137 WHERE `guid` = 6940646 AND `id` = 1345154;

-- #10501
-- pickup 6940849 (Free Book) moved 8.2 yd across and 1.25 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -9547.6208, `position_y` = -2233.6335, `position_z` = 88.0005, `orientation` = 3.00079, `rotation0` = -0.0459186, `rotation1` = -0.00323807, `rotation2` = 0.996465, `rotation3` = 0.0702684 WHERE `guid` = 6940849 AND `id` = 254551;

-- #10506
-- pickup 6940537 (Chainmail Gauntlets) moved turned to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -10415.5000, `position_y` = -2020.5700, `position_z` = 93.1403, `orientation` = 3.81489, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.943867, `rotation3` = -0.330326 WHERE `guid` = 6940537 AND `id` = 90508;

-- #10604
-- pickup 6940572 (Gravesword) moved 1.2 yd across to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -7103.6983, `position_y` = -3492.3236, `position_z` = 243.4000, `orientation` = 0.980417, `rotation0` = -0.474102, `rotation1` = -0.583181, `rotation2` = 0.308458, `rotation3` = -0.583078 WHERE `guid` = 6940572 AND `id` = 518052;
