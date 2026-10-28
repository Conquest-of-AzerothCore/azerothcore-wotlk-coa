-- Objects around Tiraxis and the Mythic+, Mark and Raid vendors, placed in game (Stormwind and Orgrimmar).
-- Decorative templates: generic (type 5) and not selectable (flags 16), so no name or cursor shows on hover.
-- 9500200/9500201: model 7089 at sizes 3.5 and 2; 9500202-9500205: Ethereal props; 9500209-9500211: supplies;
-- 9500213: small brazier at 0.9.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`) VALUES
(9500200, 5, 7089, 'Ethereal Containment Cylinder', '', '', '', 3.5),
(9500201, 5, 7089, 'Ethereal Containment Cylinder', '', '', '', 2.0),
(9500202, 5, 7088, 'Ethereal Technology', '', '', '', 1.0),
(9500203, 5, 7089, 'Ethereal Technology', '', '', '', 1.0),
(9500204, 5, 7137, 'Ethereal Distiller', '', '', '', 1.0),
(9500205, 5, 7166, 'Ethereal Repair Kit', '', '', '', 1.0),
(9500209, 5, 1013843, 'Clan Supplies', '', '', '', 1.0),
(9500210, 5, 1013842, 'Clan Supplies', '', '', '', 1.0),
(9500211, 5, 1011027, 'Earthen Supplies', '', '', '', 1.0),
(9500213, 5, 351, 'Small Brazier', '', '', '', 0.9) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `size` = VALUES(`size`);

DELETE FROM `gameobject_template_addon` WHERE `entry` IN (9500200, 9500201, 9500202, 9500203, 9500204, 9500205, 9500209, 9500210, 9500211, 9500213);
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`) VALUES
(9500200, 0, 16),
(9500201, 0, 16),
(9500202, 0, 16),
(9500203, 0, 16),
(9500204, 0, 16),
(9500205, 0, 16),
(9500209, 0, 16),
(9500210, 0, 16),
(9500211, 0, 16),
(9500213, 0, 16);

-- Spawns: Tiraxis' props and cylinders (Stormwind 9020001-9020005, Orgrimmar 9020006-9020012), a stone bench and two
-- braziers by the Stormwind vendors, supplies and a brazier by the Orgrimmar vendors.
DELETE FROM `gameobject` WHERE `guid` IN (9020001, 9020002, 9020003, 9020004, 9020005, 9020006, 9020007, 9020008, 9020009, 9020010, 9020011, 9020012, 9020013, 9020014, 9020015, 9020016, 9020017, 9020018, 9020019);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9020001, 9500202, 0, 0, 0, 1, 1, -8804.28, 672.026, 96.2004, 1.94892, 0.0, 0.0, 0.8274, 0.561614, 300, 0, 1, '', NULL, NULL),
(9020002, 9500202, 0, 0, 0, 1, 1, -8802.09, 670.654, 96.2021, 3.70743, 0.0, 0.0, 0.960244, -0.279161, 300, 0, 1, '', NULL, NULL),
(9020003, 9500205, 0, 0, 0, 1, 1, -8801.16, 669.654, 96.2016, 4.40251, 0.0, 0.0, 0.807758, -0.589514, 300, 0, 1, '', NULL, NULL),
(9020004, 9500204, 0, 0, 0, 1, 1, -8800.37, 668.382, 96.2016, 3.34615, 0.0, 0.0, 0.994774, -0.1021, 300, 0, 1, '', NULL, NULL),
(9020005, 9500200, 0, 1519, 0, 1, 1, -8802.93, 672.0, 96.2015, 0.0, 0.0, 0.0, 0.0, 1.0, 300, 0, 1, '', NULL, NULL),
(9020006, 9500202, 1, 0, 0, 1, 1, 1675.64, -4433.63, 19.6083, 2.2753, 0.0, 0.0, 0.907649, 0.419731, 300, 0, 1, '', NULL, NULL),
(9020007, 9500202, 1, 0, 0, 1, 1, 1682.93, -4437.76, 19.5007, 0.492441, 0.0, 0.0, 0.24374, 0.969841, 300, 0, 1, '', NULL, NULL),
(9020008, 9500204, 1, 0, 0, 1, 1, 1685.11, -4438.53, 19.4816, 3.40627, 0.0, 0.0, 0.991256, -0.131952, 300, 0, 1, '', NULL, NULL),
(9020009, 9500202, 1, 0, 0, 1, 1, 1685.36, -4440.43, 19.3924, 3.26882, 0.0, 0.0, 0.997977, -0.063572, 300, 0, 1, '', NULL, NULL),
(9020010, 9500201, 1, 0, 0, 1, 1, 1683.26, -4439.91, 19.3545, 2.55804, 0.0, 0.0, 0.957734, 0.287655, 300, 0, 1, '', NULL, NULL),
(9020011, 9500203, 1, 0, 0, 1, 1, 1679.78, -4435.18, 23.079, 4.43514, 0.0, 0.0, 0.798031, -0.602617, 300, 0, 1, '', NULL, NULL),
(9020012, 9500205, 1, 0, 0, 1, 1, 1678.78, -4437.13, 19.418, 4.18381, 0.0, 0.0, 0.867267, -0.497844, 300, 0, 1, '', NULL, NULL),
(9020013, 24622, 0, 0, 0, 1, 1, -8377.04, 330.452, 147.014, 3.8284, 0.0, 0.0, 0.941615, -0.336692, 300, 0, 1, '', NULL, NULL),
(9020014, 9500213, 0, 0, 0, 1, 1, -8376.06, 326.579, 147.014, 0.682899, 0.0, 0.0, 0.334853, 0.94227, 300, 0, 1, '', NULL, NULL),
(9020015, 9500213, 0, 0, 0, 1, 1, -8380.33, 332.05, 147.013, 0.604359, 0.0, 0.0, 0.297602, 0.95469, 300, 0, 1, '', NULL, NULL),
(9020016, 9500209, 1, 0, 0, 1, 1, 1901.52, -4160.9, 41.26, 5.56377, -0.013422, -0.003423, -0.35205, 0.935879, 300, 100, 1, '', NULL, NULL),
(9020017, 9500210, 1, 0, 0, 1, 1, 1898.84, -4153.65, 41.38, 0.04525, 0.000915, -0.050395, 0.022583, 0.998474, 300, 100, 1, '', NULL, NULL),
(9020018, 9500213, 1, 0, 0, 1, 1, 1898.66, -4150.15, 41.3, 0.218702, 0.0, 0.0, 0.109133, 0.994027, 300, 100, 1, '', NULL, NULL),
(9020019, 9500211, 0, 0, 0, 1, 1, -8373.71, 317.41, 147.01, 2.71534, 0.0, 0.0, 0.977374, 0.211516, 300, 100, 1, '', NULL, NULL);

