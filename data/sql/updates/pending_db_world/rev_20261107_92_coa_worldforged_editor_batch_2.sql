-- Worldforged pickups reviewed in the world editor (batch 2): positions, sizes and models checked against
-- LootCollector and the reports, and misplaced duplicate spawns hidden instead of deleted.

-- #8412
-- pickup 6942411 (Water Seer's Headdress -> Mysterious Water Orb) moved 6.7 yd across and 1.70 yd up to the spot checked in the editor
UPDATE `gameobject` SET `id` = 90043, `position_x` = -211.3058, `position_y` = 2758.8038, `position_z` = 6.1927, `orientation` = 0, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0, `rotation3` = 1 WHERE `guid` = 6942411 AND `id` = 254278;
