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

-- #12098
-- pickup 6941019 (Slightly-Damaged Chest) moved 16.4 yd across and 6.22 yd down to the ground, checked in the editor
UPDATE `gameobject` SET `position_x` = 2087.626, `position_y` = -1530.4155, `position_z` = 66.256, `orientation` = 3.6325, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.970026, `rotation3` = -0.243001 WHERE `guid` = 6941019 AND `id` = 96243;

-- #12097
-- pickup 6940496 (Foreman's Lightcap) moved 3.1 yd across and 2.12 yd up to its Ascension position on top of the crates
UPDATE `gameobject` SET `position_x` = -788.01, `position_y` = 68.039, `position_z` = 11.2038, `orientation` = 2.1028, `rotation0` = -0.04608232114189615, `rotation1` = 0.03148145269994918, `rotation2` = 0.8666500829296354, `rotation3` = 0.4957852070928823 WHERE `guid` = 6940496 AND `id` = 515403;
-- the Ascension pick axe next to the pickup was missing
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`) VALUES (3242246, 5, 1020314, 'Pick Axe', 1.5, 0, 0, '', '') ON DUPLICATE KEY UPDATE `type` = 5, `displayId` = 1020314, `name` = 'Pick Axe', `size` = 1.5, `Data0` = 0, `Data1` = 0, `AIName` = '', `ScriptName` = '';
-- Pick Axe
DELETE FROM `gameobject` WHERE `guid` = 6976011;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976011, 3242246, 0, 1, 1, -788.48, 67.559, 9.796, 5.4056, 0, 0, 0.424865, -0.905257, 300, 100, 1);
-- the pickup stands on crates in Ascension (no position data: two stacked under it and one beside)
-- Salvage Crate
DELETE FROM `gameobject` WHERE `guid` = 6976012;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976012, 188076, 0, 1, 1, -788.01, 68.039, 9.053, 5.4056, 0, 0, 0.424865, -0.905257, 300, 100, 1);
-- Salvage Crate
DELETE FROM `gameobject` WHERE `guid` = 6976013;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976013, 188076, 0, 1, 1, -788.01, 68.039, 10.083, 5.4056, 0, 0, 0.424865, -0.905257, 300, 100, 1);
-- Salvage Crate
DELETE FROM `gameobject` WHERE `guid` = 6976014;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976014, 188076, 0, 1, 1, -786.75, 69, 9.05, 5.4056, 0, 0, 0.424865, -0.905257, 300, 100, 1);
