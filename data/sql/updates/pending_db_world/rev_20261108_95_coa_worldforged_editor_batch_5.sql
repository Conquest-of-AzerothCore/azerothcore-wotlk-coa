-- Worldforged pickups reviewed in the world editor (batch 5): positions checked against the Ascension
-- catalogue, LootCollector and the reports; misplaced duplicate spawns hidden instead of deleted.

-- #6735 #7864
-- copies of other zones' pickups imported to Dun Morogh: 6940023 (Old Crossbow), 6941286 (Ulag's Other Cleaver), 6941330 (Floating Barrel), 6941331 (Floating Barrel), 6940804 (Forsaken Cart Crate) hidden, not deleted
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` IN (6940023, 6941286, 6941330, 6941331, 6940804) AND `id` IN (95803, 515405, 517351, 517352);

-- #7237
-- pickup 6941417 (Teldrassil Skewer) moved 12.0 yd across and 0.50 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 5200.8114, `position_y` = 255.5983, `position_z` = 34.926, `orientation` = 2.805369, `rotation0` = 0.116328, `rotation1` = 0.685437, `rotation2` = 0.708647, `rotation3` = 0.120267 WHERE `guid` = 6941417 AND `id` = 518305;
-- the merchant cart and crate the skewer leaned on were missing (Ascension positions, adjusted in the editor)
-- Elf Crate 01 next to the skewer
DELETE FROM `gameobject` WHERE `guid` = 6976004;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976004, 179971, 1, 1, 1, 5200.440471, 255.580729, 34.086, 1.486536, 0, 0, 0.676698, 0.736261, 300, 100, 1);
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`) VALUES (3297126, 5, 1029654, 'Night Elf Cart', 1, 0, 0, '', '') ON DUPLICATE KEY UPDATE `type` = 5, `displayId` = 1029654, `name` = 'Night Elf Cart', `size` = 1;
DELETE FROM `gameobject` WHERE `guid` = 6976003;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES (6976003, 3297126, 1, 1, 1, 5201.485306, 256.8455, 34.117395, 1.553366, 0, 0, 0.700917, 0.713242, 300, 100, 1);

-- #8420
-- pickup 6942306 (The Wingman) moved 8.9 yd across and 0.79 yd down to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -10083.3, `position_y` = -4170.7, `position_z` = 2.6922, `orientation` = 2.01255, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.844845, `rotation3` = 0.535011 WHERE `guid` = 6942306 AND `id` = 515801;

-- #10478
-- pickup 6941033 (Fishing Box) moved 11.9 yd across and 0.41 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = 1299.087, `position_y` = -2188.949, `position_z` = 53.106, `orientation` = 5.81458, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.232165, `rotation3` = -0.972676 WHERE `guid` = 6941033 AND `id` = 340115;

-- #10604
-- second Gravesword left after the first was moved: 6941265 (Gravesword) hidden, not deleted
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` IN (6941265) AND `id` IN (518052);

-- #10923
-- pickup 6940028 (Ladel) moved 25.8 yd across and 18.07 yd up to the spot checked in the editor
UPDATE `gameobject` SET `position_x` = -13781.7138, `position_y` = -214.3342, `position_z` = 28.4171, `orientation` = 5.36533, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.442987, `rotation3` = -0.896528 WHERE `guid` = 6940028 AND `id` = 515466;
