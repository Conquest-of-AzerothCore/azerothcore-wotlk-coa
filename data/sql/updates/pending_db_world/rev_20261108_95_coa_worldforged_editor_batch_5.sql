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
