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
