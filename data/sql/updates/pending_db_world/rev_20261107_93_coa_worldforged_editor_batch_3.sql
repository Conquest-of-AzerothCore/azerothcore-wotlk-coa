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

-- #10630
-- pickup 6940485 (Flayer's Helmet) moved 0.2 yd across and 0.28 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 1753.8239, `position_y` = -1133.1192, `position_z` = 61.5667, `orientation` = 1.79949, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.783168, `rotation3` = 0.62181 WHERE `guid` = 6940485 AND `id` = 340068;

-- #10653
-- pickup 6942406 (Alchemist Cache) moved 27.1 yd across to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -7683.7707, `position_y` = -4266.2539, `position_z` = 10.5920, `orientation` = 5.452117, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.403679, `rotation3` = -0.914901 WHERE `guid` = 6942406 AND `id` = 515742;

-- #10740, #11340
-- pickup 6940442 (Eroded Pit Fighter Knuckles) moved 8.3 yd across and 0.06 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -498.3902, `position_y` = -1562.4511, `position_z` = 52.5904, `orientation` = 4.95517, `rotation0` = 0.540102, `rotation1` = -0.422655, `rotation2` = 0.44851, `rotation3` = -0.573142 WHERE `guid` = 6940442 AND `id` = 515386;

-- #10771
-- pickup 6941252 (Tilloa's Flowers) moved 18.0 yd across and 1.09 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -10373.5141, `position_y` = -1254.2955, `position_z` = 37.6732, `orientation` = 4.48359, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.783201, `rotation3` = -0.621768 WHERE `guid` = 6941252 AND `id` = 95825;

-- #10832, #10888
-- pickup 6940983 (Rugged Leather Runners) moved 25.5 yd across and 29.99 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -11354.6597, `position_y` = -246.7811, `position_z` = 47.4797, `orientation` = 4.19247, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.865104, `rotation3` = -0.501593 WHERE `guid` = 6940983 AND `id` = 254354;

-- #10869
-- pickup 6940784 (Murloc Crown) moved 2.1 yd across and 2.07 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -10038.0948, `position_y` = -4310.4067, `position_z` = 3.4909, `orientation` = 3.52196, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.98197, `rotation3` = -0.189039 WHERE `guid` = 6940784 AND `id` = 254394;

-- #10918
-- pickup 6942283 (Discarded Wand) moved 36.9 yd across and 1.91 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -2253.4172, `position_y` = -2389.7135, `position_z` = 93.9540, `orientation` = 2.354208, `rotation0` = 0.323827, `rotation1` = 0.779596, `rotation2` = 0.205635, `rotation3` = -0.495056 WHERE `guid` = 6942283 AND `id` = 97116;

-- #10938
-- pickup 6941136 (Splinterspear Armor Crate) moved 1.3 yd across and 0.05 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -10397.4809, `position_y` = -2614.6986, `position_z` = 41.0717, `orientation` = 6.235741, `rotation0` = 0.00179477, `rotation1` = 0.0756431, `rotation2` = -0.0236521, `rotation3` = 0.996853 WHERE `guid` = 6941136 AND `id` = 254378;

-- #10941
-- pickup 6940851 (Old Crate) moved 17.7 yd across and 0.52 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -11139.7759, `position_y` = -3166.7492, `position_z` = 9.8843, `orientation` = 2.38275, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.928879, `rotation3` = 0.370383 WHERE `guid` = 6940851 AND `id` = 96194;

-- #10954
-- pickup 6941098 (Jewelled Ring) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6941098 AND `id` = 68394;

-- #10955
-- pickup 6941369 (Warder's Cache) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6941369 AND `id` = 95902;

-- #10959
-- pickup 6940636 (Hull Breaker) moved 22.6 yd across and 0.32 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -14678.4505, `position_y` = 500.5863, `position_z` = 2.9927, `orientation` = 0.430102, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.213397, `rotation3` = 0.976965 WHERE `guid` = 6940636 AND `id` = 95710;

-- #10960
-- pickup 6940715 (Waterproof Trunk) moved 13.3 yd across and 0.62 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -1925.9785, `position_y` = -2474.6365, `position_z` = 42.4156, `orientation` = 6.08626, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.098304, `rotation3` = -0.995156 WHERE `guid` = 6940715 AND `id` = 95876;

-- #10979
-- pickup 6941445 (Blade of Thunder) moved 3.8 yd across and 2.88 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -394.8158, `position_y` = 1853.2276, `position_z` = 129.6771, `orientation` = 2.710688, `rotation0` = -0.547586, `rotation1` = -0.437935, `rotation2` = 0.655352, `rotation3` = -0.28085 WHERE `guid` = 6941445 AND `id` = 254264;

-- #11016
-- pickup 6940523 (Spare Equipment) moved 4.3 yd across and 0.33 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -9057.7807, `position_y` = 147.0395, `position_z` = 115.0235, `orientation` = 1.60014, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.717404, `rotation3` = 0.696657 WHERE `guid` = 6940523 AND `id` = 95686;

-- #11044
-- pickup 6940136 (Plagued Bow) moved 9.7 yd across and 4.25 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 1868.0237, `position_y` = -3188.1495, `position_z` = 131.1175, `orientation` = 1.546897, `rotation0` = -0.00884178, `rotation1` = -0.00830129, `rotation2` = 0.698557, `rotation3` = 0.715451 WHERE `guid` = 6940136 AND `id` = 96236;

-- #11068
-- template 1345129 (Silken Travel Gloves): size 1 -> 0.4 (1 spawns)
UPDATE `gameobject_template` SET `size` = 0.4 WHERE `entry` = 1345129;
-- pickup 6941080 (Silken Travel Gloves) moved 7.6 yd across and 0.26 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -1766.0787, `position_y` = -2874.4441, `position_z` = 41.5836, `orientation` = 3.81393, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.944025, `rotation3` = -0.329873 WHERE `guid` = 6941080 AND `id` = 1345129;

-- #11093
-- pickup 6942107 (Ancient Statue) moved 1.7 yd across and 37.55 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -5657.6771, `position_y` = 1375.1053, `position_z` = 78.4736, `orientation` = 6.168476, `rotation0` = 0, `rotation1` = 0, `rotation2` = -0.0573231, `rotation3` = 0.998356 WHERE `guid` = 6942107 AND `id` = 96111;

-- #11116
-- pickup 6940924 (Radiant Rifle) moved 39.1 yd across and 14.43 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -5962.1306, `position_y` = 428.5849, `position_z` = 522.8098, `orientation` = 3.463178, `rotation0` = 0.459184, `rotation1` = 0.064559, `rotation2` = 0.875369, `rotation3` = -0.136789 WHERE `guid` = 6940924 AND `id` = 520073;

-- #11144
-- template 95756 (Encased Amulet): size 1 -> 0.7 (1 spawns)
UPDATE `gameobject_template` SET `size` = 0.7 WHERE `entry` = 95756;
-- pickup 6940435 (Encased Amulet) moved 11.0 yd across and 1.52 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -13255.8701, `position_y` = -354.3124, `position_z` = 13.9959, `orientation` = 3.017202, `rotation0` = 0.21629, `rotation1` = -0.025285, `rotation2` = 0.973948, `rotation3` = 0.0632857 WHERE `guid` = 6940435 AND `id` = 95756;

-- #11150
-- pickup 6940843 (Storage Crate) moved 3.8 yd across and 3.32 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -5206.1882, `position_y` = -3100.0369, `position_z` = 303.3347, `orientation` = 1.25241, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.586074, `rotation3` = 0.810257 WHERE `guid` = 6940843 AND `id` = 517341;
-- pickup 6940844 (Storage Crate) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6940844 AND `id` = 517341;

-- #11161
-- pickup 6940613 (Heavy Ogre Axe) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6940613 AND `id` = 95519;

-- #11163
-- pickup 6975021 (Morin's Jug) moved 13.7 yd across and 3.38 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -705.3076, `position_y` = -536.4640, `position_z` = 27.1831, `orientation` = 6.283185, `rotation0` = 0.16543, `rotation1` = -0.683375, `rotation2` = 0.163354, `rotation3` = 0.69206 WHERE `guid` = 6975021 AND `id` = 1345092;

-- #11169
-- pickup 6941086 (Sinter Wive's Rope) moved 1.20 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -5204.2000, `position_y` = -3535.0000, `position_z` = 305.2797, `orientation` = 3.57389, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.976731, `rotation3` = -0.21447 WHERE `guid` = 6941086 AND `id` = 375024;
-- pickup 6941087 (Sinter Wive's Rope) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6941087 AND `id` = 375024;

-- #11172
-- pickup 6940064 (Apprentice Staff) is a misplaced duplicate: hidden (spawnMask 0), kept in the table
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6940064 AND `id` = 95670;
