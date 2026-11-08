-- Worldforged pickups reviewed in the world editor (batch 4): positions, sizes and models checked against
-- LootCollector and the reports, and misplaced duplicate spawns hidden instead of deleted.

-- #11197
-- pickup 6942140 (Scarab Smasher) moved 70.3 yd across and 9.42 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -8074.4856, `position_y` = 1703.7052, `position_z` = 25.3299, `orientation` = 1.75607, `rotation0` = -0.184684, `rotation1` = 0.577097, `rotation2` = 0.449774, `rotation3` = 0.656166 WHERE `guid` = 6942140 AND `id` = 686877;
-- creature 42763 (Jonathan the Revelator) stood floating next to the Scarab Smasher: set on the ground
UPDATE `creature` SET `position_x` = -8071.4737, `position_y` = 1700.8625, `position_z` = 24.5805, `orientation` = 4.76475 WHERE `guid` = 42763 AND `id` = 15693;

-- #11201
-- pickup 6940795 (Ring of the Jungle) moved 11.0 yd across and 14.80 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -12367.8783, `position_y` = -734.0621, `position_z` = 33.9647, `orientation` = 1.22969, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.576832, `rotation3` = 0.816863 WHERE `guid` = 6940795 AND `id` = 254349;

-- #11235
-- pickup 6970042 (Brambleblade Blade) moved 29.2 yd across and 0.99 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -4931.6629, `position_y` = -2277.9665, `position_z` = -65.5449, `orientation` = 6.165028, `rotation0` = -0.0421068, `rotation1` = 0.436118, `rotation2` = -0.0204341, `rotation3` = 0.898672 WHERE `guid` = 6970042 AND `id` = 9900038;

-- #11250
-- pickup 6940946 (Red Metal Pauldrons) moved 0.8 yd across and 0.12 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 3007.2122, `position_y` = -2736.0122, `position_z` = 129.5041, `orientation` = 4.01963, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.905169, `rotation3` = -0.425051 WHERE `guid` = 6940946 AND `id` = 1345112;

-- #11274
-- pickup 6941160 (Stonesplitter) moved 11.4 yd across and 0.21 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -13232.8017, `position_y` = -483.0316, `position_z` = 6.0350, `orientation` = 3.29389, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.997102, `rotation3` = -0.076075 WHERE `guid` = 6941160 AND `id` = 95759;

-- #11359
-- pickup 6942308 (The Wrath of Arkkoroc) moved 20.6 yd across and 24.75 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 3857.9727, `position_y` = -7172.1229, `position_z` = 24.9720, `orientation` = 3.336149, `rotation0` = 0.69502, `rotation1` = 0.0678245, `rotation2` = 0.7124, `rotation3` = -0.0695206 WHERE `guid` = 6942308 AND `id` = 254430;

-- #11401
-- template 1345147 (Terrible Defias Mixture): size 1 -> 0.5 (1 spawns)
UPDATE `gameobject_template` SET `size` = 0.5 WHERE `entry` = 1345147;
-- pickup 6941205 (Terrible Defias Mixture) moved 20.4 yd across and 5.17 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -11142.2382, `position_y` = 544.9816, `position_z` = 36.9810, `orientation` = 0.562727, `rotation0` = 0.149573, `rotation1` = -0.515723, `rotation2` = 0.23454, `rotation3` = 0.810338 WHERE `guid` = 6941205 AND `id` = 1345147;

-- no issue
-- template 9900034 (Steel Helmet): displayId 515290 -> 515287 (1 spawns)
UPDATE `gameobject_template` SET `displayId` = 515287 WHERE `entry` = 9900034;
-- pickup 209574 (Gold Vein) moved 3.59 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -14643.3000, `position_y` = 481.6200, `position_z` = 20.2087, `orientation` = 2.72271, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.978148, `rotation3` = 0.207912 WHERE `guid` = 209574 AND `id` = 1734;
-- pickup 209618 (Truesilver Deposit) moved 3.87 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -14643.3000, `position_y` = 481.6200, `position_z` = 19.9253, `orientation` = 2.72271, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.978148, `rotation3` = 0.207912 WHERE `guid` = 209618 AND `id` = 2047;
-- pickup 209530 (Mithril Deposit) moved 3.58 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -14643.3000, `position_y` = 481.6200, `position_z` = 20.2104, `orientation` = 2.72271, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.978148, `rotation3` = 0.207912 WHERE `guid` = 209530 AND `id` = 2040;
-- pickup 6970037 (Steel Helmet) moved 6.8 yd across and 17.64 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -4947.1627, `position_y` = -2293.9843, `position_z` = -82.1888, `orientation` = 0.839312, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.407446, `rotation3` = 0.913229 WHERE `guid` = 6970037 AND `id` = 9900034;
-- pickup 6940863 (Stashed Goods) moved 0.15 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 1984.0000, `position_y` = 1596.3000, `position_z` = 82.4757, `orientation` = 1.03615, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.495209, `rotation3` = 0.868774 WHERE `guid` = 6940863 AND `id` = 95671;