-- Stormwind Keep: the vendor corner gives way (three benches out), and every wooden bench becomes a stone bench.
-- The stone bench sits further from its pivot, so each moves 0.66 yd forward to stay out of the wall.
DELETE FROM `gameobject` WHERE `guid` IN (26479, 26484, 26488, 26489, 26501);
UPDATE `gameobject` SET `id` = 24622, `position_x` = -8412.2, `position_y` = 325.653 WHERE `guid` = 13936;
UPDATE `gameobject` SET `id` = 24622, `position_x` = -8413.17, `position_y` = 317.311 WHERE `guid` = 13943;
UPDATE `gameobject` SET `id` = 24622, `position_x` = -8407.53, `position_y` = 319.583 WHERE `guid` = 13945;
UPDATE `gameobject` SET `id` = 24622, `position_x` = -8409.2, `position_y` = 321.683 WHERE `guid` = 13946;
UPDATE `gameobject` SET `id` = 24622, `position_x` = -8397.7, `position_y` = 297.851 WHERE `guid` = 26480;
UPDATE `gameobject` SET `id` = 24622, `position_x` = -8389.53, `position_y` = 297.096 WHERE `guid` = 26487;
UPDATE `gameobject` SET `id` = 24622, `position_x` = -8392.81, `position_y` = 301.036 WHERE `guid` = 26490;
UPDATE `gameobject` SET `id` = 24622, `position_x` = -8402.54, `position_y` = 333.333 WHERE `guid` = 26491;
UPDATE `gameobject` SET `id` = 24622, `position_x` = -8394.48, `position_y` = 303.126 WHERE `guid` = 26492;
UPDATE `gameobject` SET `id` = 24622, `position_x` = -8379.87, `position_y` = 304.786 WHERE `guid` = 26495;
UPDATE `gameobject` SET `id` = 24622, `position_x` = -8370.07, `position_y` = 312.576 WHERE `guid` = 26502;
UPDATE `gameobject` SET `id` = 24622, `position_x` = -8369.15, `position_y` = 320.519 WHERE `guid` = 26509;
UPDATE `gameobject` SET `id` = 24622, `position_x` = -8384.63, `position_y` = 339.979 WHERE `guid` = 26510;
UPDATE `gameobject` SET `id` = 24622, `position_x` = -8392.74, `position_y` = 341.133 WHERE `guid` = 26511;

-- Orgrimmar: the Kor'kron Elite where the brazier now stands.
DELETE FROM `creature_addon` WHERE `guid` = 3379;
DELETE FROM `creature` WHERE `guid` = 3379;
