-- Dun Kazad flights (#9903, #9615, #10708). On the realm, Gryphon Master Stonefeather (164405) serves Dun Kazad from
-- the courtyard inside the mountain (2r0PE1dBarE_002816) and the client routes leave through the cave. rev_20261018_80
-- moved the Graysky routes 1987/1988 to Moer Stonefist's roost, so flights from Stonefeather cut straight through the
-- mountain to the roost. Restore the client routes, keep the Graysky tower landing of #9226, and end the Graysky and
-- Ironforge (1990) flights on the courtyard floor beside Stonefeather instead of 10 yd past its edge, where players
-- fell 18-35 yd. Moer (165622) shares taxi node 421, so his take-off would now cut through the rock; he no longer
-- offers flights (rev_20261108_9949 removes his roost).
DELETE FROM `taxipathnode_dbc` WHERE `ID` IN (39819, 39928, 39934, 39929, 39935, 39820, 39930, 39933, 39932, 39821, 39822, 39823, 39824, 39825, 39794, 39795, 39796, 39797, 39798, 39799, 39800, 39801, 39802, 39803, 39804, 39805, 39806, 39807, 39826, 39827, 39828, 39829, 39830, 39831, 39832, 39833, 39834, 39835, 39836, 39837, 39838, 39839, 39840, 39841, 39842, 39843, 39844, 39808, 39809, 39810, 39811, 39812, 39813, 39814, 39815, 39816, 39817, 39818, 39881, 39882);
INSERT INTO `taxipathnode_dbc` (`ID`, `PathID`, `NodeIndex`, `ContinentID`, `LocX`, `LocY`, `LocZ`, `Flags`, `Delay`, `ArrivalEventID`, `DepartureEventID`) VALUES
(39844, 1988, 32, 0, -7042.01, 1127.80, 328.9, 0, 0, 0, 0),
(39817, 1987, 23, 0, -6491.00, -268.00, 582.0, 0, 0, 0, 0),
(39818, 1987, 24, 0, -6483.00, -268.50, 577.1, 0, 0, 0, 0),
(39881, 1990, 38, 0, -6491.00, -268.00, 582.0, 0, 0, 0, 0),
(39882, 1990, 39, 0, -6483.00, -268.50, 577.1, 0, 0, 0, 0);
UPDATE `creature_template` SET `npcflag` = 1 WHERE `entry` = 165622;

-- Copper Veins over the Grik'nir ice cave (Md_Icecave.wmo, #10591): rev_20261027_60 took their height from the terrain,
-- so 40 of them sit on the mountain 55-270 yd above the cave, most on faces too steep to climb. The 19 veins within
-- 100 yd outside the cave are all at valley height, so these belong on the cave floor: same spot, or within 2 yd.
UPDATE `gameobject` SET `position_z` = 389.87 WHERE `guid` = 12007920 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 383.39 WHERE `guid` = 12007988 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 388.30 WHERE `guid` = 12007989 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 385.55 WHERE `guid` = 12007990 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 382.36 WHERE `guid` = 12007993 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 390.92 WHERE `guid` = 12007996 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 391.14 WHERE `guid` = 12007997 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 390.97 WHERE `guid` = 12007998 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 394.38 WHERE `guid` = 12007999 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 386.97 WHERE `guid` = 12008002 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 390.71 WHERE `guid` = 12008004 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 373.96 WHERE `guid` = 12008007 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 391.46 WHERE `guid` = 12008008 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 375.21 WHERE `guid` = 12008012 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 387.11 WHERE `guid` = 12008013 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 382.46 WHERE `guid` = 12008017 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 373.87 WHERE `guid` = 12008018 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 387.61 WHERE `guid` = 12008019 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 371.87 WHERE `guid` = 12008021 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 388.26 WHERE `guid` = 12008023 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 382.58 WHERE `guid` = 12008025 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 371.51 WHERE `guid` = 12008029 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 385.99 WHERE `guid` = 12008049 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 387.92 WHERE `guid` = 12008052 AND `id` = 1731;
UPDATE `gameobject` SET `position_z` = 386.00 WHERE `guid` = 12008053 AND `id` = 1731;
UPDATE `gameobject` SET `position_x` = -6521.55, `position_y` = 399.66, `position_z` = 383.47 WHERE `guid` = 12007987 AND `id` = 1731;
UPDATE `gameobject` SET `position_x` = -6574.63, `position_y` = 378.96, `position_z` = 392.29 WHERE `guid` = 12007994 AND `id` = 1731;
UPDATE `gameobject` SET `position_x` = -6509.97, `position_y` = 358.27, `position_z` = 373.97 WHERE `guid` = 12008001 AND `id` = 1731;
UPDATE `gameobject` SET `position_x` = -6554.93, `position_y` = 359.27, `position_z` = 392.45 WHERE `guid` = 12008003 AND `id` = 1731;
UPDATE `gameobject` SET `position_x` = -6549.36, `position_y` = 350.42, `position_z` = 392.50 WHERE `guid` = 12008005 AND `id` = 1731;
UPDATE `gameobject` SET `position_x` = -6525.38, `position_y` = 339.57, `position_z` = 374.29 WHERE `guid` = 12008009 AND `id` = 1731;
UPDATE `gameobject` SET `position_x` = -6563.20, `position_y` = 340.28, `position_z` = 389.29 WHERE `guid` = 12008010 AND `id` = 1731;
UPDATE `gameobject` SET `position_x` = -6522.10, `position_y` = 319.88, `position_z` = 374.28 WHERE `guid` = 12008014 AND `id` = 1731;
UPDATE `gameobject` SET `position_x` = -6573.63, `position_y` = 319.88, `position_z` = 393.25 WHERE `guid` = 12008015 AND `id` = 1731;
UPDATE `gameobject` SET `position_x` = -6543.51, `position_y` = 304.39, `position_z` = 383.29 WHERE `guid` = 12008022 AND `id` = 1731;
UPDATE `gameobject` SET `position_x` = -6536.23, `position_y` = 296.26, `position_z` = 382.61 WHERE `guid` = 12008026 AND `id` = 1731;
UPDATE `gameobject` SET `position_x` = -6545.37, `position_y` = 295.97, `position_z` = 383.85 WHERE `guid` = 12008027 AND `id` = 1731;
UPDATE `gameobject` SET `position_x` = -6502.40, `position_y` = 292.06, `position_z` = 370.70 WHERE `guid` = 12008028 AND `id` = 1731;
UPDATE `gameobject` SET `position_x` = -6525.67, `position_y` = 291.04, `position_z` = 382.74 WHERE `guid` = 12008030 AND `id` = 1731;
UPDATE `gameobject` SET `position_x` = -6558.21, `position_y` = 416.63, `position_z` = 385.88 WHERE `guid` = 12008050 AND `id` = 1731;
