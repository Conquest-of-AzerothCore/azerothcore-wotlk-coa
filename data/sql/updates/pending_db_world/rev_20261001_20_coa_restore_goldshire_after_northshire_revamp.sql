-- rev_20260930_98_northshire_baseline_restore and rev_20260930_99_ASC_northshire_revamp (#5764) sort after
-- the Goldshire and Elwynn files of #5833 and rewrote rows outside Northshire: the Goldshire spawns went back
-- to the stock inn layout, the Goldshire and Elwynn quest NPC models fell back to placeholder displays, the
-- Elwynn quest mobs and Goldshire's Beginner's Book were deleted, and Dun Morogh and Durotar quests lost their
-- chain links, reputation and scaling level. This re-applies the #5833 values for those rows; the revamp's
-- Northshire rows are unchanged.

-- creature positions of the Goldshire WB1 layout and the Elwynn relocations
UPDATE `creature` SET `position_x` = -9593.82, `position_y` = 48.035, `position_z` = 59.666, `orientation` = 0 WHERE `guid` = 56324 AND `id` = 14871;
UPDATE `creature` SET `position_x` = -9391.43, `position_y` = 142.467, `position_z` = 61.14, `orientation` = 4.11 WHERE `guid` = 70557 AND `id` = 15565;
UPDATE `creature` SET `position_z` = 57.33 WHERE `guid` = 79644 AND `id` = 721;
UPDATE `creature` SET `position_x` = -9483.51, `position_y` = -22.01, `orientation` = 1.2007 WHERE `guid` = 79645 AND `id` = 917;
UPDATE `creature` SET `position_x` = -9476.27, `position_y` = -4.47, `orientation` = 3.0682 WHERE `guid` = 79646 AND `id` = 2329;
UPDATE `creature` SET `position_x` = -9477.31, `position_y` = -25.63, `orientation` = 1.5672 WHERE `guid` = 79647 AND `id` = 465;
UPDATE `creature` SET `position_x` = -9414.8, `position_y` = 139.9, `position_z` = 58.46, `orientation` = 3.16 WHERE `guid` = 79648 AND `id` = 299;
UPDATE `creature` SET `position_x` = -9265.9, `position_y` = -3.8, `position_z` = 73.34, `orientation` = 5.7 WHERE `guid` = 79920 AND `id` = 299;
UPDATE `creature` SET `position_x` = -9496.06, `position_y` = 14.682, `position_z` = 56.695, `orientation` = 0.53 WHERE `guid` = 79949 AND `id` = 11940;
UPDATE `creature` SET `position_x` = -9459, `position_y` = 52.5, `position_z` = 56.58, `orientation` = 4.2 WHERE `guid` = 80332 AND `id` = 620;
UPDATE `creature` SET `position_x` = -9461.8, `position_y` = 44.434, `position_z` = 56.526, `orientation` = 0.9 WHERE `guid` = 80334 AND `id` = 240;
UPDATE `creature` SET `position_x` = -9312, `position_y` = 77.6, `position_z` = 68.11, `orientation` = 4.11 WHERE `guid` = 80341 AND `id` = 299;
UPDATE `creature` SET `position_x` = -9323.6, `position_y` = 79, `position_z` = 61.58, `orientation` = 2.74 WHERE `guid` = 80342 AND `id` = 525;
UPDATE `creature` SET `position_x` = -9336.3, `position_y` = 69.8, `position_z` = 60.76, `orientation` = 2.97 WHERE `guid` = 80343 AND `id` = 299;
UPDATE `creature` SET `position_x` = -9491.56, `position_y` = -0.91, `orientation` = 4.7262 WHERE `guid` = 80344 AND `id` = 328;
UPDATE `creature` SET `position_x` = -9490.91, `position_y` = -8.312, `position_z` = 56.339, `orientation` = 5.6862 WHERE `guid` = 80345 AND `id` = 6778;
UPDATE `creature` SET `position_x` = -9480.69, `position_y` = -18.104, `position_z` = 56.963, `orientation` = 3.138 WHERE `guid` = 80346 AND `id` = 295;
UPDATE `creature` SET `position_x` = -9480.76, `position_y` = -1.24, `position_z` = 63.82, `orientation` = 4.4644 WHERE `guid` = 80347 AND `id` = 377;
UPDATE `creature` SET `position_x` = -9482.71, `position_y` = -24.96, `orientation` = 1.5497 WHERE `guid` = 80348 AND `id` = 151;
UPDATE `creature` SET `position_x` = -9482.87, `position_y` = -34.59, `orientation` = 6.2272 WHERE `guid` = 80349 AND `id` = 3935;
UPDATE `creature` SET `position_x` = -9479.89, `position_y` = -1.924, `position_z` = 56.966, `orientation` = 3.0856 WHERE `guid` = 80350 AND `id` = 253;
UPDATE `creature` SET `position_x` = -9334.5, `position_y` = 48, `position_z` = 59.86, `orientation` = 4.33 WHERE `guid` = 80351 AND `id` = 525;
UPDATE `creature` SET `position_x` = -9482.85, `position_y` = -40.21, `orientation` = 4.6739 WHERE `guid` = 80352 AND `id` = 6374;
UPDATE `creature` SET `position_x` = -9488.67, `position_y` = -40.6, `orientation` = 5.6513 WHERE `guid` = 80353 AND `id` = 906;
UPDATE `creature` SET `position_x` = -9488.97, `position_y` = -43.91, `orientation` = 0.0488 WHERE `guid` = 80354 AND `id` = 6121;
UPDATE `creature` SET `position_x` = -9482.97, `position_y` = -39.22, `orientation` = 1.7417 WHERE `guid` = 80355 AND `id` = 1430;
UPDATE `creature` SET `position_x` = -9468.5, `position_y` = -25, `position_z` = 57.08, `orientation` = 5.97 WHERE `guid` = 80356 AND `id` = 883;
UPDATE `creature` SET `position_x` = -9466.5, `position_y` = -27.5, `position_z` = 57.13, `orientation` = 3.9 WHERE `guid` = 80357 AND `id` = 890;
UPDATE `creature` SET `position_z` = 60.05 WHERE `guid` = 80361 AND `id` = 113;
UPDATE `creature` SET `position_x` = -9563.5, `position_y` = 78, `position_z` = 58.88, `orientation` = 2 WHERE `guid` = 80365 AND `id` = 721;
UPDATE `creature` SET `position_z` = 63.22 WHERE `guid` = 80366 AND `id` = 1933;
UPDATE `creature` SET `position_z` = 59.78 WHERE `guid` = 80695 AND `id` = 113;
UPDATE `creature` SET `position_z` = 59.66 WHERE `guid` = 80699 AND `id` = 721;
UPDATE `creature` SET `position_z` = 54.19 WHERE `guid` = 80799 AND `id` = 1933;
UPDATE `creature` SET `position_z` = 58.1 WHERE `guid` = 80800 AND `id` = 2442;
UPDATE `creature` SET `position_z` = 56.38 WHERE `guid` = 80801 AND `id` = 883;
UPDATE `creature` SET `position_z` = 57.98 WHERE `guid` = 80802 AND `id` = 524;
UPDATE `creature` SET `position_z` = 54.43 WHERE `guid` = 80803 AND `id` = 721;
UPDATE `creature` SET `position_z` = 62.94 WHERE `guid` = 80810 AND `id` = 525;
UPDATE `creature` SET `position_x` = -9570.9, `position_y` = -719.2, `position_z` = 64.74, `orientation` = 0.02 WHERE `guid` = 80924 AND `id` = 1949;
UPDATE `creature` SET `position_x` = -9492.5, `position_y` = -51, `position_z` = 57.09, `orientation` = 2 WHERE `guid` = 81090 AND `id` = 883;
UPDATE `creature` SET `position_x` = -9494, `position_y` = -53, `position_z` = 57.19, `orientation` = 1.2 WHERE `guid` = 81091 AND `id` = 890;
UPDATE `creature` SET `position_z` = 59.52 WHERE `guid` = 86714 AND `id` = 25962;
UPDATE `creature` SET `position_x` = -9487.28, `position_y` = -10.04, `orientation` = 6.1923 WHERE `guid` = 89359 AND `id` = 15760;
UPDATE `creature` SET `position_x` = -9484.89, `position_y` = -9.8, `orientation` = 3.2253 WHERE `guid` = 89360 AND `id` = 15760;
UPDATE `creature` SET `position_z` = 59.74 WHERE `guid` = 94559 AND `id` = 16781;
UPDATE `creature` SET `position_z` = 59.64 WHERE `guid` = 94560 AND `id` = 16781;
UPDATE `creature` SET `position_z` = 59.63 WHERE `guid` = 94561 AND `id` = 16781;
UPDATE `creature` SET `position_z` = 59.53 WHERE `guid` = 94619 AND `id` = 16781;
UPDATE `creature` SET `position_z` = 65.84 WHERE `guid` = 94849 AND `id` = 17066;
UPDATE `creature` SET `position_x` = -9480.25, `position_y` = 6.77, `orientation` = 4.8031 WHERE `guid` = 240026 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9482.71, `position_y` = 7.78, `orientation` = 4.4968 WHERE `guid` = 240027 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9477.96, `position_y` = 8.17, `orientation` = 4.4968 WHERE `guid` = 240028 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9484.41, `position_y` = -1.98, `orientation` = 3.0241 WHERE `guid` = 240101 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9479.29, `position_y` = -2.13, `orientation` = 2.6825 WHERE `guid` = 240156 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9475.65, `position_y` = -4.62, `orientation` = 4.1512 WHERE `guid` = 240157 AND `id` = 23686;
UPDATE `creature` SET `position_z` = 69.03 WHERE `guid` = 240165 AND `id` = 23686;
UPDATE `creature` SET `position_z` = 69.86 WHERE `guid` = 240167 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9494.63, `position_y` = -5.66, `orientation` = 6.2089 WHERE `guid` = 240176 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9499.65, `position_y` = -4.96, `orientation` = 6.1697 WHERE `guid` = 240177 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9499.87, `position_y` = 0.48, `orientation` = 6.0636 WHERE `guid` = 240178 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9497, `position_y` = 2.57, `orientation` = 4.9327 WHERE `guid` = 240179 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9496.48, `position_y` = 7.77, `orientation` = 4.2533 WHERE `guid` = 240180 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9492.92, `position_y` = 7.82, `orientation` = 1.6026 WHERE `guid` = 240181 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9489.67, `position_y` = 0.99, `orientation` = 4.3829 WHERE `guid` = 240182 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9488.5, `position_y` = 4.42, `orientation` = 2.6589 WHERE `guid` = 240183 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9484.62, `position_y` = 3.1, `orientation` = 3.1223 WHERE `guid` = 240184 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9473.71, `position_y` = -0.92, `orientation` = 5.6199 WHERE `guid` = 240189 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9474.88, `position_y` = 3.22, `orientation` = 5.6199 WHERE `guid` = 240190 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9477.81, `position_y` = 5.52, `orientation` = 5.612 WHERE `guid` = 240191 AND `id` = 23686;
UPDATE `creature` SET `position_z` = 55.66 WHERE `guid` = 241095 AND `id` = 32820;
UPDATE `creature` SET `position_z` = 55.67 WHERE `guid` = 241116 AND `id` = 32820;
UPDATE `creature` SET `position_z` = 56.24 WHERE `guid` = 241117 AND `id` = 32820;
UPDATE `creature` SET `position_z` = 57.77 WHERE `guid` = 241132 AND `id` = 32820;
UPDATE `creature` SET `position_z` = 57.77 WHERE `guid` = 241149 AND `id` = 32820;
UPDATE `creature` SET `position_z` = 57.59 WHERE `guid` = 241308 AND `id` = 32820;
UPDATE `creature` SET `position_z` = 57.27 WHERE `guid` = 241319 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9464, `position_y` = -35, `position_z` = 57.16, `orientation` = 0 WHERE `guid` = 241320 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9497, `position_y` = -49, `position_z` = 57.09, `orientation` = 0 WHERE `guid` = 241322 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9489, `position_y` = -54.5, `position_z` = 57.28, `orientation` = 0 WHERE `guid` = 241323 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9467, `position_y` = -19, `position_z` = 57.1, `orientation` = 0 WHERE `guid` = 241342 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9488.5, `position_y` = -44.27, `orientation` = 0.3341 WHERE `guid` = 241343 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9487.91, `position_y` = -40.19, `orientation` = 5.7121 WHERE `guid` = 241347 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9491.86, `position_y` = -1.29, `orientation` = 4.5081 WHERE `guid` = 241348 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9490.15, `position_y` = -8.21, `orientation` = 5.8521 WHERE `guid` = 241350 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9482.94, `position_y` = -39.69, `orientation` = 4.7921 WHERE `guid` = 241359 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9482.94, `position_y` = -39.69, `orientation` = 1.7421 WHERE `guid` = 241360 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9482.45, `position_y` = -34.55, `orientation` = 0.8431 WHERE `guid` = 241362 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9483.72, `position_y` = -22.03, `orientation` = 1.2011 WHERE `guid` = 241363 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9482.42, `position_y` = -24.93, `orientation` = 1.5501 WHERE `guid` = 241366 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9481.1, `position_y` = -18.2, `orientation` = 3.1381 WHERE `guid` = 241372 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9480.82, `position_y` = -1.14, `orientation` = 4.4641 WHERE `guid` = 241375 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9477.33, `position_y` = -25.64, `orientation` = 1.5671 WHERE `guid` = 241377 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9479.7, `position_y` = -2.23, `orientation` = 3.0861 WHERE `guid` = 241378 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9476.46, `position_y` = -4.49, `orientation` = 3.0681 WHERE `guid` = 241381 AND `id` = 32820;
UPDATE `creature` SET `position_z` = 59.86 WHERE `guid` = 241474 AND `id` = 32820;
UPDATE `creature` SET `position_z` = 60.33 WHERE `guid` = 241495 AND `id` = 32820;
UPDATE `creature` SET `position_z` = 64.3 WHERE `guid` = 241555 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9479.28, `position_y` = -8.11, `orientation` = 5.5471 WHERE `guid` = 244077 AND `id` = 32820;
UPDATE `creature` SET `position_z` = 59.74 WHERE `guid` = 244095 AND `id` = 32820;
UPDATE `creature` SET `position_z` = 59.64 WHERE `guid` = 244096 AND `id` = 32820;
UPDATE `creature` SET `position_z` = 59.63 WHERE `guid` = 244097 AND `id` = 32820;
UPDATE `creature` SET `position_z` = 59.53 WHERE `guid` = 244123 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9487.28, `position_y` = -10.04, `orientation` = 6.1923 WHERE `guid` = 244198 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9484.89, `position_y` = -9.8, `orientation` = 3.2253 WHERE `guid` = 244199 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9453.86, `position_y` = 44.74, `position_z` = 57.041, `orientation` = 3.88 WHERE `guid` = 244815 AND `id` = 32799;
UPDATE `creature` SET `position_x` = -9479.28, `position_y` = -8.11, `orientation` = 5.5471 WHERE `guid` = 244819 AND `id` = 32836;
UPDATE `creature` SET `position_x` = -9448.86, `position_y` = 51.965, `position_z` = 56.799, `orientation` = 3.95 WHERE `guid` = 245655 AND `id` = 25898;

-- gameobject positions of the Goldshire WB1 layout and the Elwynn relocations
UPDATE `gameobject` SET `position_x` = -9496.91, `position_y` = -1.29, `orientation` = 0.2407, `rotation2` = 0.12006, `rotation3` = 0.992767 WHERE `guid` = 2302 AND `id` = 180428;
UPDATE `gameobject` SET `position_x` = -9493.25, `position_y` = 0.03, `orientation` = 6.1225, `rotation2` = 0.080256, `rotation3` = -0.996774 WHERE `guid` = 2314 AND `id` = 180429;
UPDATE `gameobject` SET `position_x` = -9480.02, `position_y` = -1.07, `orientation` = 4.6739, `rotation2` = 0.720583, `rotation3` = -0.693369 WHERE `guid` = 2381 AND `id` = 180410;
UPDATE `gameobject` SET `position_x` = -9474.88, `position_y` = -7.19, `orientation` = 2.6144, `rotation2` = 0.965459, `rotation3` = 0.260554 WHERE `guid` = 3203 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9477.13, `position_y` = -5.7, `orientation` = 3.1031, `rotation2` = 0.999815, `rotation3` = 0.019245 WHERE `guid` = 3204 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9477.23, `position_y` = -6.65, `orientation` = 3.0333, `rotation2` = 0.998534, `rotation3` = 0.05412 WHERE `guid` = 3205 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9477.38, `position_y` = -7.56, `orientation` = 3.0158, `rotation2` = 0.998023, `rotation3` = 0.062855 WHERE `guid` = 3206 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9477.41, `position_y` = -14.47, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 3207 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9477.54, `position_y` = -13.42, `orientation` = 3.1903, `rotation2` = 0.999703, `rotation3` = -0.024351 WHERE `guid` = 3208 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9477.37, `position_y` = -15.35, `orientation` = 3.1031, `rotation2` = 0.999815, `rotation3` = 0.019245 WHERE `guid` = 3209 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9481.95, `position_y` = -27.19, `orientation` = 5.5989, `rotation2` = 0.335506, `rotation3` = -0.942038 WHERE `guid` = 3210 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9470.89, `position_y` = 5.86, `orientation` = 3.2951, `rotation2` = 0.997056, `rotation3` = -0.076678 WHERE `guid` = 8011 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9472.46, `position_y` = -2.31, `orientation` = 0.2058, `rotation2` = 0.102719, `rotation3` = 0.99471 WHERE `guid` = 8171 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9472.72, `position_y` = -18.87, `orientation` = 0.1709, `rotation2` = 0.085346, `rotation3` = 0.996351 WHERE `guid` = 8172 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9480.1, `position_y` = 10.74, `orientation` = 1.7068, `rotation2` = 0.75352, `rotation3` = 0.657425 WHERE `guid` = 8173 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9479.32, `position_y` = -22.03, `orientation` = 2.1083, `rotation2` = 0.869481, `rotation3` = 0.493967 WHERE `guid` = 8174 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9479.38, `position_y` = -36.54, `orientation` = 1.5323, `rotation2` = 0.693366, `rotation3` = 0.720585 WHERE `guid` = 26242 AND `id` = 1560;
UPDATE `gameobject` SET `position_x` = -9485.26, `position_y` = -18.65, `orientation` = 0.1709, `rotation2` = 0.085346, `rotation3` = 0.996351 WHERE `guid` = 26243 AND `id` = 177502;
UPDATE `gameobject` SET `position_x` = -9474.77, `position_y` = -12.34, `orientation` = 1.4188, `rotation2` = 0.651379, `rotation3` = 0.758753 WHERE `guid` = 26244 AND `id` = 22772;
UPDATE `gameobject` SET `position_x` = -9476.51, `position_y` = -17.87, `orientation` = 3.8798, `rotation2` = 0.932651, `rotation3` = -0.36078 WHERE `guid` = 26246 AND `id` = 22803;
UPDATE `gameobject` SET `position_x` = -9473.86, `position_y` = -10.3, `orientation` = 0.4851, `rotation2` = 0.240179, `rotation3` = 0.970729 WHERE `guid` = 26247 AND `id` = 22773;
UPDATE `gameobject` SET `position_x` = -9478.16, `position_y` = -20.92, `orientation` = 1.5236, `rotation2` = 0.690225, `rotation3` = 0.723595 WHERE `guid` = 26249 AND `id` = 177495;
UPDATE `gameobject` SET `position_x` = -9475.37, `position_y` = -6.39, `orientation` = 4.351, `rotation2` = 0.822671, `rotation3` = -0.568518 WHERE `guid` = 26250 AND `id` = 177500;
UPDATE `gameobject` SET `position_x` = -9475.63, `position_y` = -9.01, `orientation` = 1.9075, `rotation2` = 0.815591, `rotation3` = 0.578629 WHERE `guid` = 26251 AND `id` = 177501;
UPDATE `gameobject` SET `position_x` = -9477.29, `position_y` = 2.62, `orientation` = 4.6913, `rotation2` = 0.714523, `rotation3` = -0.699612 WHERE `guid` = 26252 AND `id` = 177503;
UPDATE `gameobject` SET `position_x` = -9475.18, `position_y` = -9.43, `orientation` = 3.1205, `rotation2` = 0.999944, `rotation3` = 0.010546 WHERE `guid` = 26253 AND `id` = 22774;
UPDATE `gameobject` SET `position_x` = -9476.63, `position_y` = -20.64, `orientation` = 2.3264, `rotation2` = 0.918076, `rotation3` = 0.396404 WHERE `guid` = 26255 AND `id` = 177494;
UPDATE `gameobject` SET `position_x` = -9482.55, `position_y` = -28.66, `orientation` = 1.2094, `rotation2` = 0.568515, `rotation3` = 0.822673 WHERE `guid` = 26256 AND `id` = 22783;
UPDATE `gameobject` SET `position_x` = -9475.22, `position_y` = -10.89, `orientation` = 4.2114, `rotation2` = 0.860318, `rotation3` = -0.509758 WHERE `guid` = 26257 AND `id` = 22777;
UPDATE `gameobject` SET `position_x` = -9478.08, `position_y` = -17.59, `orientation` = 4.7088, `rotation2` = 0.708375, `rotation3` = -0.705837 WHERE `guid` = 26259 AND `id` = 22804;
UPDATE `gameobject` SET `position_x` = -9479.44, `position_y` = -18.11, `orientation` = 4.9706, `rotation2` = 0.610184, `rotation3` = -0.79226 WHERE `guid` = 26260 AND `id` = 175749;
UPDATE `gameobject` SET `position_x` = -9474.5, `position_y` = 14, `position_z` = 56.574, `orientation` = 1.506, `rotation2` = 0.683831, `rotation3` = 0.729641 WHERE `guid` = 26784 AND `id` = 142075;
UPDATE `gameobject` SET `position_x` = -9479.08, `position_y` = 2.66, `orientation` = 4.6913, `rotation2` = 0.714523, `rotation3` = -0.699612 WHERE `guid` = 26792 AND `id` = 177504;
UPDATE `gameobject` SET `position_x` = -9462.51, `position_y` = 41.52, `position_z` = 56.371, `orientation` = 4.6212, `rotation2` = 0.738601, `rotation3` = -0.674143 WHERE `guid` = 26794 AND `id` = 91;
UPDATE `gameobject` SET `position_x` = -9462.53, `position_y` = 41.53, `position_z` = 57.275, `orientation` = 4.6212, `rotation2` = 0.738601, `rotation3` = -0.674143 WHERE `guid` = 26795 AND `id` = 92;
UPDATE `gameobject` SET `position_x` = -9464.15, `position_y` = 40.01, `position_z` = 57.267, `orientation` = 3.0504, `rotation2` = 0.998961, `rotation3` = 0.045581 WHERE `guid` = 26796 AND `id` = 95;
UPDATE `gameobject` SET `position_x` = -9464.11, `position_y` = 40, `position_z` = 56.363, `orientation` = 3.0504, `rotation2` = 0.998961, `rotation3` = 0.045581 WHERE `guid` = 26797 AND `id` = 96;
UPDATE `gameobject` SET `position_x` = -9463.93, `position_y` = 43.22, `position_z` = 57.245, `orientation` = 6.192, `rotation2` = 0.045577, `rotation3` = -0.998961 WHERE `guid` = 26798 AND `id` = 93;
UPDATE `gameobject` SET `position_x` = -9463.91, `position_y` = 43.19, `position_z` = 56.34, `orientation` = 6.192, `rotation2` = 0.045577, `rotation3` = -0.998961 WHERE `guid` = 26799 AND `id` = 94;
UPDATE `gameobject` SET `position_x` = -9496.3, `position_y` = -6.19, `orientation` = 5.5378, `rotation2` = 0.364125, `rotation3` = -0.93135 WHERE `guid` = 26800 AND `id` = 22811;
UPDATE `gameobject` SET `position_x` = -9494.91, `position_y` = -5.93, `orientation` = 4.7088, `rotation2` = 0.708375, `rotation3` = -0.705837 WHERE `guid` = 26801 AND `id` = 22812;
UPDATE `gameobject` SET `position_x` = -9491.69, `position_y` = -5.97, `orientation` = 4.5779, `rotation2` = 0.753022, `rotation3` = -0.657995 WHERE `guid` = 26802 AND `id` = 177497;
UPDATE `gameobject` SET `position_x` = -9493.31, `position_y` = -5.95, `orientation` = 4.7088, `rotation2` = 0.708375, `rotation3` = -0.705837 WHERE `guid` = 26803 AND `id` = 177498;
UPDATE `gameobject` SET `position_x` = -9496.52, `position_y` = -7.52, `orientation` = 0.0051, `rotation2` = 0.00255, `rotation3` = 0.999997 WHERE `guid` = 26804 AND `id` = 177499;
UPDATE `gameobject` SET `position_x` = -9490, `position_y` = -6.27, `orientation` = 4.0368, `rotation2` = 0.901487, `rotation3` = -0.432807 WHERE `guid` = 26805 AND `id` = 22813;
UPDATE `gameobject` SET `position_x` = -9479.76, `position_y` = -17.82, `orientation` = 5.276, `rotation2` = 0.482575, `rotation3` = -0.875854 WHERE `guid` = 26806 AND `id` = 22806;
UPDATE `gameobject` SET `position_x` = -9479.71, `position_y` = -20.53, `orientation` = 1.157, `rotation2` = 0.546769, `rotation3` = 0.837284 WHERE `guid` = 26807 AND `id` = 177496;
UPDATE `gameobject` SET `position_x` = -9486.16, `position_y` = -42.29, `orientation` = 1.4887, `rotation2` = 0.677494, `rotation3` = 0.735528 WHERE `guid` = 26808 AND `id` = 22776;
UPDATE `gameobject` SET `position_x` = -9484.94, `position_y` = -41.73, `orientation` = 0.0837, `rotation2` = 0.041838, `rotation3` = 0.999124 WHERE `guid` = 26810 AND `id` = 22775;
UPDATE `gameobject` SET `position_x` = -9475.88, `position_y` = -25.32, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 30677 AND `id` = 3658;
UPDATE `gameobject` SET `position_x` = -9475.88, `position_y` = -25.32, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 30839 AND `id` = 3719;
UPDATE `gameobject` SET `position_z` = 56.93 WHERE `guid` = 32313 AND `id` = 3658;
UPDATE `gameobject` SET `position_z` = 56.93 WHERE `guid` = 32754 AND `id` = 3719;
UPDATE `gameobject` SET `position_x` = -9488.49, `position_y` = 0.18, `orientation` = 3.9059, `rotation2` = 0.927864, `rotation3` = -0.37292 WHERE `guid` = 34374 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9485.22, `position_y` = -19.76, `orientation` = 4.5866, `rotation2` = 0.750152, `rotation3` = -0.661265 WHERE `guid` = 34375 AND `id` = 180415;
UPDATE `gameobject` SET `position_z` = 56.61 WHERE `guid` = 36183 AND `id` = 180405;
UPDATE `gameobject` SET `position_x` = -9491.86, `position_y` = 5.89, `position_z` = 58.33, `orientation` = 3.5045, `rotation2` = 0.983582, `rotation3` = -0.18046 WHERE `guid` = 36184 AND `id` = 180405;
UPDATE `gameobject` SET `position_x` = -9496.98, `position_y` = -2.33, `orientation` = 1.9163, `rotation2` = 0.818129, `rotation3` = 0.575035 WHERE `guid` = 36624 AND `id` = 180406;
UPDATE `gameobject` SET `position_x` = -9494.89, `position_y` = -7.51, `orientation` = 1.445, `rotation2` = 0.661262, `rotation3` = 0.750155 WHERE `guid` = 36625 AND `id` = 180406;
UPDATE `gameobject` SET `position_x` = -9483.42, `position_y` = -33.82, `orientation` = 1.8639, `rotation2` = 0.802784, `rotation3` = 0.59627 WHERE `guid` = 36626 AND `id` = 180406;
UPDATE `gameobject` SET `position_z` = 56.64 WHERE `guid` = 36627 AND `id` = 180406;
UPDATE `gameobject` SET `position_x` = -9490.86, `position_y` = -2.94, `orientation` = 2.6668, `rotation2` = 0.971954, `rotation3` = 0.235173 WHERE `guid` = 37047 AND `id` = 180407;
UPDATE `gameobject` SET `position_z` = 56.63 WHERE `guid` = 37049 AND `id` = 180407;
UPDATE `gameobject` SET `position_x` = -9496.68, `position_y` = -22.77, `orientation` = 2.9111, `rotation2` = 0.993366, `rotation3` = 0.114991 WHERE `guid` = 37050 AND `id` = 180407;
UPDATE `gameobject` SET `position_x` = -9488.96, `position_y` = -8.14, `orientation` = 4.4819, `rotation2` = 0.783726, `rotation3` = -0.621106 WHERE `guid` = 37401 AND `id` = 180410;
UPDATE `gameobject` SET `position_x` = -9486.08, `position_y` = -16.61, `orientation` = 0.2931, `rotation2` = 0.146026, `rotation3` = 0.989281 WHERE `guid` = 37402 AND `id` = 180410;
UPDATE `gameobject` SET `position_x` = -9496.97, `position_y` = -0.13, `orientation` = 0.0139, `rotation2` = 0.00695, `rotation3` = 0.999976 WHERE `guid` = 37403 AND `id` = 180410;
UPDATE `gameobject` SET `position_x` = -9492.03, `position_y` = 8.7, `orientation` = 4.3772, `rotation2` = 0.815153, `rotation3` = -0.579246 WHERE `guid` = 37507 AND `id` = 180411;
UPDATE `gameobject` SET `position_x` = -9492.82, `position_y` = -29.08, `orientation` = 1.1309, `rotation2` = 0.535796, `rotation3` = 0.844348 WHERE `guid` = 37508 AND `id` = 180411;
UPDATE `gameobject` SET `position_x` = -9493.08, `position_y` = -23.34, `orientation` = 4.639, `rotation2` = 0.732572, `rotation3` = -0.68069 WHERE `guid` = 37509 AND `id` = 180411;
UPDATE `gameobject` SET `position_x` = -9486.14, `position_y` = -5.66, `orientation` = 5.948, `rotation2` = 0.166809, `rotation3` = -0.985989 WHERE `guid` = 37799 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9490.13, `position_y` = -13.44, `orientation` = 1.3578, `rotation2` = 0.627937, `rotation3` = 0.778264 WHERE `guid` = 37800 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9497, `position_y` = -11.42, `orientation` = 0.1535, `rotation2` = 0.076675, `rotation3` = 0.997056 WHERE `guid` = 37801 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9488.31, `position_y` = -0.04, `orientation` = 3.9234, `rotation2` = 0.924565, `rotation3` = -0.381024 WHERE `guid` = 37802 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9495.61, `position_y` = 3.5, `orientation` = 5.023, `rotation2` = 0.58922, `rotation3` = -0.807973 WHERE `guid` = 37803 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9489.08, `position_y` = -45.45, `orientation` = 5.3895, `rotation2` = 0.43212, `rotation3` = -0.901816 WHERE `guid` = 38988 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9479.77, `position_y` = -46.79, `orientation` = 6.14, `rotation2` = 0.071532, `rotation3` = -0.997438 WHERE `guid` = 38989 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9472.05, `position_y` = -45.69, `orientation` = 1.4276, `rotation2` = 0.654711, `rotation3` = 0.755879 WHERE `guid` = 38990 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9499.94, `position_y` = 7.67, `orientation` = 2.8762, `rotation2` = 0.991209, `rotation3` = 0.132307 WHERE `guid` = 38992 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9500.79, `position_y` = -0.34, `orientation` = 4.7088, `rotation2` = 0.708375, `rotation3` = -0.705837 WHERE `guid` = 38993 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9500.68, `position_y` = -27.52, `orientation` = 5.1626, `rotation2` = 0.531434, `rotation3` = -0.8471 WHERE `guid` = 38994 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9501.44, `position_y` = -20.28, `orientation` = 4.7262, `rotation2` = 0.702207, `rotation3` = -0.711973 WHERE `guid` = 38995 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9501.07, `position_y` = -10.3, `orientation` = 4.7612, `rotation2` = 0.689641, `rotation3` = -0.724152 WHERE `guid` = 38996 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9479.77, `position_y` = -44.26, `orientation` = 4.7612, `rotation2` = 0.689641, `rotation3` = -0.724152 WHERE `guid` = 39428 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9492.23, `position_y` = 4.5, `orientation` = 4.8833, `rotation2` = 0.644174, `rotation3` = -0.764879 WHERE `guid` = 39429 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9492.79, `position_y` = -26.5, `orientation` = 4.7961, `rotation2` = 0.6769, `rotation3` = -0.736075 WHERE `guid` = 39430 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9499.32, `position_y` = -2.27, `orientation` = 3.1903, `rotation2` = 0.999703, `rotation3` = -0.024351 WHERE `guid` = 39431 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9499.68, `position_y` = -17.94, `orientation` = 3.1555, `rotation2` = 0.999976, `rotation3` = -0.006954 WHERE `guid` = 39432 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9481.01, `position_y` = -43.3, `orientation` = 4.6739, `rotation2` = 0.720583, `rotation3` = -0.693369 WHERE `guid` = 40843 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -9473.16, `position_y` = -39.02, `orientation` = 0.0488, `rotation2` = 0.024398, `rotation3` = 0.999702 WHERE `guid` = 40844 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9479.82, `position_y` = -44.25, `orientation` = 4.6564, `rotation2` = 0.726622, `rotation3` = -0.687037 WHERE `guid` = 40845 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9486.15, `position_y` = -9.83, `orientation` = 2.3351, `rotation2` = 0.919792, `rotation3` = 0.392406 WHERE `guid` = 40846 AND `id` = 180844;
UPDATE `gameobject` SET `position_x` = -9494.7, `position_y` = -24.89, `orientation` = 4.6913, `rotation2` = 0.714523, `rotation3` = -0.699612 WHERE `guid` = 40847 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9498.98, `position_y` = -10.35, `orientation` = 3.1903, `rotation2` = 0.999703, `rotation3` = -0.024351 WHERE `guid` = 40848 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9498.51, `position_y` = -1.63, `orientation` = 3.1031, `rotation2` = 0.999815, `rotation3` = 0.019245 WHERE `guid` = 40849 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -9499.19, `position_y` = -20.33, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 40850 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9488.51, `position_y` = -34.57, `orientation` = 3.1205, `rotation2` = 0.999944, `rotation3` = 0.010546 WHERE `guid` = 40851 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -9490.35, `position_y` = 5.25, `orientation` = 1.5323, `rotation2` = 0.693366, `rotation3` = 0.720585 WHERE `guid` = 40852 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -9488.38, `position_y` = -27.4, `orientation` = 3.1031, `rotation2` = 0.999815, `rotation3` = 0.019245 WHERE `guid` = 40853 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9492.79, `position_y` = -26.51, `orientation` = 4.6913, `rotation2` = 0.714523, `rotation3` = -0.699612 WHERE `guid` = 40854 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9498.88, `position_y` = -20.58, `orientation` = 3.0682, `rotation2` = 0.999327, `rotation3` = 0.036688 WHERE `guid` = 40856 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9498.76, `position_y` = -0.39, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 40857 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9492.01, `position_y` = 8.33, `orientation` = 1.5497, `rotation2` = 0.699609, `rotation3` = 0.714526 WHERE `guid` = 40858 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9490.89, `position_y` = -24.95, `orientation` = 4.6739, `rotation2` = 0.720583, `rotation3` = -0.693369 WHERE `guid` = 40859 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9498.74, `position_y` = -12.95, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 40861 AND `id` = 178645;
UPDATE `gameobject` SET `position_z` = 56.89 WHERE `guid` = 40862 AND `id` = 178433;
UPDATE `gameobject` SET `position_x` = -9476.45, `position_y` = -9.86, `orientation` = 2.9809, `rotation2` = 0.996774, `rotation3` = 0.08026 WHERE `guid` = 40863 AND `id` = 178436;
UPDATE `gameobject` SET `position_z` = 56.89 WHERE `guid` = 40864 AND `id` = 178431;
UPDATE `gameobject` SET `position_z` = 57.23 WHERE `guid` = 40866 AND `id` = 178433;
UPDATE `gameobject` SET `position_x` = -9476.61, `position_y` = -14.36, `orientation` = 2.6318, `rotation2` = 0.967689, `rotation3` = 0.252145 WHERE `guid` = 40868 AND `id` = 178434;
UPDATE `gameobject` SET `position_x` = -9472.88, `position_y` = 0.09, `orientation` = 6.2796, `rotation2` = 0.001793, `rotation3` = -0.999998 WHERE `guid` = 40871 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9476.43, `position_y` = -8.81, `orientation` = 3.1555, `rotation2` = 0.999976, `rotation3` = -0.006954 WHERE `guid` = 40872 AND `id` = 178434;
UPDATE `gameobject` SET `position_x` = -9476.43, `position_y` = -6.82, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 40873 AND `id` = 178435;
UPDATE `gameobject` SET `position_x` = -9472.57, `position_y` = -2.32, `orientation` = 0.0139, `rotation2` = 0.00695, `rotation3` = 0.999976 WHERE `guid` = 40874 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9476.38, `position_y` = -7.74, `orientation` = 3.0158, `rotation2` = 0.998023, `rotation3` = 0.062855 WHERE `guid` = 40875 AND `id` = 178436;
UPDATE `gameobject` SET `position_x` = -9476.48, `position_y` = 7.57, `orientation` = 6.2447, `rotation2` = 0.019241, `rotation3` = -0.999815 WHERE `guid` = 40876 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9473.42, `position_y` = -20.6, `orientation` = 6.2621, `rotation2` = 0.010542, `rotation3` = -0.999944 WHERE `guid` = 40880 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -9483.62, `position_y` = 7.47, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 40886 AND `id` = 178438;
UPDATE `gameobject` SET `position_z` = 56.86 WHERE `guid` = 40887 AND `id` = 178431;
UPDATE `gameobject` SET `position_x` = -9473.06, `position_y` = -3.92, `orientation` = 6.2621, `rotation2` = 0.010542, `rotation3` = -0.999944 WHERE `guid` = 40888 AND `id` = 178438;
UPDATE `gameobject` SET `position_z` = 56.82 WHERE `guid` = 40889 AND `id` = 178428;
UPDATE `gameobject` SET `position_z` = 56.82 WHERE `guid` = 40890 AND `id` = 178433;
UPDATE `gameobject` SET `position_x` = -9476.58, `position_y` = -12.31, `orientation` = 3.0682, `rotation2` = 0.999327, `rotation3` = 0.036688 WHERE `guid` = 40891 AND `id` = 178434;
UPDATE `gameobject` SET `position_x` = -9473.25, `position_y` = -31.8, `orientation` = 0.0139, `rotation2` = 0.00695, `rotation3` = 0.999976 WHERE `guid` = 40892 AND `id` = 178645;
UPDATE `gameobject` SET `position_z` = 57.01 WHERE `guid` = 40894 AND `id` = 178432;
UPDATE `gameobject` SET `position_x` = -9480.11, `position_y` = 10.68, `orientation` = 1.5672, `rotation2` = 0.705834, `rotation3` = 0.708377 WHERE `guid` = 40896 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9476.56, `position_y` = -11.07, `orientation` = 3.0158, `rotation2` = 0.998023, `rotation3` = 0.062855 WHERE `guid` = 40897 AND `id` = 178435;
UPDATE `gameobject` SET `position_x` = -9476.61, `position_y` = -13.3, `orientation` = 2.9286, `rotation2` = 0.994335, `rotation3` = 0.106295 WHERE `guid` = 40898 AND `id` = 178436;
UPDATE `gameobject` SET `position_x` = -9485.42, `position_y` = 1.99, `orientation` = 2.562, `rotation2` = 0.958302, `rotation3` = 0.285757 WHERE `guid` = 40899 AND `id` = 178554;
UPDATE `gameobject` SET `position_z` = 57 WHERE `guid` = 40900 AND `id` = 178432;
UPDATE `gameobject` SET `position_z` = 56.9 WHERE `guid` = 41505 AND `id` = 178430;
UPDATE `gameobject` SET `position_x` = -9492.04, `position_y` = 6.75, `orientation` = 1.5672, `rotation2` = 0.705834, `rotation3` = 0.708377 WHERE `guid` = 41655 AND `id` = 178437;
UPDATE `gameobject` SET `position_z` = 57.06 WHERE `guid` = 41656 AND `id` = 178425;
UPDATE `gameobject` SET `position_x` = -9472.74, `position_y` = -18.66, `orientation` = 3.1729, `rotation2` = 0.999877, `rotation3` = -0.015653 WHERE `guid` = 41802 AND `id` = 178551;
UPDATE `gameobject` SET `position_z` = 59.48 WHERE `guid` = 50805 AND `id` = 181302;
UPDATE `gameobject` SET `position_z` = 59.56 WHERE `guid` = 50822 AND `id` = 181305;
UPDATE `gameobject` SET `position_z` = 59.65 WHERE `guid` = 50891 AND `id` = 181306;
UPDATE `gameobject` SET `position_z` = 60.54 WHERE `guid` = 50933 AND `id` = 181307;
UPDATE `gameobject` SET `position_z` = 59.26 WHERE `guid` = 51040 AND `id` = 181605;
UPDATE `gameobject` SET `position_z` = 58.99 WHERE `guid` = 51592 AND `id` = 181355;
UPDATE `gameobject` SET `position_z` = 60.03 WHERE `guid` = 51593 AND `id` = 181355;
UPDATE `gameobject` SET `position_z` = 58.97 WHERE `guid` = 51840 AND `id` = 181355;
UPDATE `gameobject` SET `position_z` = 59.66 WHERE `guid` = 51987 AND `id` = 181355;
UPDATE `gameobject` SET `position_z` = 58.14 WHERE `guid` = 52349 AND `id` = 188020;
UPDATE `gameobject` SET `position_z` = 59.95 WHERE `guid` = 52417 AND `id` = 188020;
UPDATE `gameobject` SET `position_z` = 59.68 WHERE `guid` = 52418 AND `id` = 188020;
UPDATE `gameobject` SET `position_x` = -9475.42, `position_y` = -23.15, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 52634 AND `id` = 181388;
UPDATE `gameobject` SET `position_x` = -9477.44, `position_y` = -15.49, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 52683 AND `id` = 181388;
UPDATE `gameobject` SET `position_x` = -9477.53, `position_y` = -13.33, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 52684 AND `id` = 181388;
UPDATE `gameobject` SET `position_x` = -9477.48, `position_y` = -7.79, `orientation` = 3.1729, `rotation2` = 0.999877, `rotation3` = -0.015653 WHERE `guid` = 52735 AND `id` = 181388;
UPDATE `gameobject` SET `position_x` = -9477.22, `position_y` = -5.41, `orientation` = 3.2427, `rotation2` = 0.998722, `rotation3` = -0.050532 WHERE `guid` = 52754 AND `id` = 181388;
UPDATE `gameobject` SET `position_x` = -9499.19, `position_y` = -15.61, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 52939 AND `id` = 181390;
UPDATE `gameobject` SET `position_x` = -9492.09, `position_y` = 5.52, `orientation` = 1.5847, `rotation2` = 0.712005, `rotation3` = 0.702174 WHERE `guid` = 52989 AND `id` = 181390;
UPDATE `gameobject` SET `position_x` = -9498.96, `position_y` = -4.18, `orientation` = 3.1729, `rotation2` = 0.999877, `rotation3` = -0.015653 WHERE `guid` = 52990 AND `id` = 181390;
UPDATE `gameobject` SET `position_x` = -9472.88, `position_y` = -2.27, `orientation` = 6.2447, `rotation2` = 0.019241, `rotation3` = -0.999815 WHERE `guid` = 53023 AND `id` = 181390;
UPDATE `gameobject` SET `position_x` = -9473.22, `position_y` = -18.94, `orientation` = 0.0139, `rotation2` = 0.00695, `rotation3` = 0.999976 WHERE `guid` = 53024 AND `id` = 181390;
UPDATE `gameobject` SET `position_x` = -9477.12, `position_y` = -14.35, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 53142 AND `id` = 181391;
UPDATE `gameobject` SET `position_x` = -9476.87, `position_y` = -6.53, `orientation` = 3.0682, `rotation2` = 0.999327, `rotation3` = 0.036688 WHERE `guid` = 53147 AND `id` = 181391;
UPDATE `gameobject` SET `position_x` = -9488.45, `position_y` = -4.5, `orientation` = 1.5497, `rotation2` = 0.699609, `rotation3` = 0.714526 WHERE `guid` = 53251 AND `id` = 181391;
UPDATE `gameobject` SET `position_x` = -9483.07, `position_y` = -22.94, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 53252 AND `id` = 181391;
UPDATE `gameobject` SET `position_x` = -9488.69, `position_y` = -15.84, `orientation` = 1.5148, `rotation2` = 0.687035, `rotation3` = 0.726625 WHERE `guid` = 53253 AND `id` = 181391;
UPDATE `gameobject` SET `position_x` = -9485.08, `position_y` = -15.91, `orientation` = 1.5323, `rotation2` = 0.693366, `rotation3` = 0.720585 WHERE `guid` = 53365 AND `id` = 181391;
UPDATE `gameobject` SET `position_x` = -9484.81, `position_y` = -4.61, `orientation` = 1.5497, `rotation2` = 0.699609, `rotation3` = 0.714526 WHERE `guid` = 53366 AND `id` = 181391;
UPDATE `gameobject` SET `position_x` = -9480.11, `position_y` = 10.19, `orientation` = 1.5148, `rotation2` = 0.687035, `rotation3` = 0.726625 WHERE `guid` = 53612 AND `id` = 181392;
UPDATE `gameobject` SET `position_x` = -9500.62, `position_y` = -10.11, `orientation` = 3.1205, `rotation2` = 0.999944, `rotation3` = 0.010546 WHERE `guid` = 54096 AND `id` = 181401;
UPDATE `gameobject` SET `position_x` = -9492.14, `position_y` = 6.77, `orientation` = 1.5847, `rotation2` = 0.712005, `rotation3` = 0.702174 WHERE `guid` = 54214 AND `id` = 181401;
UPDATE `gameobject` SET `position_x` = -9470.26, `position_y` = -10.7, `orientation` = 6.2621, `rotation2` = 0.010542, `rotation3` = -0.999944 WHERE `guid` = 54235 AND `id` = 181401;
UPDATE `gameobject` SET `position_x` = -9463.39, `position_y` = 41.56, `position_z` = 58.308, `orientation` = 6.2094, `rotation2` = 0.036884, `rotation3` = -0.99932 WHERE `guid` = 54778 AND `id` = 187576;
UPDATE `gameobject` SET `position_x` = -9497.5, `position_y` = -3.79, `orientation` = 6.2272, `rotation2` = 0.027989, `rotation3` = -0.999608 WHERE `guid` = 54862 AND `id` = 187576;
UPDATE `gameobject` SET `position_x` = -9483.78, `position_y` = -0.67, `orientation` = 4.6564, `rotation2` = 0.726622, `rotation3` = -0.687037 WHERE `guid` = 54863 AND `id` = 187576;
UPDATE `gameobject` SET `position_x` = -9493.15, `position_y` = -23.97, `orientation` = 1.5497, `rotation2` = 0.699609, `rotation3` = 0.714526 WHERE `guid` = 54879 AND `id` = 187576;
UPDATE `gameobject` SET `position_x` = -9434, `position_y` = 60.5, `position_z` = 56.56 WHERE `guid` = 66928 AND `id` = 186615;
UPDATE `gameobject` SET `position_x` = -9492.14, `position_y` = 6.77, `orientation` = 1.5847, `rotation2` = 0.712005, `rotation3` = 0.702174 WHERE `guid` = 66973 AND `id` = 195253;
UPDATE `gameobject` SET `position_x` = -9500.62, `position_y` = -10.11, `orientation` = 3.1205, `rotation2` = 0.999944, `rotation3` = 0.010546 WHERE `guid` = 66974 AND `id` = 195253;
UPDATE `gameobject` SET `position_x` = -9470.26, `position_y` = -10.7, `orientation` = 6.2621, `rotation2` = 0.010542, `rotation3` = -0.999944 WHERE `guid` = 67002 AND `id` = 195253;
UPDATE `gameobject` SET `position_x` = -9472.48, `position_y` = -19.16, `orientation` = 1.9512, `rotation2` = 0.828038, `rotation3` = 0.560671 WHERE `guid` = 68029 AND `id` = 180405;
UPDATE `gameobject` SET `position_z` = 74.51 WHERE `guid` = 68030 AND `id` = 180405;
UPDATE `gameobject` SET `position_x` = -9481.38, `position_y` = -10.09, `orientation` = 5.0753, `rotation2` = 0.567892, `rotation3` = -0.823103 WHERE `guid` = 68031 AND `id` = 180405;
UPDATE `gameobject` SET `position_x` = -9476.87, `position_y` = -2.96, `orientation` = 5.0753, `rotation2` = 0.567892, `rotation3` = -0.823103 WHERE `guid` = 68339 AND `id` = 180406;
UPDATE `gameobject` SET `position_z` = 74.56 WHERE `guid` = 68341 AND `id` = 180406;
UPDATE `gameobject` SET `position_x` = -9472.43, `position_y` = -2.06, `position_z` = 58.44, `orientation` = 1.9686, `rotation2` = 0.832885, `rotation3` = 0.553446 WHERE `guid` = 68645 AND `id` = 180407;
UPDATE `gameobject` SET `position_z` = 74.52 WHERE `guid` = 68647 AND `id` = 180407;
UPDATE `gameobject` SET `position_z` = 74.6 WHERE `guid` = 68648 AND `id` = 180407;
UPDATE `gameobject` SET `position_x` = -9476.12, `position_y` = -7.22, `orientation` = 5.372, `rotation2` = 0.439995, `rotation3` = -0.898 WHERE `guid` = 69157 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9476.11, `position_y` = -7.62, `orientation` = 0.2058, `rotation2` = 0.102719, `rotation3` = 0.99471 WHERE `guid` = 69158 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9477.18, `position_y` = -6.23, `orientation` = 1.1134, `rotation2` = 0.528387, `rotation3` = 0.849003 WHERE `guid` = 69159 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9477.31, `position_y` = -7.13, `orientation` = 2.1432, `rotation2` = 0.877968, `rotation3` = 0.47872 WHERE `guid` = 69160 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9477.49, `position_y` = -13.96, `orientation` = 3.8187, `rotation2` = 0.943236, `rotation3` = -0.332123 WHERE `guid` = 69161 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9477.43, `position_y` = -14.95, `orientation` = 1.9512, `rotation2` = 0.828038, `rotation3` = 0.560671 WHERE `guid` = 69162 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9478.85, `position_y` = -16.68, `orientation` = 3.8012, `rotation2` = 0.946106, `rotation3` = -0.323857 WHERE `guid` = 69163 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9479.88, `position_y` = -17.54, `orientation` = 5.6513, `rotation2` = 0.310713, `rotation3` = -0.950504 WHERE `guid` = 69164 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9481.8, `position_y` = -7.95, `orientation` = 2.6668, `rotation2` = 0.971954, `rotation3` = 0.235173 WHERE `guid` = 69165 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9486.02, `position_y` = 2.33, `orientation` = 6.0702, `rotation2` = 0.106291, `rotation3` = -0.994335 WHERE `guid` = 69166 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9483.78, `position_y` = -0.67, `orientation` = 4.6564, `rotation2` = 0.726622, `rotation3` = -0.687037 WHERE `guid` = 80366 AND `id` = 195259;
UPDATE `gameobject` SET `position_x` = -9497.5, `position_y` = -3.79, `orientation` = 6.2272, `rotation2` = 0.027989, `rotation3` = -0.999608 WHERE `guid` = 80367 AND `id` = 195259;
UPDATE `gameobject` SET `position_x` = -9493.15, `position_y` = -23.97, `orientation` = 1.5497, `rotation2` = 0.699609, `rotation3` = 0.714526 WHERE `guid` = 80378 AND `id` = 195259;
UPDATE `gameobject` SET `position_x` = -9477.12, `position_y` = -14.35, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 80456 AND `id` = 195260;
UPDATE `gameobject` SET `position_x` = -9476.87, `position_y` = -6.53, `orientation` = 3.0682, `rotation2` = 0.999327, `rotation3` = 0.036688 WHERE `guid` = 80457 AND `id` = 195260;
UPDATE `gameobject` SET `position_x` = -9484.81, `position_y` = -4.61, `orientation` = 1.5497, `rotation2` = 0.699609, `rotation3` = 0.714526 WHERE `guid` = 80458 AND `id` = 195260;
UPDATE `gameobject` SET `position_x` = -9488.69, `position_y` = -15.84, `orientation` = 1.5148, `rotation2` = 0.687035, `rotation3` = 0.726625 WHERE `guid` = 80459 AND `id` = 195260;
UPDATE `gameobject` SET `position_x` = -9485.08, `position_y` = -15.91, `orientation` = 1.5323, `rotation2` = 0.693366, `rotation3` = 0.720585 WHERE `guid` = 80460 AND `id` = 195260;
UPDATE `gameobject` SET `position_x` = -9483.07, `position_y` = -22.94, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 80487 AND `id` = 195260;
UPDATE `gameobject` SET `position_x` = -9488.45, `position_y` = -4.5, `orientation` = 1.5497, `rotation2` = 0.699609, `rotation3` = 0.714526 WHERE `guid` = 80508 AND `id` = 195260;
UPDATE `gameobject` SET `position_x` = -9472.88, `position_y` = -2.27, `orientation` = 6.2447, `rotation2` = 0.019241, `rotation3` = -0.999815 WHERE `guid` = 80623 AND `id` = 195263;
UPDATE `gameobject` SET `position_x` = -9492.09, `position_y` = 5.52, `orientation` = 1.5847, `rotation2` = 0.712005, `rotation3` = 0.702174 WHERE `guid` = 80633 AND `id` = 195263;
UPDATE `gameobject` SET `position_x` = -9473.22, `position_y` = -18.94, `orientation` = 0.0139, `rotation2` = 0.00695, `rotation3` = 0.999976 WHERE `guid` = 80634 AND `id` = 195263;
UPDATE `gameobject` SET `position_x` = -9499.19, `position_y` = -15.61, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 80640 AND `id` = 195263;
UPDATE `gameobject` SET `position_x` = -9498.96, `position_y` = -4.18, `orientation` = 3.1729, `rotation2` = 0.999877, `rotation3` = -0.015653 WHERE `guid` = 80641 AND `id` = 195263;
UPDATE `gameobject` SET `position_x` = -9477.22, `position_y` = -5.41, `orientation` = 3.2427, `rotation2` = 0.998722, `rotation3` = -0.050532 WHERE `guid` = 80669 AND `id` = 195264;
UPDATE `gameobject` SET `position_x` = -9477.44, `position_y` = -15.49, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 80670 AND `id` = 195264;
UPDATE `gameobject` SET `position_x` = -9475.42, `position_y` = -23.15, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 80671 AND `id` = 195264;
UPDATE `gameobject` SET `position_x` = -9477.53, `position_y` = -13.33, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 80679 AND `id` = 195264;
UPDATE `gameobject` SET `position_x` = -9477.48, `position_y` = -7.79, `orientation` = 3.1729, `rotation2` = 0.999877, `rotation3` = -0.015653 WHERE `guid` = 80680 AND `id` = 195264;
UPDATE `gameobject` SET `position_x` = -9480.11, `position_y` = 10.19, `orientation` = 1.5148, `rotation2` = 0.687035, `rotation3` = 0.726625 WHERE `guid` = 80873 AND `id` = 195266;
UPDATE `gameobject` SET `position_x` = -9482.97, `position_y` = -17.17, `orientation` = 5.4942, `rotation2` = 0.38434, `rotation3` = -0.923192 WHERE `guid` = 81108 AND `id` = 189303;
UPDATE `gameobject` SET `position_x` = -9477.99, `position_y` = -19.27, `orientation` = 5.0928, `rotation2` = 0.560668, `rotation3` = -0.82804 WHERE `guid` = 81121 AND `id` = 180523;
UPDATE `gameobject` SET `position_x` = -9491.9, `position_y` = 7.84, `orientation` = 1.6078, `rotation2` = 0.720068, `rotation3` = 0.693904 WHERE `guid` = 151923 AND `id` = 113770;
UPDATE `gameobject` SET `position_x` = -9436, `position_y` = 110.5, `position_z` = 57.46 WHERE `guid` = 151924 AND `id` = 113771;
UPDATE `gameobject` SET `position_x` = -9427.5, `position_y` = 66.5, `position_z` = 56.91 WHERE `guid` = 151926 AND `id` = 113768;
UPDATE `gameobject` SET `position_z` = 58.32 WHERE `guid` = 151927 AND `id` = 113769;
UPDATE `gameobject` SET `position_x` = -9475.8, `position_y` = 5.08, `orientation` = 4.1407, `rotation2` = 0.877796, `rotation3` = -0.479034 WHERE `guid` = 151929 AND `id` = 113771;
UPDATE `gameobject` SET `position_x` = -9472.24, `position_y` = -6.15, `orientation` = 3.0844, `rotation2` = 0.999591, `rotation3` = 0.028592 WHERE `guid` = 151930 AND `id` = 113772;
UPDATE `gameobject` SET `position_x` = -9472.9, `position_y` = -15.88, `orientation` = 2.3657, `rotation2` = 0.925688, `rotation3` = 0.378288 WHERE `guid` = 151932 AND `id` = 113769;
UPDATE `gameobject` SET `position_x` = -9486.21, `position_y` = -44.79, `position_z` = 56.92, `orientation` = 1.8238, `rotation2` = 0.790668, `rotation3` = 0.612245 WHERE `guid` = 151933 AND `id` = 113770;
UPDATE `gameobject` SET `position_x` = -9494.21, `position_y` = -28.68, `orientation` = 0.253, `rotation2` = 0.126163, `rotation3` = 0.99201 WHERE `guid` = 151934 AND `id` = 113771;
UPDATE `gameobject` SET `position_x` = -9497.95, `position_y` = 3.33, `orientation` = 0.418, `rotation2` = 0.207482, `rotation3` = 0.978239 WHERE `guid` = 151936 AND `id` = 113768;
UPDATE `gameobject` SET `position_x` = -9483, `position_y` = 49, `position_z` = 56.6 WHERE `guid` = 151937 AND `id` = 113769;
UPDATE `gameobject` SET `position_z` = 58.45 WHERE `guid` = 151942 AND `id` = 113769;
UPDATE `gameobject` SET `position_x` = -9471.5, `position_y` = 101, `position_z` = 57.92 WHERE `guid` = 151944 AND `id` = 113771;
UPDATE `gameobject` SET `position_x` = -9412, `position_y` = -30.5, `position_z` = 63.33 WHERE `guid` = 206537 AND `id` = 1618;
UPDATE `gameobject` SET `position_z` = 59.46 WHERE `guid` = 206542 AND `id` = 1618;

-- Elwynn quest mobs and the Goldshire Beginner's Book
DELETE FROM `creature` WHERE `guid` IN (9002260, 9002261, 9002262, 9002263, 9002264, 9002265, 9002266, 9002267, 9002268, 9002269, 9002290, 9002291, 9002292, 9002306, 9002330, 9002331, 9002332, 9002333, 9002334, 9002335, 9002336, 9002337, 9002338, 9002339, 9002340, 9002341, 9002342, 9002343, 9013200);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9002260, 1922, 0, 0, 0, 1, 1, 0, -9365, -715, 66.35, 3.5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, between the two northern oaks'),
(9002261, 1922, 0, 0, 0, 1, 1, 0, -9352, -740, 69.08, 4, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, north-east edge'),
(9002262, 1922, 0, 0, 0, 1, 1, 0, -9440, -695, 64.64, 2, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, open grass west of the southern oaks'),
(9002263, 1922, 0, 0, 0, 1, 1, 0, -9470, -705, 62.85, 1, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, south-west edge toward the tower'),
(9002264, 1922, 0, 0, 0, 1, 1, 0, -9395, -760, 64.73, 5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, east clearing'),
(9002265, 1922, 0, 0, 0, 1, 1, 0, -9470, -785, 61.02, 0.5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, south-east clearing'),
(9002266, 822, 0, 0, 0, 1, 1, 0, -9410, -675, 65.58, 2, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, west edge'),
(9002267, 822, 0, 0, 0, 1, 1, 0, -9445, -735, 65.09, 4, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, under the southern oak'),
(9002268, 822, 0, 0, 0, 1, 1, 0, -9380, -775, 63.66, 5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, beside the eastern oak'),
(9002269, 822, 0, 0, 0, 1, 1, 0, -9425, -775, 65.01, 4.5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, south-east grass'),
(9002290, 43, 0, 0, 0, 1, 1, 0, -9030, -591, 56.38, 1.57, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Jasperlode Mine spider chamber, upper east lobe between the webbed spiders'),
(9002291, 43, 0, 0, 0, 1, 1, 0, -9045, -610, 52.5, 3.9, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Jasperlode Mine spider chamber, lower east lobe on the way to Mother Fang''s den'),
(9002292, 43, 0, 0, 0, 1, 1, 0, -9030, -558, 55.16, 4.7, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Jasperlode Mine spider chamber, west lobe'),
(9002306, 478, 0, 0, 0, 1, 1, 1, -9005, -800, 69.62, 1.6, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Riverpaw camp on the north shore of Stone Cairn Lake, west of the camp'),
(9002330, 1922, 0, 0, 0, 1, 1, 0, -9383, -800, 66.36, 0.8, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, north-east, past the eastern oak'),
(9002331, 822, 0, 0, 0, 1, 1, 0, -9352, -712, 66.43, 3.9, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, north edge, beyond the northern oaks'),
(9002332, 1922, 0, 0, 0, 1, 1, 0, -9383, -684, 67.72, 4.3, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, north-west, between the north-west oak and the path'),
(9002333, 1922, 0, 0, 0, 1, 1, 0, -9442, -668, 64.94, 5.2, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, west edge of the grass'),
(9002334, 822, 0, 0, 0, 1, 1, 0, -9482, -732, 60.97, 0.2, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, south-west, beside the south-west oak'),
(9002335, 1922, 0, 0, 0, 1, 1, 0, -9484, -757, 61.78, 0.6, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, south, toward the tower grounds'),
(9002336, 822, 0, 0, 0, 1, 1, 0, -9447, -798, 62.13, 1.1, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, south-east, under the south-east oak'),
(9002337, 1922, 0, 0, 0, 1, 1, 0, -9405, -797, 66.58, 1.9, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, east, between the two eastern clearings'),
(9002338, 1922, 0, 0, 0, 1, 1, 0, -9420, -757, 65.14, 3, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, middle of the wood, south of the central oak'),
(9002339, 822, 0, 0, 0, 1, 1, 0, -9380, -742, 68.64, 2.4, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, north-east clearing below the eastern oak'),
(9002340, 1922, 0, 0, 0, 1, 1, 0, -9412, -698, 67.36, 4.5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, clearing between the western oaks'),
(9002341, 822, 0, 0, 0, 1, 1, 0, -9462, -720, 63.31, 5.8, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, north side of the south-west oak'),
(9002342, 1922, 0, 0, 0, 1, 1, 0, -9362, -757, 67.23, 2.9, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, north-east, below the eastern oak'),
(9002343, 1922, 0, 0, 0, 1, 1, 0, -9462, -800, 60.17, 1.3, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, south-east clearing, with the pair by the oak'),
(9013200, 75118, 0, 0, 0, 1, 1, 0, -9484.3, 37.6, 56.667, 3.14159, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'PR #5423 port: Beginner''s Book of Ascension at the market');

-- Goldshire and Elwynn quest NPC models
UPDATE `creature_template_model` SET `CreatureDisplayID` = 1944 WHERE `CreatureID` = 162801 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 2959 WHERE `CreatureID` = 162805 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 5080 WHERE `CreatureID` = 162806 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 1753 WHERE `CreatureID` = 162807 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 5552 WHERE `CreatureID` = 162808 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 1443 WHERE `CreatureID` = 162809 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 25555 WHERE `CreatureID` = 162810 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 3370 WHERE `CreatureID` = 162811 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 25556 WHERE `CreatureID` = 162812 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 15769 WHERE `CreatureID` = 162813 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 1441 WHERE `CreatureID` = 162814 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 18616 WHERE `CreatureID` = 162817 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 18617 WHERE `CreatureID` = 162818 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 18618 WHERE `CreatureID` = 162819 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 18619 WHERE `CreatureID` = 162820 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 3534 WHERE `CreatureID` = 162821 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 3703 WHERE `CreatureID` = 162822 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 1943 WHERE `CreatureID` = 162823 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 3324 WHERE `CreatureID` = 162824 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 3361 WHERE `CreatureID` = 162826 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 5080 WHERE `CreatureID` = 162943 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 3768 WHERE `CreatureID` = 900017 AND `Idx` = 0;

-- Dun Morogh and Durotar quest chains
UPDATE `quest_template` SET `RewardNextQuest` = 1660007 WHERE `ID` = 1660006;
UPDATE `quest_template` SET `QuestLevel` = -1, `RewardNextQuest` = 1660008 WHERE `ID` = 1660007;
UPDATE `quest_template` SET `QuestLevel` = -1, `RewardNextQuest` = 1660009 WHERE `ID` = 1660008;
UPDATE `quest_template` SET `RewardNextQuest` = 1660037 WHERE `ID` = 1660018;
UPDATE `quest_template` SET `QuestLevel` = -1 WHERE `ID` = 1660039;
UPDATE `quest_template` SET `RewardNextQuest` = 1660077, `RewardFactionID2` = 54, `RewardFactionValue2` = 5 WHERE `ID` = 1660076;
UPDATE `quest_template` SET `RewardFactionID2` = 54, `RewardFactionValue2` = 5 WHERE `ID` = 1660077;
UPDATE `quest_template` SET `RewardFactionID2` = 54, `RewardFactionValue2` = 5 WHERE `ID` = 1660079;
