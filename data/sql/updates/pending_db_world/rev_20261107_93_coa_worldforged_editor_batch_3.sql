-- Worldforged pickups reviewed in the world editor (batch 3): positions, sizes and models checked against
-- LootCollector and the reports, and misplaced duplicate spawns hidden instead of deleted.

-- #10465
-- pickup 6970018 (Champion's Band) moved 2.2 yd across to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 6136.2900, `position_y` = -1517.9923, `position_z` = 440.8850, `orientation` = 0, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0, `rotation3` = 1 WHERE `guid` = 6970018 AND `id` = 9900020;
-- pickup 6940796 (Shining Necklace) moved 3.6 yd across and 0.52 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 6135.3237, `position_y` = -1516.6354, `position_z` = 441.3366, `orientation` = 1.148519, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.543213, `rotation3` = 0.839595 WHERE `guid` = 6940796 AND `id` = 96161;
