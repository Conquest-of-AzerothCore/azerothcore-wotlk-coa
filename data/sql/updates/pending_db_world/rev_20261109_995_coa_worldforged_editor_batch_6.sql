-- Worldforged pickups reviewed in the world editor (batch 6): positions checked against the Ascension
-- catalogue, LootCollector and the reports; a misplaced duplicate spawn hidden instead of deleted.

-- #11820
-- pickup 6941313 (Empty Sack) moved 36.0 yd across and 0.33 yd up to its Ascension position
UPDATE `gameobject` SET `position_x` = 1774.725, `position_y` = -1862.0174, `position_z` = 73.0311, `orientation` = 5.16438, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.53068, `rotation3` = -0.847572 WHERE `guid` = 6941313 AND `id` = 340044;
-- the plague wagon and barrel next to the sack were missing (Ascension positions)
-- Scourge Body Wagon
DELETE FROM `gameobject` WHERE `guid` = 6976006;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976006, 190575, 0, 1, 1, 1776.889, -1863.691, 72.203, 5.16438, 0, 0, 0.53068, -0.847572, 300, 100, 1);
-- Plague Barrel
DELETE FROM `gameobject` WHERE `guid` = 6976007;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976007, 193414, 0, 1, 1, 1776.3, -1863.48, 72.989, 5.16438, 0, 0, 0.53068, -0.847572, 300, 100, 1);

-- #11797
-- pickup 6941648 (Doomwarden) moved 12.7 yd across and 7.41 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -2014.859, `position_y` = 1926.0041, `position_z` = 71.2119, `orientation` = 2.807448, `rotation0` = -0.406886, `rotation1` = 0.560093, `rotation2` = 0.527353, `rotation3` = 0.492584 WHERE `guid` = 6941648 AND `id` = 254287;
