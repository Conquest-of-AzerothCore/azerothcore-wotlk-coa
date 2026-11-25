DELETE FROM `gameobject_template` WHERE `entry` = 501007;
DROP TEMPORARY TABLE IF EXISTS `tmp_go`;
CREATE TEMPORARY TABLE `tmp_go` SELECT * FROM `gameobject_template` WHERE `entry` = 90389;
UPDATE `tmp_go` SET `entry` = 501007, `name` = 'Darrow Silverband', `displayId` = 1010746, `Data1` = 501007;
INSERT INTO `gameobject_template` SELECT * FROM `tmp_go`;
DROP TEMPORARY TABLE `tmp_go`;

DELETE FROM `gameobject_template_addon` WHERE `entry` = 501007;
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`, `mingold`, `maxgold`, `artkit0`, `artkit1`, `artkit2`, `artkit3`)
SELECT 501007, `faction`, `flags`, `mingold`, `maxgold`, `artkit0`, `artkit1`, `artkit2`, `artkit3` FROM `gameobject_template_addon` WHERE `entry` = 90389;

DELETE FROM `gameobject_loot_template` WHERE `Entry` = 501007;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(501007, 521235, 0, 100, 0, 1, 0, 1, 1, 'Darrow Silverband - Darrow Silverband');

DELETE FROM `gameobject_template` WHERE `entry` = 1344800;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(1344800, 3, 63520, 'Moonbathed Necklace', '', '', '', 0.55, 1689, 1344800, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', 'worldforged_pickup', NULL);

DELETE FROM `gameobject` WHERE `guid` = 12101056;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(12101056, 501007, 0, 0, 0, 1, 1, -488.5555484383908, 112.55596513239377, 61.57746410803078, 2.6518111163360225, 0, 0, 0.970164, 0.24245, 300, 100, 1, '', NULL, 'Darrow Silverband (replaces Ring of Druidic Whispers)');

UPDATE `gameobject` SET `position_x` = 577.7413920233148, `position_y` = 1577.7562886503847, `position_z` = 132.788, `orientation` = 4.415274288465383, `rotation0` = 0, `rotation1` = 0, `rotation2` = -0.8039784015418685, `rotation3` = 0.5946584985133755 WHERE `guid` = 33508;
UPDATE `gameobject` SET `position_x` = 580.445067179812, `position_y` = 1576.3898184023, `position_z` = 132.788, `orientation` = 3.9785584233664255, `rotation0` = 0, `rotation1` = 0, `rotation2` = -0.9137065088202663, `rotation3` = 0.40637472330286567 WHERE `guid` = 33516;
UPDATE `gameobject` SET `position_x` = 579.1614171556525, `position_y` = 1577.2452208754441, `position_z` = 132.796, `orientation` = 4.304196909028494, `rotation0` = 0, `rotation1` = 0, `rotation2` = -0.83574834383146, `rotation3` = 0.5491126530894839 WHERE `guid` = 33852;
UPDATE `gameobject` SET `position_x` = 575.3504578108469, `position_y` = 1568.54719390113, `position_z` = 132.788, `orientation` = 3.12417612684797, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.9999620833141465, `rotation3` = 0.008708153307804403 WHERE `guid` = 33853;
UPDATE `gameobject` SET `position_x` = 1081.7775506602934, `position_y` = -415.867094575605, `position_z` = 69.55238199132334, `orientation` = 3.4383, `rotation0` = 0, `rotation1` = 0, `rotation2` = -0.989016, `rotation3` = 0.147811 WHERE `guid` = 202853;
UPDATE `gameobject` SET `position_x` = 894.2207445656762, `position_y` = -558.5230811832992, `position_z` = 141.9398966011417, `orientation` = 1.090296646520575, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.5185449200692368, `rotation3` = 0.8550503879131272 WHERE `guid` = 6940111;
UPDATE `gameobject` SET `position_x` = 884.6131878806335, `position_y` = -113.01356113538914, `position_z` = 39.652069338446275, `orientation` = 4.395963227043412, `rotation0` = -0.0595434547377995, `rotation1` = -0.7030363700964681, `rotation2` = 0.18019589990895957, `rotation3` = -0.6853640470403082 WHERE `guid` = 6940563;
UPDATE `gameobject` SET `position_x` = -552.5286205431289, `position_y` = -854.0094543716548, `position_z` = 6.067, `orientation` = 1.4823071906335474, `rotation0` = -0.23267519732624434, `rotation1` = -0.21294600421936621, `rotation2` = -0.6406771028982231, `rotation3` = -0.7000350717343659 WHERE `guid` = 6940841;
UPDATE `gameobject` SET `position_x` = -8085.087316250461, `position_y` = -1883.3084229433641, `position_z` = 183.7759449483477, `orientation` = 4.636373076839233, `rotation0` = -0.6810316476062785, `rotation1` = 0.24619020151946253, `rotation2` = 0.6773750093095875, `rotation3` = -0.12941938184568966 WHERE `guid` = 6941105;
UPDATE `gameobject` SET `position_x` = 6247.095792067239, `position_y` = -4390.2329895492985, `position_z` = 690.2723331382853, `orientation` = 3.9925103161687123, `rotation0` = 0.6416085962503251, `rotation1` = 0.2907360052783257, `rotation2` = 0.6465176968249376, `rotation3` = -0.2929604958772882 WHERE `guid` = 6941421;
UPDATE `gameobject` SET `position_x` = 10706.5, `position_y` = 769.057, `position_z` = 1322.8324004513972, `orientation` = 3.14116, `rotation0` = 0, `rotation1` = 0, `rotation2` = 1, `rotation3` = 0.0002141 WHERE `guid` = 6941964;
UPDATE `gameobject` SET `position_x` = 6003.610806272314, `position_y` = -4098.781127268401, `position_z` = 605.5180133159338, `orientation` = 0.5851888192836515, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.28843733709958547, `rotation3` = 0.9574987741855863 WHERE `guid` = 6942247;
UPDATE `gameobject` SET `position_x` = 1277.6920147000599, `position_y` = 1283.08, `position_z` = 52.83508033149102, `orientation` = 0, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0, `rotation3` = 1 WHERE `guid` = 6970025;

UPDATE `creature` SET `position_x` = 522.449, `position_y` = 1626.15, `position_z` = 102.71740254613039, `orientation` = 1.48353 WHERE `guid` = 17611;
UPDATE `creature` SET `position_x` = 515.935018406306, `position_y` = 1625.1707470147521, `position_z` = 126.00965292826525, `orientation` = 4.37993 WHERE `guid` = 17612;
UPDATE `creature` SET `position_x` = 533.7263705064793, `position_y` = 1537.9369976436788, `position_z` = 134.4464163421312, `orientation` = 1.3556484379140035 WHERE `guid` = 17613;
UPDATE `creature` SET `position_x` = 565.0559240376525, `position_y` = 1597.1244928611802, `position_z` = 131.32584291798787, `orientation` = 4.79220203399565 WHERE `guid` = 17619;
UPDATE `creature` SET `position_x` = 552.8727691184394, `position_y` = 1536.7163095307299, `position_z` = 134.890647598025, `orientation` = 2.2414074189469106 WHERE `guid` = 17620;
UPDATE `creature` SET `position_x` = 575.442794770119, `position_y` = 1593.5943067367707, `position_z` = 132.48260840512592, `orientation` = 3.536043388391099 WHERE `guid` = 17621;
UPDATE `creature` SET `position_x` = 530.4211801743317, `position_y` = 1633.3051962141146, `position_z` = 103.31240272521973, `orientation` = 5.08670462860176 WHERE `guid` = 17622;
UPDATE `creature` SET `position_x` = 572.9000718179002, `position_y` = 1577.2428497313888, `position_z` = 132.20329816963994, `orientation` = 3.4618000949244365 WHERE `guid` = 17623;
UPDATE `creature` SET `position_x` = 573.4018052270482, `position_y` = 1556.4434354322193, `position_z` = 133.52060685826973, `orientation` = 3.235284674340979 WHERE `guid` = 17624;
UPDATE `creature` SET `position_x` = 574.3605701965055, `position_y` = 1573.20539120045, `position_z` = 132.63305396274816, `orientation` = 0.8631122454173749 WHERE `guid` = 17625;
UPDATE `creature` SET `position_x` = 480.31042583154886, `position_y` = 1533.2501821869494, `position_z` = 130.9321234138077, `orientation` = 0.453786 WHERE `guid` = 17626;
UPDATE `creature` SET `position_x` = 525.8940487137014, `position_y` = 1626.0996677231262, `position_z` = 103.31240272521973, `orientation` = 2.16421 WHERE `guid` = 17631;
UPDATE `creature` SET `position_x` = 572.0694576973328, `position_y` = 1541.9913052950192, `position_z` = 134.1583877570952, `orientation` = 2.5336644112825915 WHERE `guid` = 17642;
UPDATE `creature` SET `position_x` = 541.5447630631083, `position_y` = 1536.4747973940732, `position_z` = 134.9189840416016, `orientation` = 1.5285216520290579 WHERE `guid` = 17644;
UPDATE `creature` SET `position_x` = 513.679, `position_y` = 1625.1, `position_z` = 125.90333583829846, `orientation` = 4.57276 WHERE `guid` = 17645;
UPDATE `creature` SET `position_x` = 531.7754456793504, `position_y` = 1631.4178101176585, `position_z` = 103.31240272521973, `orientation` = 2.54818 WHERE `guid` = 17646;
UPDATE `creature` SET `position_x` = 532.9164025183512, `position_y` = 1581.1764376711199, `position_z` = 127.4742505174523, `orientation` = 6.24828 WHERE `guid` = 17868;
