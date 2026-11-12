-- Worldforged pickups reviewed in the world editor (batch 7): positions checked against the server floor
-- (maps + vmaps), the Ascension catalogue and LootCollector; missing Ascension props restored next to
-- their pickups; misplaced duplicate spawns hidden instead of deleted.

-- #12119
-- pickup 6942088 (Ridiculously Thick Web) moved 3.3 yd across and 0.63 yd down onto the cave floor at the LootCollector spot, checked in the editor
UPDATE `gameobject` SET `position_x` = 10947.1076, `position_y` = 884.3237, `position_z` = 1337.2487, `orientation` = 3.8209, `rotation0` = 0.21126571600859118, `rotation1` = -0.6455961588691098, `rotation2` = 0.6869038286281989, `rotation3` = -0.25833220300371124 WHERE `guid` = 6942088 AND `id` = 95614;
-- pickup 6941651 (Dripping Fang) moved 1.1 yd across and 134.61 yd down from 140 yd above the cave to its LootCollector spot in the Egg Chamber
UPDATE `gameobject` SET `position_x` = 10932.6, `position_y` = 933.4, `position_z` = 1340.61, `orientation` = 4.3301, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.828572, `rotation3` = -0.559882 WHERE `guid` = 6941651 AND `id` = 1345040;

-- #12100
-- pickup 6941017 (Garmet Supplies) moved 2.8 yd across and 0.10 yd up out of the ground, checked in the editor
UPDATE `gameobject` SET `position_x` = 2456.6999, `position_y` = -1685.6573, `position_z` = 103.3423, `orientation` = 0.1718, `rotation0` = 0, `rotation1` = 0, `rotation2` = -0.08578582856422419, `rotation3` = -0.9963136010401291 WHERE `guid` = 6941017 AND `id` = 340047;
