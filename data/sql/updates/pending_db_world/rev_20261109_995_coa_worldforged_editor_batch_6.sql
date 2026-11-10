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

-- #11787
-- pickup 6940799 (Left Behind Boots) moved 27.2 yd across and 4.94 yd up to its Ascension position on the dock
UPDATE `gameobject` SET `position_x` = -11583.41, `position_y` = -38.3, `position_z` = 10.94, `orientation` = 0.49008, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.242595, `rotation3` = 0.970128 WHERE `guid` = 6940799 AND `id` = 95740;

-- #11781
-- pickup 6942169 (Unearthed Treasures) moved 21.2 yd across and 165.43 yd down to its Ascension position on the cave floor
UPDATE `gameobject` SET `position_x` = -5456.72, `position_y` = 128.94, `position_z` = 28.13, `orientation` = 5.21483, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.509133, `rotation3` = -0.860688 WHERE `guid` = 6942169 AND `id` = 96140;

-- #11777
-- pickup 6940837 (Old Ogre Relic) moved 82.3 yd across and 31.17 yd up to its Ascension position
UPDATE `gameobject` SET `position_x` = -7733.8024, `position_y` = -2792.3808, `position_z` = 164.6, `orientation` = 5.40399, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.425575, `rotation3` = -0.904923 WHERE `guid` = 6940837 AND `id` = 254669;
-- the relic model was far too big for a pickup; its only spawn is this one
UPDATE `gameobject_template` SET `size` = 0.3 WHERE `entry` = 254669;

-- #11766
-- pickup 6942389 (Fallen Glaive) moved 18.3 yd across and 5.09 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 3243.3101, `position_y` = -4320.4489, `position_z` = 132.3855, `orientation` = 4.469775, `rotation0` = -0.433165, `rotation1` = 0.561066, `rotation2` = 0.552553, `rotation3` = -0.438472 WHERE `guid` = 6942389 AND `id` = 254411;

-- #11778
-- pickup 6941104 (Dragon Handler's Equipment) moved 726.3 yd across and 59.69 yd down to its Ascension position, on top of two crates inside Draco'dar's hut
UPDATE `gameobject` SET `position_x` = -8347.91, `position_y` = -921.715, `position_z` = 209.0322, `orientation` = 1.588163, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.71322, `rotation3` = 0.70094 WHERE `guid` = 6941104 AND `id` = 254665;
-- the crates it rests on and the bedroll were missing from the hut (Ascension props, placed in the editor)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`) VALUES (9900051, 5, 285, 'Long Brown Crate', 1, 0, 0, '', '') ON DUPLICATE KEY UPDATE `type` = 5, `displayId` = 285, `name` = 'Long Brown Crate', `size` = 1, `Data0` = 0, `Data1` = 0, `AIName` = '', `ScriptName` = '';
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`) VALUES (9900052, 5, 1011606, 'Bedroll', 1, 0, 0, '', '') ON DUPLICATE KEY UPDATE `type` = 5, `displayId` = 1011606, `name` = 'Bedroll', `size` = 1, `Data0` = 0, `Data1` = 0, `AIName` = '', `ScriptName` = '';
-- Long Brown Crate under the pickup
DELETE FROM `gameobject` WHERE `guid` = 6976008;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976008, 9900051, 0, 1, 1, -8346.9409, -921.7269, 208.3951, 1.793379, 0, 0, 0.781265, 0.6242, 300, 100, 1);
-- second Long Brown Crate under the pickup
DELETE FROM `gameobject` WHERE `guid` = 6976010;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976010, 9900051, 0, 1, 1, -8348.3716, -921.8816, 208.4069, 1.45618, 0, 0, 0.665445, 0.746447, 300, 100, 1);
-- Bedroll
DELETE FROM `gameobject` WHERE `guid` = 6976009;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976009, 9900052, 0, 1, 1, -8354.11, -910.969, 208.3964, 0, 0, 0, 0, 1, 300, 100, 1);

-- #11774
-- duplicate of the Casket Will pickup 6941339 (the one at the Ascension position): 6960034 hidden, not deleted
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` IN (6960034) AND `id` IN (90281);

-- #11808
-- pickup 6942017 (Owlbeast Talon) moved 9.5 yd across and 0.31 yd up to out of the rock it was buried in
UPDATE `gameobject` SET `position_x` = 7650.2247, `position_y` = -4919.5979, `position_z` = 697.0921, `orientation` = 2.68263, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.973785, `rotation3` = 0.227472 WHERE `guid` = 6942017 AND `id` = 1345104;

-- #11826
-- pickup 6941796 (Grimtotem Bow) moved 14.0 yd across and 0.65 yd down to the tent next to Sage Nauchol, where LootCollector records it
UPDATE `gameobject` SET `position_x` = -3628.5142, `position_y` = -1028.2337, `position_z` = 203.9655, `orientation` = 0.381159, `rotation0` = -0.761488, `rotation1` = 0.08334, `rotation2` = 0.391572, `rotation3` = 0.509766 WHERE `guid` = 6941796 AND `id` = 520699;

-- #11835
-- the copy on the ground below the tower: 6942160 (Sharpened Pike) hidden, not deleted
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` IN (6942160) AND `id` IN (95831);
-- pickup 6942161 (Sharpened Pike) moved 11.3 yd across and 0.70 yd down to the tower floor (it hung 0.8 yd above it)
UPDATE `gameobject` SET `position_x` = 1239.0983, `position_y` = -2205.9413, `position_z` = 113.516, `orientation` = 3.039075, `rotation0` = 0.030973, `rotation1` = 0.603709, `rotation2` = 0.795557, `rotation3` = 0.040815 WHERE `guid` = 6942161 AND `id` = 95831;
