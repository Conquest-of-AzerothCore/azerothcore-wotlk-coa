-- Bromgar Stonewind (164298) stood inside the high elf chair at the Namarien Sanctuary table. She now sits in it facing
-- the table: seat collision 0.42 yd above the floor, root on the floor 0.15 yd behind the seat centre (the dwarf chair
-- sit, stand state 5, carries the hips forward of the root); fitted in game.
UPDATE `creature` SET `position_x` = -7570.350, `position_y` = 101.330, `position_z` = 267.690, `orientation` = 4.7124
WHERE `guid` = 9960949 AND `id` = 164298;

DELETE FROM `creature_addon` WHERE `guid` = 9960949;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960949, 0, 0, 5, 1, 0, 0, '');
