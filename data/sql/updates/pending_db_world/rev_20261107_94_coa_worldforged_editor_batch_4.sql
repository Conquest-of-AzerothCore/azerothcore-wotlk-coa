-- Worldforged pickups reviewed in the world editor (batch 4): positions, sizes and models checked against
-- LootCollector and the reports, and misplaced duplicate spawns hidden instead of deleted.

-- #11197
-- pickup 6942140 (Scarab Smasher) moved 70.3 yd across and 9.42 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -8074.4856, `position_y` = 1703.7052, `position_z` = 25.3299, `orientation` = 1.75607, `rotation0` = -0.184684, `rotation1` = 0.577097, `rotation2` = 0.449774, `rotation3` = 0.656166 WHERE `guid` = 6942140 AND `id` = 686877;
-- creature 42763 (Jonathan the Revelator) stood floating next to the Scarab Smasher: set on the ground
UPDATE `creature` SET `position_x` = -8071.4737, `position_y` = 1700.8625, `position_z` = 24.5805, `orientation` = 4.76475 WHERE `guid` = 42763 AND `id` = 15693;
