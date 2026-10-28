-- Conquest of Azeroth rebuilt Goldshire and parts of Northshire and Elwynn. It moved the Lion's Pride Inn
-- 39 yards south-west and turned it 5.8 degrees, laid a market plaza on the old site, raised a town hall,
-- a walled manor and new farms, and re-sculpted the ground. The stock spawns stayed behind: inn furniture
-- and trainers float over the market or lie under it, quest givers stand where CoA no longer has them,
-- animals and herbs sit inside new walls or under raised ground. This moves them.
--
-- WHERE EACH POSITION COMES FROM
--   inn  every stock row of the inn follows the building's rigid move: turn +0.101122 rad about the stock
--     origin (-9464.2474, 24.3991), then shift to the CoA origin (-9483.1654, -10.1595). z is unchanged,
--     as are the floors (ground 56.96, upper 63.82, cellar 49.79). Farley, Pestle, Josetta and
--     Melika stand at their QuestSuperTrack turn-in points instead, 0.1-0.4 yd from the transform.
--   quest givers CoA moved  QuestSuperTrack turn-in points in the client (Dughan, Merissa, the Flame
--     Warden, the Spring Collector, Morja, Stormbrow, McBride, Neals).
--   the Mirror Lake Defias camp  CoA walled its ground in as the Spada manor; the three bandits and the
--     Thuros spawn point inside the walls go to the Mirror Lake Orchard, which quest 17008 says the
--     Defias have overrun.
--   everything else  the same spot with z on the CoA floor, or the nearest open ground chosen by hand
--     beside the landmark that trapped it; every point was checked against the server collision data.
--   Goldshire's signpost  CoA took the post off the crossroads and stood a 1.626-scale one on the market
--     plaza; its direction arms and Midsummer hanging follow: turn +0.170606 rad about the stock post
--     (-9500.3444, 67.0526, base 56.325), scale by 1.626, shift to the plaza post (-9464.0724, 41.6306,
--     base 56.88). The arms are scaled with it.
--   inn rest area  CoA AreaTrigger.dbc 562.
--   Antonio Perelli  his inn visit walks the market lanes to the moved inn's porch, then the stock route
--     inside.
--
-- Left alone: the Darkmoon Faire and Midsummer bonfire layouts (their ground is now the town hall and a
-- farmhouse), Stormwind City, and decorations that hung on replaced buildings.
-- Each UPDATE matches guid and entry, so a row something else has changed is left alone.

-- ---------------------------------------------------------------------------
-- 1. Lion's Pride Inn creatures
-- ---------------------------------------------------------------------------
UPDATE `creature` SET `position_x` = -9483.51, `position_y` = -22.01, `position_z` = 63.9038, `orientation` = 1.2007 WHERE `guid` = 79645 AND `id` = 917;
UPDATE `creature` SET `position_x` = -9476.27, `position_y` = -4.47, `position_z` = 63.9038, `orientation` = 3.0682 WHERE `guid` = 79646 AND `id` = 2329;
UPDATE `creature` SET `position_x` = -9477.31, `position_y` = -25.63, `position_z` = 57.1459, `orientation` = 1.5672 WHERE `guid` = 79647 AND `id` = 465;
UPDATE `creature` SET `position_x` = -9491.56, `position_y` = -0.91, `position_z` = 63.9038, `orientation` = 4.7262 WHERE `guid` = 80344 AND `id` = 328;
UPDATE `creature` SET `position_x` = -9490.91, `position_y` = -8.312, `position_z` = 56.339, `orientation` = 5.6862 WHERE `guid` = 80345 AND `id` = 6778;
UPDATE `creature` SET `position_x` = -9480.69, `position_y` = -18.104, `position_z` = 56.963, `orientation` = 3.138 WHERE `guid` = 80346 AND `id` = 295;
UPDATE `creature` SET `position_x` = -9480.76, `position_y` = -1.24, `position_z` = 63.82, `orientation` = 4.4644 WHERE `guid` = 80347 AND `id` = 377;
UPDATE `creature` SET `position_x` = -9482.71, `position_y` = -24.96, `position_z` = 57.1459, `orientation` = 1.5497 WHERE `guid` = 80348 AND `id` = 151;
UPDATE `creature` SET `position_x` = -9482.87, `position_y` = -34.59, `position_z` = 57.0335, `orientation` = 6.2272 WHERE `guid` = 80349 AND `id` = 3935;
UPDATE `creature` SET `position_x` = -9479.89, `position_y` = -1.924, `position_z` = 56.966, `orientation` = 3.0856 WHERE `guid` = 80350 AND `id` = 253;
UPDATE `creature` SET `position_x` = -9482.85, `position_y` = -40.21, `position_z` = 49.8766, `orientation` = 4.6739 WHERE `guid` = 80352 AND `id` = 6374;
UPDATE `creature` SET `position_x` = -9488.67, `position_y` = -40.6, `position_z` = 49.8778, `orientation` = 5.6513 WHERE `guid` = 80353 AND `id` = 906;
UPDATE `creature` SET `position_x` = -9488.97, `position_y` = -43.91, `position_z` = 49.8779, `orientation` = 0.0488 WHERE `guid` = 80354 AND `id` = 6121;
UPDATE `creature` SET `position_x` = -9482.97, `position_y` = -39.22, `position_z` = 57.033, `orientation` = 1.7417 WHERE `guid` = 80355 AND `id` = 1430;
UPDATE `creature` SET `position_x` = -9487.28, `position_y` = -10.04, `position_z` = 56.5369, `orientation` = 6.1923 WHERE `guid` = 89359 AND `id` = 15760;
UPDATE `creature` SET `position_x` = -9484.89, `position_y` = -9.8, `position_z` = 56.6126, `orientation` = 3.2253 WHERE `guid` = 89360 AND `id` = 15760;
UPDATE `creature` SET `position_x` = -9480.25, `position_y` = 6.77, `position_z` = 64.302, `orientation` = 4.8031 WHERE `guid` = 240026 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9482.71, `position_y` = 7.78, `position_z` = 62.6981, `orientation` = 4.4968 WHERE `guid` = 240027 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9477.96, `position_y` = 8.17, `position_z` = 63.0202, `orientation` = 4.4968 WHERE `guid` = 240028 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9484.41, `position_y` = -1.98, `position_z` = 72.6435, `orientation` = 3.0241 WHERE `guid` = 240101 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9479.29, `position_y` = -2.13, `position_z` = 72.8428, `orientation` = 2.6825 WHERE `guid` = 240156 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9475.65, `position_y` = -4.62, `position_z` = 73.8424, `orientation` = 4.1512 WHERE `guid` = 240157 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9494.63, `position_y` = -5.66, `position_z` = 74.3358, `orientation` = 6.2089 WHERE `guid` = 240176 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9499.65, `position_y` = -4.96, `position_z` = 68.8904, `orientation` = 6.1697 WHERE `guid` = 240177 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9499.87, `position_y` = 0.48, `position_z` = 68.3554, `orientation` = 6.0636 WHERE `guid` = 240178 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9497, `position_y` = 2.57, `position_z` = 72.8948, `orientation` = 4.9327 WHERE `guid` = 240179 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9496.48, `position_y` = 7.77, `position_z` = 72.9378, `orientation` = 4.2533 WHERE `guid` = 240180 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9492.92, `position_y` = 7.82, `position_z` = 75.3386, `orientation` = 1.6026 WHERE `guid` = 240181 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9489.67, `position_y` = 0.99, `position_z` = 73.544, `orientation` = 4.3829 WHERE `guid` = 240182 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9488.5, `position_y` = 4.42, `position_z` = 73.0729, `orientation` = 2.6589 WHERE `guid` = 240183 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9484.62, `position_y` = 3.1, `position_z` = 70.4258, `orientation` = 3.1223 WHERE `guid` = 240184 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9473.71, `position_y` = -0.92, `position_z` = 72.2759, `orientation` = 5.6199 WHERE `guid` = 240189 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9474.88, `position_y` = 3.22, `position_z` = 69.8408, `orientation` = 5.6199 WHERE `guid` = 240190 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9477.81, `position_y` = 5.52, `position_z` = 68.205, `orientation` = 5.612 WHERE `guid` = 240191 AND `id` = 23686;
UPDATE `creature` SET `position_x` = -9488.5, `position_y` = -44.27, `position_z` = 49.794, `orientation` = 0.3341 WHERE `guid` = 241343 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9487.91, `position_y` = -40.19, `position_z` = 49.794, `orientation` = 5.7121 WHERE `guid` = 241347 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9491.86, `position_y` = -1.29, `position_z` = 63.82, `orientation` = 4.5081 WHERE `guid` = 241348 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9490.15, `position_y` = -8.21, `position_z` = 56.339, `orientation` = 5.8521 WHERE `guid` = 241350 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9482.94, `position_y` = -39.69, `position_z` = 49.793, `orientation` = 4.7921 WHERE `guid` = 241359 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9482.94, `position_y` = -39.69, `position_z` = 57.033, `orientation` = 1.7421 WHERE `guid` = 241360 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9482.45, `position_y` = -34.55, `position_z` = 57.033, `orientation` = 0.8431 WHERE `guid` = 241362 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9483.72, `position_y` = -22.03, `position_z` = 63.904, `orientation` = 1.2011 WHERE `guid` = 241363 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9482.42, `position_y` = -24.93, `position_z` = 57.146, `orientation` = 1.5501 WHERE `guid` = 241366 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9481.1, `position_y` = -18.2, `position_z` = 57.046, `orientation` = 3.1381 WHERE `guid` = 241372 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9480.82, `position_y` = -1.14, `position_z` = 63.904, `orientation` = 4.4641 WHERE `guid` = 241375 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9477.33, `position_y` = -25.64, `position_z` = 57.146, `orientation` = 1.5671 WHERE `guid` = 241377 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9479.7, `position_y` = -2.23, `position_z` = 57.049, `orientation` = 3.0861 WHERE `guid` = 241378 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9476.46, `position_y` = -4.49, `position_z` = 63.904, `orientation` = 3.0681 WHERE `guid` = 241381 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9479.28, `position_y` = -8.11, `position_z` = 56.3399, `orientation` = 5.5471 WHERE `guid` = 244077 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9487.28, `position_y` = -10.04, `position_z` = 56.5369, `orientation` = 6.1923 WHERE `guid` = 244198 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9484.89, `position_y` = -9.8, `position_z` = 56.6126, `orientation` = 3.2253 WHERE `guid` = 244199 AND `id` = 32820;
UPDATE `creature` SET `position_x` = -9479.28, `position_y` = -8.11, `position_z` = 56.3399, `orientation` = 5.5471 WHERE `guid` = 244819 AND `id` = 32836;

-- ---------------------------------------------------------------------------
-- 2. Lion's Pride Inn objects
-- ---------------------------------------------------------------------------
UPDATE `gameobject` SET `position_x` = -9496.91, `position_y` = -1.29, `position_z` = 56.9661, `orientation` = 0.2407, `rotation2` = 0.12006, `rotation3` = 0.992767 WHERE `guid` = 2302 AND `id` = 180428;
UPDATE `gameobject` SET `position_x` = -9493.25, `position_y` = 0.03, `position_z` = 57.6953, `orientation` = 6.1225, `rotation2` = 0.080256, `rotation3` = -0.996774 WHERE `guid` = 2314 AND `id` = 180429;
UPDATE `gameobject` SET `position_x` = -9480.02, `position_y` = -1.07, `position_z` = 58.3619, `orientation` = 4.6739, `rotation2` = 0.720583, `rotation3` = -0.693369 WHERE `guid` = 2381 AND `id` = 180410;
UPDATE `gameobject` SET `position_x` = -9474.88, `position_y` = -7.19, `position_z` = 64.9316, `orientation` = 2.6144, `rotation2` = 0.965459, `rotation3` = 0.260554 WHERE `guid` = 3203 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9477.13, `position_y` = -5.7, `position_z` = 57.472, `orientation` = 3.1031, `rotation2` = 0.999815, `rotation3` = 0.019245 WHERE `guid` = 3204 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9477.23, `position_y` = -6.65, `position_z` = 57.4578, `orientation` = 3.0333, `rotation2` = 0.998534, `rotation3` = 0.05412 WHERE `guid` = 3205 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9477.38, `position_y` = -7.56, `position_z` = 57.5069, `orientation` = 3.0158, `rotation2` = 0.998023, `rotation3` = 0.062855 WHERE `guid` = 3206 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9477.41, `position_y` = -14.47, `position_z` = 57.4622, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 3207 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9477.54, `position_y` = -13.42, `position_z` = 57.5173, `orientation` = 3.1903, `rotation2` = 0.999703, `rotation3` = -0.024351 WHERE `guid` = 3208 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9477.37, `position_y` = -15.35, `position_z` = 57.4671, `orientation` = 3.1031, `rotation2` = 0.999815, `rotation3` = 0.019245 WHERE `guid` = 3209 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9481.95, `position_y` = -27.19, `position_z` = 64.9177, `orientation` = 5.5989, `rotation2` = 0.335506, `rotation3` = -0.942038 WHERE `guid` = 3210 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9470.89, `position_y` = 5.86, `position_z` = 65.8999, `orientation` = 3.2951, `rotation2` = 0.997056, `rotation3` = -0.076678 WHERE `guid` = 8011 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9472.46, `position_y` = -2.31, `position_z` = 68.453, `orientation` = 0.2058, `rotation2` = 0.102719, `rotation3` = 0.99471 WHERE `guid` = 8171 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9472.72, `position_y` = -18.87, `position_z` = 68.4044, `orientation` = 0.1709, `rotation2` = 0.085346, `rotation3` = 0.996351 WHERE `guid` = 8172 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9480.1, `position_y` = 10.74, `position_z` = 63.4504, `orientation` = 1.7068, `rotation2` = 0.75352, `rotation3` = 0.657425 WHERE `guid` = 8173 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9479.32, `position_y` = -22.03, `position_z` = 71.8053, `orientation` = 2.1083, `rotation2` = 0.869481, `rotation3` = 0.493967 WHERE `guid` = 8174 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9479.38, `position_y` = -36.54, `position_z` = 63.8205, `orientation` = 1.5323, `rotation2` = 0.693366, `rotation3` = 0.720585 WHERE `guid` = 26242 AND `id` = 1560;
UPDATE `gameobject` SET `position_x` = -9485.26, `position_y` = -18.65, `position_z` = 63.9322, `orientation` = 0.1709, `rotation2` = 0.085346, `rotation3` = 0.996351 WHERE `guid` = 26243 AND `id` = 177502;
UPDATE `gameobject` SET `position_x` = -9474.77, `position_y` = -12.34, `position_z` = 56.9157, `orientation` = 1.4188, `rotation2` = 0.651379, `rotation3` = 0.758753 WHERE `guid` = 26244 AND `id` = 22772;
UPDATE `gameobject` SET `position_x` = -9476.51, `position_y` = -17.87, `position_z` = 56.9748, `orientation` = 3.8798, `rotation2` = 0.932651, `rotation3` = -0.36078 WHERE `guid` = 26246 AND `id` = 22803;
UPDATE `gameobject` SET `position_x` = -9473.86, `position_y` = -10.3, `position_z` = 56.9157, `orientation` = 0.4851, `rotation2` = 0.240179, `rotation3` = 0.970729 WHERE `guid` = 26247 AND `id` = 22773;
UPDATE `gameobject` SET `position_x` = -9478.16, `position_y` = -20.92, `position_z` = 56.9748, `orientation` = 1.5236, `rotation2` = 0.690225, `rotation3` = 0.723595 WHERE `guid` = 26249 AND `id` = 177495;
UPDATE `gameobject` SET `position_x` = -9475.37, `position_y` = -6.39, `position_z` = 63.8175, `orientation` = 4.351, `rotation2` = 0.822671, `rotation3` = -0.568518 WHERE `guid` = 26250 AND `id` = 177500;
UPDATE `gameobject` SET `position_x` = -9475.63, `position_y` = -9.01, `position_z` = 63.8175, `orientation` = 1.9075, `rotation2` = 0.815591, `rotation3` = 0.578629 WHERE `guid` = 26251 AND `id` = 177501;
UPDATE `gameobject` SET `position_x` = -9477.29, `position_y` = 2.62, `position_z` = 63.9322, `orientation` = 4.6913, `rotation2` = 0.714523, `rotation3` = -0.699612 WHERE `guid` = 26252 AND `id` = 177503;
UPDATE `gameobject` SET `position_x` = -9475.18, `position_y` = -9.43, `position_z` = 56.9157, `orientation` = 3.1205, `rotation2` = 0.999944, `rotation3` = 0.010546 WHERE `guid` = 26253 AND `id` = 22774;
UPDATE `gameobject` SET `position_x` = -9476.63, `position_y` = -20.64, `position_z` = 56.9748, `orientation` = 2.3264, `rotation2` = 0.918076, `rotation3` = 0.396404 WHERE `guid` = 26255 AND `id` = 177494;
UPDATE `gameobject` SET `position_x` = -9482.55, `position_y` = -28.66, `position_z` = 63.8175, `orientation` = 1.2094, `rotation2` = 0.568515, `rotation3` = 0.822673 WHERE `guid` = 26256 AND `id` = 22783;
UPDATE `gameobject` SET `position_x` = -9475.22, `position_y` = -10.89, `position_z` = 56.9157, `orientation` = 4.2114, `rotation2` = 0.860318, `rotation3` = -0.509758 WHERE `guid` = 26257 AND `id` = 22777;
UPDATE `gameobject` SET `position_x` = -9478.08, `position_y` = -17.59, `position_z` = 56.9748, `orientation` = 4.7088, `rotation2` = 0.708375, `rotation3` = -0.705837 WHERE `guid` = 26259 AND `id` = 22804;
UPDATE `gameobject` SET `position_x` = -9479.44, `position_y` = -18.11, `position_z` = 64.9663, `orientation` = 4.9706, `rotation2` = 0.610184, `rotation3` = -0.79226 WHERE `guid` = 26260 AND `id` = 175749;
UPDATE `gameobject` SET `position_x` = -9479.08, `position_y` = 2.66, `position_z` = 63.9322, `orientation` = 4.6913, `rotation2` = 0.714523, `rotation3` = -0.699612 WHERE `guid` = 26792 AND `id` = 177504;
UPDATE `gameobject` SET `position_x` = -9496.3, `position_y` = -6.19, `position_z` = 56.3435, `orientation` = 5.5378, `rotation2` = 0.364125, `rotation3` = -0.93135 WHERE `guid` = 26800 AND `id` = 22811;
UPDATE `gameobject` SET `position_x` = -9494.91, `position_y` = -5.93, `position_z` = 56.3435, `orientation` = 4.7088, `rotation2` = 0.708375, `rotation3` = -0.705837 WHERE `guid` = 26801 AND `id` = 22812;
UPDATE `gameobject` SET `position_x` = -9491.69, `position_y` = -5.97, `position_z` = 56.3435, `orientation` = 4.5779, `rotation2` = 0.753022, `rotation3` = -0.657995 WHERE `guid` = 26802 AND `id` = 177497;
UPDATE `gameobject` SET `position_x` = -9493.31, `position_y` = -5.95, `position_z` = 56.3435, `orientation` = 4.7088, `rotation2` = 0.708375, `rotation3` = -0.705837 WHERE `guid` = 26803 AND `id` = 177498;
UPDATE `gameobject` SET `position_x` = -9496.52, `position_y` = -7.52, `position_z` = 56.3435, `orientation` = 0.0051, `rotation2` = 0.00255, `rotation3` = 0.999997 WHERE `guid` = 26804 AND `id` = 177499;
UPDATE `gameobject` SET `position_x` = -9490, `position_y` = -6.27, `position_z` = 56.3435, `orientation` = 4.0368, `rotation2` = 0.901487, `rotation3` = -0.432807 WHERE `guid` = 26805 AND `id` = 22813;
UPDATE `gameobject` SET `position_x` = -9479.76, `position_y` = -17.82, `position_z` = 56.9748, `orientation` = 5.276, `rotation2` = 0.482575, `rotation3` = -0.875854 WHERE `guid` = 26806 AND `id` = 22806;
UPDATE `gameobject` SET `position_x` = -9479.71, `position_y` = -20.53, `position_z` = 56.9748, `orientation` = 1.157, `rotation2` = 0.546769, `rotation3` = 0.837284 WHERE `guid` = 26807 AND `id` = 177496;
UPDATE `gameobject` SET `position_x` = -9486.16, `position_y` = -42.29, `position_z` = 57.4436, `orientation` = 1.4887, `rotation2` = 0.677494, `rotation3` = 0.735528 WHERE `guid` = 26808 AND `id` = 22776;
UPDATE `gameobject` SET `position_x` = -9484.94, `position_y` = -41.73, `position_z` = 57.4436, `orientation` = 0.0837, `rotation2` = 0.041838, `rotation3` = 0.999124 WHERE `guid` = 26810 AND `id` = 22775;
UPDATE `gameobject` SET `position_x` = -9475.88, `position_y` = -25.32, `position_z` = 56.9626, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 30677 AND `id` = 3658;
UPDATE `gameobject` SET `position_x` = -9475.88, `position_y` = -25.32, `position_z` = 56.9626, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 30839 AND `id` = 3719;
UPDATE `gameobject` SET `position_x` = -9488.49, `position_y` = 0.18, `position_z` = 65.3135, `orientation` = 3.9059, `rotation2` = 0.927864, `rotation3` = -0.37292 WHERE `guid` = 34374 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9485.22, `position_y` = -19.76, `position_z` = 64.7441, `orientation` = 4.5866, `rotation2` = 0.750152, `rotation3` = -0.661265 WHERE `guid` = 34375 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9491.86, `position_y` = 5.89, `position_z` = 58.33, `orientation` = 3.5045, `rotation2` = 0.983582, `rotation3` = -0.18046 WHERE `guid` = 36184 AND `id` = 180405;
UPDATE `gameobject` SET `position_x` = -9496.98, `position_y` = -2.33, `position_z` = 63.8205, `orientation` = 1.9163, `rotation2` = 0.818129, `rotation3` = 0.575035 WHERE `guid` = 36624 AND `id` = 180406;
UPDATE `gameobject` SET `position_x` = -9494.89, `position_y` = -7.51, `position_z` = 56.9783, `orientation` = 1.445, `rotation2` = 0.661262, `rotation3` = 0.750155 WHERE `guid` = 36625 AND `id` = 180406;
UPDATE `gameobject` SET `position_x` = -9483.42, `position_y` = -33.82, `position_z` = 63.8205, `orientation` = 1.8639, `rotation2` = 0.802784, `rotation3` = 0.59627 WHERE `guid` = 36626 AND `id` = 180406;
UPDATE `gameobject` SET `position_x` = -9490.86, `position_y` = -2.94, `position_z` = 56.9661, `orientation` = 2.6668, `rotation2` = 0.971954, `rotation3` = 0.235173 WHERE `guid` = 37047 AND `id` = 180407;
UPDATE `gameobject` SET `position_x` = -9496.68, `position_y` = -22.77, `position_z` = 60.185, `orientation` = 2.9111, `rotation2` = 0.993366, `rotation3` = 0.114991 WHERE `guid` = 37050 AND `id` = 180407;
UPDATE `gameobject` SET `position_x` = -9488.96, `position_y` = -8.14, `position_z` = 64.633, `orientation` = 4.4819, `rotation2` = 0.783726, `rotation3` = -0.621106 WHERE `guid` = 37401 AND `id` = 180410;
UPDATE `gameobject` SET `position_x` = -9486.08, `position_y` = -16.61, `position_z` = 64.876, `orientation` = 0.2931, `rotation2` = 0.146026, `rotation3` = 0.989281 WHERE `guid` = 37402 AND `id` = 180410;
UPDATE `gameobject` SET `position_x` = -9496.97, `position_y` = -0.13, `position_z` = 58.3203, `orientation` = 0.0139, `rotation2` = 0.00695, `rotation3` = 0.999976 WHERE `guid` = 37403 AND `id` = 180410;
UPDATE `gameobject` SET `position_x` = -9492.03, `position_y` = 8.7, `position_z` = 65.787, `orientation` = 4.3772, `rotation2` = 0.815153, `rotation3` = -0.579246 WHERE `guid` = 37507 AND `id` = 180411;
UPDATE `gameobject` SET `position_x` = -9492.82, `position_y` = -29.08, `position_z` = 65.951, `orientation` = 1.1309, `rotation2` = 0.535796, `rotation3` = 0.844348 WHERE `guid` = 37508 AND `id` = 180411;
UPDATE `gameobject` SET `position_x` = -9493.08, `position_y` = -23.34, `position_z` = 64.1442, `orientation` = 4.639, `rotation2` = 0.732572, `rotation3` = -0.68069 WHERE `guid` = 37509 AND `id` = 180411;
UPDATE `gameobject` SET `position_x` = -9486.14, `position_y` = -5.66, `position_z` = 64.7649, `orientation` = 5.948, `rotation2` = 0.166809, `rotation3` = -0.985989 WHERE `guid` = 37799 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9490.13, `position_y` = -13.44, `position_z` = 57.2409, `orientation` = 1.3578, `rotation2` = 0.627937, `rotation3` = 0.778264 WHERE `guid` = 37800 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9497, `position_y` = -11.42, `position_z` = 57.1311, `orientation` = 0.1535, `rotation2` = 0.076675, `rotation3` = 0.997056 WHERE `guid` = 37801 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9488.31, `position_y` = -0.04, `position_z` = 65.2719, `orientation` = 3.9234, `rotation2` = 0.924565, `rotation3` = -0.381024 WHERE `guid` = 37802 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9495.61, `position_y` = 3.5, `position_z` = 64.7441, `orientation` = 5.023, `rotation2` = 0.58922, `rotation3` = -0.807973 WHERE `guid` = 37803 AND `id` = 180425;
UPDATE `gameobject` SET `position_x` = -9489.08, `position_y` = -45.45, `position_z` = 66.0361, `orientation` = 5.3895, `rotation2` = 0.43212, `rotation3` = -0.901816 WHERE `guid` = 38988 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9479.77, `position_y` = -46.79, `position_z` = 71.7849, `orientation` = 6.14, `rotation2` = 0.071532, `rotation3` = -0.997438 WHERE `guid` = 38989 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9472.05, `position_y` = -45.69, `position_z` = 66.1144, `orientation` = 1.4276, `rotation2` = 0.654711, `rotation3` = 0.755879 WHERE `guid` = 38990 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9499.94, `position_y` = 7.67, `position_z` = 65.9558, `orientation` = 2.8762, `rotation2` = 0.991209, `rotation3` = 0.132307 WHERE `guid` = 38992 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9500.79, `position_y` = -0.34, `position_z` = 72.5583, `orientation` = 4.7088, `rotation2` = 0.708375, `rotation3` = -0.705837 WHERE `guid` = 38993 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9500.68, `position_y` = -27.52, `position_z` = 65.9921, `orientation` = 5.1626, `rotation2` = 0.531434, `rotation3` = -0.8471 WHERE `guid` = 38994 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9501.44, `position_y` = -20.28, `position_z` = 72.5328, `orientation` = 4.7262, `rotation2` = 0.702207, `rotation3` = -0.711973 WHERE `guid` = 38995 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9501.07, `position_y` = -10.3, `position_z` = 72.5697, `orientation` = 4.7612, `rotation2` = 0.689641, `rotation3` = -0.724152 WHERE `guid` = 38996 AND `id` = 180471;
UPDATE `gameobject` SET `position_x` = -9479.77, `position_y` = -44.26, `position_z` = 68.3207, `orientation` = 4.7612, `rotation2` = 0.689641, `rotation3` = -0.724152 WHERE `guid` = 39428 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9492.23, `position_y` = 4.5, `position_z` = 71.1019, `orientation` = 4.8833, `rotation2` = 0.644174, `rotation3` = -0.764879 WHERE `guid` = 39429 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9492.79, `position_y` = -26.5, `position_z` = 68.4426, `orientation` = 4.7961, `rotation2` = 0.6769, `rotation3` = -0.736075 WHERE `guid` = 39430 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9499.32, `position_y` = -2.27, `position_z` = 66.9817, `orientation` = 3.1903, `rotation2` = 0.999703, `rotation3` = -0.024351 WHERE `guid` = 39431 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9499.68, `position_y` = -17.94, `position_z` = 66.9625, `orientation` = 3.1555, `rotation2` = 0.999976, `rotation3` = -0.006954 WHERE `guid` = 39432 AND `id` = 180472;
UPDATE `gameobject` SET `position_x` = -9481.01, `position_y` = -43.3, `position_z` = 62.0397, `orientation` = 4.6739, `rotation2` = 0.720583, `rotation3` = -0.693369 WHERE `guid` = 40843 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -9473.16, `position_y` = -39.02, `position_z` = 62.0467, `orientation` = 0.0488, `rotation2` = 0.024398, `rotation3` = 0.999702 WHERE `guid` = 40844 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9479.82, `position_y` = -44.25, `position_z` = 66.983, `orientation` = 4.6564, `rotation2` = 0.726622, `rotation3` = -0.687037 WHERE `guid` = 40845 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9486.15, `position_y` = -9.83, `position_z` = 62.5621, `orientation` = 2.3351, `rotation2` = 0.919792, `rotation3` = 0.392406 WHERE `guid` = 40846 AND `id` = 180844;
UPDATE `gameobject` SET `position_x` = -9494.7, `position_y` = -24.89, `position_z` = 62.0813, `orientation` = 4.6913, `rotation2` = 0.714523, `rotation3` = -0.699612 WHERE `guid` = 40847 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9498.98, `position_y` = -10.35, `position_z` = 71.7806, `orientation` = 3.1903, `rotation2` = 0.999703, `rotation3` = -0.024351 WHERE `guid` = 40848 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9498.51, `position_y` = -1.63, `position_z` = 62.0954, `orientation` = 3.1031, `rotation2` = 0.999815, `rotation3` = 0.019245 WHERE `guid` = 40849 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -9499.19, `position_y` = -20.33, `position_z` = 71.8324, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 40850 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9488.51, `position_y` = -34.57, `position_z` = 62.0185, `orientation` = 3.1205, `rotation2` = 0.999944, `rotation3` = 0.010546 WHERE `guid` = 40851 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -9490.35, `position_y` = 5.25, `position_z` = 62.0731, `orientation` = 1.5323, `rotation2` = 0.693366, `rotation3` = 0.720585 WHERE `guid` = 40852 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -9488.38, `position_y` = -27.4, `position_z` = 62.0532, `orientation` = 3.1031, `rotation2` = 0.999815, `rotation3` = 0.019245 WHERE `guid` = 40853 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9492.79, `position_y` = -26.51, `position_z` = 66.9765, `orientation` = 4.6913, `rotation2` = 0.714523, `rotation3` = -0.699612 WHERE `guid` = 40854 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9498.88, `position_y` = -20.58, `position_z` = 62.2065, `orientation` = 3.0682, `rotation2` = 0.999327, `rotation3` = 0.036688 WHERE `guid` = 40856 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9498.76, `position_y` = -0.39, `position_z` = 71.8364, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 40857 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9492.01, `position_y` = 8.33, `position_z` = 72.5629, `orientation` = 1.5497, `rotation2` = 0.699609, `rotation3` = 0.714526 WHERE `guid` = 40858 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9490.89, `position_y` = -24.95, `position_z` = 62.0603, `orientation` = 4.6739, `rotation2` = 0.720583, `rotation3` = -0.693369 WHERE `guid` = 40859 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9498.74, `position_y` = -12.95, `position_z` = 62.0745, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 40861 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -9476.45, `position_y` = -9.86, `position_z` = 61.0303, `orientation` = 2.9809, `rotation2` = 0.996774, `rotation3` = 0.08026 WHERE `guid` = 40863 AND `id` = 178436;
UPDATE `gameobject` SET `position_x` = -9476.61, `position_y` = -14.36, `position_z` = 61.0872, `orientation` = 2.6318, `rotation2` = 0.967689, `rotation3` = 0.252145 WHERE `guid` = 40868 AND `id` = 178434;
UPDATE `gameobject` SET `position_x` = -9472.88, `position_y` = 0.09, `position_z` = 62.0325, `orientation` = 6.2796, `rotation2` = 0.001793, `rotation3` = -0.999998 WHERE `guid` = 40871 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9476.43, `position_y` = -8.81, `position_z` = 61.0444, `orientation` = 3.1555, `rotation2` = 0.999976, `rotation3` = -0.006954 WHERE `guid` = 40872 AND `id` = 178434;
UPDATE `gameobject` SET `position_x` = -9476.43, `position_y` = -6.82, `position_z` = 61.0356, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 40873 AND `id` = 178435;
UPDATE `gameobject` SET `position_x` = -9472.57, `position_y` = -2.32, `position_z` = 67.2082, `orientation` = 0.0139, `rotation2` = 0.00695, `rotation3` = 0.999976 WHERE `guid` = 40874 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9476.38, `position_y` = -7.74, `position_z` = 61.0227, `orientation` = 3.0158, `rotation2` = 0.998023, `rotation3` = 0.062855 WHERE `guid` = 40875 AND `id` = 178436;
UPDATE `gameobject` SET `position_x` = -9476.48, `position_y` = 7.57, `position_z` = 60.6918, `orientation` = 6.2447, `rotation2` = 0.019241, `rotation3` = -0.999815 WHERE `guid` = 40876 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9473.42, `position_y` = -20.6, `position_z` = 62.1921, `orientation` = 6.2621, `rotation2` = 0.010542, `rotation3` = -0.999944 WHERE `guid` = 40880 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -9483.62, `position_y` = 7.47, `position_z` = 60.776, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 40886 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9473.06, `position_y` = -3.92, `position_z` = 62.0117, `orientation` = 6.2621, `rotation2` = 0.010542, `rotation3` = -0.999944 WHERE `guid` = 40888 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9476.58, `position_y` = -12.31, `position_z` = 61.1023, `orientation` = 3.0682, `rotation2` = 0.999327, `rotation3` = 0.036688 WHERE `guid` = 40891 AND `id` = 178434;
UPDATE `gameobject` SET `position_x` = -9473.25, `position_y` = -31.8, `position_z` = 61.9979, `orientation` = 0.0139, `rotation2` = 0.00695, `rotation3` = 0.999976 WHERE `guid` = 40892 AND `id` = 178645;
UPDATE `gameobject` SET `position_x` = -9480.11, `position_y` = 10.68, `position_z` = 61.924, `orientation` = 1.5672, `rotation2` = 0.705834, `rotation3` = 0.708377 WHERE `guid` = 40896 AND `id` = 178438;
UPDATE `gameobject` SET `position_x` = -9476.56, `position_y` = -11.07, `position_z` = 61.0893, `orientation` = 3.0158, `rotation2` = 0.998023, `rotation3` = 0.062855 WHERE `guid` = 40897 AND `id` = 178435;
UPDATE `gameobject` SET `position_x` = -9476.61, `position_y` = -13.3, `position_z` = 61.1104, `orientation` = 2.9286, `rotation2` = 0.994335, `rotation3` = 0.106295 WHERE `guid` = 40898 AND `id` = 178436;
UPDATE `gameobject` SET `position_x` = -9485.42, `position_y` = 1.99, `position_z` = 61.5535, `orientation` = 2.562, `rotation2` = 0.958302, `rotation3` = 0.285757 WHERE `guid` = 40899 AND `id` = 178554;
UPDATE `gameobject` SET `position_x` = -9492.04, `position_y` = 6.75, `position_z` = 66.6165, `orientation` = 1.5672, `rotation2` = 0.705834, `rotation3` = 0.708377 WHERE `guid` = 41655 AND `id` = 178437;
UPDATE `gameobject` SET `position_x` = -9472.74, `position_y` = -18.66, `position_z` = 67.1856, `orientation` = 3.1729, `rotation2` = 0.999877, `rotation3` = -0.015653 WHERE `guid` = 41802 AND `id` = 178551;
UPDATE `gameobject` SET `position_x` = -9475.42, `position_y` = -23.15, `position_z` = 58.1197, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 52634 AND `id` = 181388;
UPDATE `gameobject` SET `position_x` = -9477.44, `position_y` = -15.49, `position_z` = 57.4722, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 52683 AND `id` = 181388;
UPDATE `gameobject` SET `position_x` = -9477.53, `position_y` = -13.33, `position_z` = 57.522, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 52684 AND `id` = 181388;
UPDATE `gameobject` SET `position_x` = -9477.48, `position_y` = -7.79, `position_z` = 57.5196, `orientation` = 3.1729, `rotation2` = 0.999877, `rotation3` = -0.015653 WHERE `guid` = 52735 AND `id` = 181388;
UPDATE `gameobject` SET `position_x` = -9477.22, `position_y` = -5.41, `position_z` = 57.4864, `orientation` = 3.2427, `rotation2` = 0.998722, `rotation3` = -0.050532 WHERE `guid` = 52754 AND `id` = 181388;
UPDATE `gameobject` SET `position_x` = -9499.19, `position_y` = -15.61, `position_z` = 60.0708, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 52939 AND `id` = 181390;
UPDATE `gameobject` SET `position_x` = -9492.09, `position_y` = 5.52, `position_z` = 59.861, `orientation` = 1.5847, `rotation2` = 0.712005, `rotation3` = 0.702174 WHERE `guid` = 52989 AND `id` = 181390;
UPDATE `gameobject` SET `position_x` = -9498.96, `position_y` = -4.18, `position_z` = 59.9563, `orientation` = 3.1729, `rotation2` = 0.999877, `rotation3` = -0.015653 WHERE `guid` = 52990 AND `id` = 181390;
UPDATE `gameobject` SET `position_x` = -9472.88, `position_y` = -2.27, `position_z` = 59.9894, `orientation` = 6.2447, `rotation2` = 0.019241, `rotation3` = -0.999815 WHERE `guid` = 53023 AND `id` = 181390;
UPDATE `gameobject` SET `position_x` = -9473.22, `position_y` = -18.94, `position_z` = 60.0177, `orientation` = 0.0139, `rotation2` = 0.00695, `rotation3` = 0.999976 WHERE `guid` = 53024 AND `id` = 181390;
UPDATE `gameobject` SET `position_x` = -9477.12, `position_y` = -14.35, `position_z` = 57.4694, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 53142 AND `id` = 181391;
UPDATE `gameobject` SET `position_x` = -9476.87, `position_y` = -6.53, `position_z` = 57.453, `orientation` = 3.0682, `rotation2` = 0.999327, `rotation3` = 0.036688 WHERE `guid` = 53147 AND `id` = 181391;
UPDATE `gameobject` SET `position_x` = -9488.45, `position_y` = -4.5, `position_z` = 58.1837, `orientation` = 1.5497, `rotation2` = 0.699609, `rotation3` = 0.714526 WHERE `guid` = 53251 AND `id` = 181391;
UPDATE `gameobject` SET `position_x` = -9483.07, `position_y` = -22.94, `position_z` = 58.128, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 53252 AND `id` = 181391;
UPDATE `gameobject` SET `position_x` = -9488.69, `position_y` = -15.84, `position_z` = 58.1873, `orientation` = 1.5148, `rotation2` = 0.687035, `rotation3` = 0.726625 WHERE `guid` = 53253 AND `id` = 181391;
UPDATE `gameobject` SET `position_x` = -9485.08, `position_y` = -15.91, `position_z` = 58.2021, `orientation` = 1.5323, `rotation2` = 0.693366, `rotation3` = 0.720585 WHERE `guid` = 53365 AND `id` = 181391;
UPDATE `gameobject` SET `position_x` = -9484.81, `position_y` = -4.61, `position_z` = 58.1569, `orientation` = 1.5497, `rotation2` = 0.699609, `rotation3` = 0.714526 WHERE `guid` = 53366 AND `id` = 181391;
UPDATE `gameobject` SET `position_x` = -9480.11, `position_y` = 10.19, `position_z` = 61.1232, `orientation` = 1.5148, `rotation2` = 0.687035, `rotation3` = 0.726625 WHERE `guid` = 53612 AND `id` = 181392;
UPDATE `gameobject` SET `position_x` = -9500.62, `position_y` = -10.11, `position_z` = 66.6079, `orientation` = 3.1205, `rotation2` = 0.999944, `rotation3` = 0.010546 WHERE `guid` = 54096 AND `id` = 181401;
UPDATE `gameobject` SET `position_x` = -9492.14, `position_y` = 6.77, `position_z` = 68.3571, `orientation` = 1.5847, `rotation2` = 0.712005, `rotation3` = 0.702174 WHERE `guid` = 54214 AND `id` = 181401;
UPDATE `gameobject` SET `position_x` = -9470.26, `position_y` = -10.7, `position_z` = 72.5988, `orientation` = 6.2621, `rotation2` = 0.010542, `rotation3` = -0.999944 WHERE `guid` = 54235 AND `id` = 181401;
UPDATE `gameobject` SET `position_x` = -9497.5, `position_y` = -3.79, `position_z` = 59.23, `orientation` = 6.2272, `rotation2` = 0.027989, `rotation3` = -0.999608 WHERE `guid` = 54862 AND `id` = 187576;
UPDATE `gameobject` SET `position_x` = -9483.78, `position_y` = -0.67, `position_z` = 58.7647, `orientation` = 4.6564, `rotation2` = 0.726622, `rotation3` = -0.687037 WHERE `guid` = 54863 AND `id` = 187576;
UPDATE `gameobject` SET `position_x` = -9493.15, `position_y` = -23.97, `position_z` = 62.0472, `orientation` = 1.5497, `rotation2` = 0.699609, `rotation3` = 0.714526 WHERE `guid` = 54879 AND `id` = 187576;
UPDATE `gameobject` SET `position_x` = -9492.14, `position_y` = 6.77, `position_z` = 68.3571, `orientation` = 1.5847, `rotation2` = 0.712005, `rotation3` = 0.702174 WHERE `guid` = 66973 AND `id` = 195253;
UPDATE `gameobject` SET `position_x` = -9500.62, `position_y` = -10.11, `position_z` = 66.6079, `orientation` = 3.1205, `rotation2` = 0.999944, `rotation3` = 0.010546 WHERE `guid` = 66974 AND `id` = 195253;
UPDATE `gameobject` SET `position_x` = -9470.26, `position_y` = -10.7, `position_z` = 72.5988, `orientation` = 6.2621, `rotation2` = 0.010542, `rotation3` = -0.999944 WHERE `guid` = 67002 AND `id` = 195253;
UPDATE `gameobject` SET `position_x` = -9472.48, `position_y` = -19.16, `position_z` = 58.0485, `orientation` = 1.9512, `rotation2` = 0.828038, `rotation3` = 0.560671 WHERE `guid` = 68029 AND `id` = 180405;
UPDATE `gameobject` SET `position_x` = -9481.38, `position_y` = -10.09, `position_z` = 56.9876, `orientation` = 5.0753, `rotation2` = 0.567892, `rotation3` = -0.823103 WHERE `guid` = 68031 AND `id` = 180405;
UPDATE `gameobject` SET `position_x` = -9476.87, `position_y` = -2.96, `position_z` = 56.9661, `orientation` = 5.0753, `rotation2` = 0.567892, `rotation3` = -0.823103 WHERE `guid` = 68339 AND `id` = 180406;
UPDATE `gameobject` SET `position_x` = -9472.43, `position_y` = -2.06, `position_z` = 58.44, `orientation` = 1.9686, `rotation2` = 0.832885, `rotation3` = 0.553446 WHERE `guid` = 68645 AND `id` = 180407;
UPDATE `gameobject` SET `position_x` = -9476.12, `position_y` = -7.22, `position_z` = 64.8899, `orientation` = 5.372, `rotation2` = 0.439995, `rotation3` = -0.898 WHERE `guid` = 69157 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9476.11, `position_y` = -7.62, `position_z` = 64.7927, `orientation` = 0.2058, `rotation2` = 0.102719, `rotation3` = 0.99471 WHERE `guid` = 69158 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9477.18, `position_y` = -6.23, `position_z` = 57.4448, `orientation` = 1.1134, `rotation2` = 0.528387, `rotation3` = 0.849003 WHERE `guid` = 69159 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9477.31, `position_y` = -7.13, `position_z` = 57.483, `orientation` = 2.1432, `rotation2` = 0.877968, `rotation3` = 0.47872 WHERE `guid` = 69160 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9477.49, `position_y` = -13.96, `position_z` = 57.4896, `orientation` = 3.8187, `rotation2` = 0.943236, `rotation3` = -0.332123 WHERE `guid` = 69161 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9477.43, `position_y` = -14.95, `position_z` = 57.4559, `orientation` = 1.9512, `rotation2` = 0.828038, `rotation3` = 0.560671 WHERE `guid` = 69162 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9478.85, `position_y` = -16.68, `position_z` = 64.7927, `orientation` = 3.8012, `rotation2` = 0.946106, `rotation3` = -0.323857 WHERE `guid` = 69163 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9479.88, `position_y` = -17.54, `position_z` = 64.8969, `orientation` = 5.6513, `rotation2` = 0.310713, `rotation3` = -0.950504 WHERE `guid` = 69164 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9481.8, `position_y` = -7.95, `position_z` = 57.0363, `orientation` = 2.6668, `rotation2` = 0.971954, `rotation3` = 0.235173 WHERE `guid` = 69165 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9486.02, `position_y` = 2.33, `position_z` = 64.6538, `orientation` = 6.0702, `rotation2` = 0.106291, `rotation3` = -0.994335 WHERE `guid` = 69166 AND `id` = 180415;
UPDATE `gameobject` SET `position_x` = -9483.78, `position_y` = -0.67, `position_z` = 58.7647, `orientation` = 4.6564, `rotation2` = 0.726622, `rotation3` = -0.687037 WHERE `guid` = 80366 AND `id` = 195259;
UPDATE `gameobject` SET `position_x` = -9497.5, `position_y` = -3.79, `position_z` = 59.23, `orientation` = 6.2272, `rotation2` = 0.027989, `rotation3` = -0.999608 WHERE `guid` = 80367 AND `id` = 195259;
UPDATE `gameobject` SET `position_x` = -9493.15, `position_y` = -23.97, `position_z` = 62.0472, `orientation` = 1.5497, `rotation2` = 0.699609, `rotation3` = 0.714526 WHERE `guid` = 80378 AND `id` = 195259;
UPDATE `gameobject` SET `position_x` = -9477.12, `position_y` = -14.35, `position_z` = 57.4694, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 80456 AND `id` = 195260;
UPDATE `gameobject` SET `position_x` = -9476.87, `position_y` = -6.53, `position_z` = 57.453, `orientation` = 3.0682, `rotation2` = 0.999327, `rotation3` = 0.036688 WHERE `guid` = 80457 AND `id` = 195260;
UPDATE `gameobject` SET `position_x` = -9484.81, `position_y` = -4.61, `position_z` = 58.1569, `orientation` = 1.5497, `rotation2` = 0.699609, `rotation3` = 0.714526 WHERE `guid` = 80458 AND `id` = 195260;
UPDATE `gameobject` SET `position_x` = -9488.69, `position_y` = -15.84, `position_z` = 58.1873, `orientation` = 1.5148, `rotation2` = 0.687035, `rotation3` = 0.726625 WHERE `guid` = 80459 AND `id` = 195260;
UPDATE `gameobject` SET `position_x` = -9485.08, `position_y` = -15.91, `position_z` = 58.2021, `orientation` = 1.5323, `rotation2` = 0.693366, `rotation3` = 0.720585 WHERE `guid` = 80460 AND `id` = 195260;
UPDATE `gameobject` SET `position_x` = -9483.07, `position_y` = -22.94, `position_z` = 58.128, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 80487 AND `id` = 195260;
UPDATE `gameobject` SET `position_x` = -9488.45, `position_y` = -4.5, `position_z` = 58.1837, `orientation` = 1.5497, `rotation2` = 0.699609, `rotation3` = 0.714526 WHERE `guid` = 80508 AND `id` = 195260;
UPDATE `gameobject` SET `position_x` = -9472.88, `position_y` = -2.27, `position_z` = 59.9894, `orientation` = 6.2447, `rotation2` = 0.019241, `rotation3` = -0.999815 WHERE `guid` = 80623 AND `id` = 195263;
UPDATE `gameobject` SET `position_x` = -9492.09, `position_y` = 5.52, `position_z` = 59.861, `orientation` = 1.5847, `rotation2` = 0.712005, `rotation3` = 0.702174 WHERE `guid` = 80633 AND `id` = 195263;
UPDATE `gameobject` SET `position_x` = -9473.22, `position_y` = -18.94, `position_z` = 60.0177, `orientation` = 0.0139, `rotation2` = 0.00695, `rotation3` = 0.999976 WHERE `guid` = 80634 AND `id` = 195263;
UPDATE `gameobject` SET `position_x` = -9499.19, `position_y` = -15.61, `position_z` = 60.0708, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 80640 AND `id` = 195263;
UPDATE `gameobject` SET `position_x` = -9498.96, `position_y` = -4.18, `position_z` = 59.9563, `orientation` = 3.1729, `rotation2` = 0.999877, `rotation3` = -0.015653 WHERE `guid` = 80641 AND `id` = 195263;
UPDATE `gameobject` SET `position_x` = -9477.22, `position_y` = -5.41, `position_z` = 57.4864, `orientation` = 3.2427, `rotation2` = 0.998722, `rotation3` = -0.050532 WHERE `guid` = 80669 AND `id` = 195264;
UPDATE `gameobject` SET `position_x` = -9477.44, `position_y` = -15.49, `position_z` = 57.4722, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 80670 AND `id` = 195264;
UPDATE `gameobject` SET `position_x` = -9475.42, `position_y` = -23.15, `position_z` = 58.1197, `orientation` = 3.0856, `rotation2` = 0.999608, `rotation3` = 0.027993 WHERE `guid` = 80671 AND `id` = 195264;
UPDATE `gameobject` SET `position_x` = -9477.53, `position_y` = -13.33, `position_z` = 57.522, `orientation` = 3.138, `rotation2` = 0.999998, `rotation3` = 0.001796 WHERE `guid` = 80679 AND `id` = 195264;
UPDATE `gameobject` SET `position_x` = -9477.48, `position_y` = -7.79, `position_z` = 57.5196, `orientation` = 3.1729, `rotation2` = 0.999877, `rotation3` = -0.015653 WHERE `guid` = 80680 AND `id` = 195264;
UPDATE `gameobject` SET `position_x` = -9480.11, `position_y` = 10.19, `position_z` = 61.1232, `orientation` = 1.5148, `rotation2` = 0.687035, `rotation3` = 0.726625 WHERE `guid` = 80873 AND `id` = 195266;
UPDATE `gameobject` SET `position_x` = -9482.97, `position_y` = -17.17, `position_z` = 56.9626, `orientation` = 5.4942, `rotation2` = 0.38434, `rotation3` = -0.923192 WHERE `guid` = 81108 AND `id` = 189303;
UPDATE `gameobject` SET `position_x` = -9477.99, `position_y` = -19.27, `position_z` = 57.5529, `orientation` = 5.0928, `rotation2` = 0.560668, `rotation3` = -0.82804 WHERE `guid` = 81121 AND `id` = 180523;
UPDATE `gameobject` SET `position_x` = -9491.9, `position_y` = 7.84, `position_z` = 56.5597, `orientation` = 1.6078, `rotation2` = 0.720068, `rotation3` = 0.693904 WHERE `guid` = 151923 AND `id` = 113770;
UPDATE `gameobject` SET `position_x` = -9475.8, `position_y` = 5.08, `position_z` = 56.6227, `orientation` = 4.1407, `rotation2` = 0.877796, `rotation3` = -0.479034 WHERE `guid` = 151929 AND `id` = 113771;
UPDATE `gameobject` SET `position_x` = -9472.24, `position_y` = -6.15, `position_z` = 56.5301, `orientation` = 3.0844, `rotation2` = 0.999591, `rotation3` = 0.028592 WHERE `guid` = 151930 AND `id` = 113772;
UPDATE `gameobject` SET `position_x` = -9472.9, `position_y` = -15.88, `position_z` = 58.0491, `orientation` = 2.3657, `rotation2` = 0.925688, `rotation3` = 0.378288 WHERE `guid` = 151932 AND `id` = 113769;
UPDATE `gameobject` SET `position_x` = -9486.21, `position_y` = -44.79, `position_z` = 56.92, `orientation` = 1.8238, `rotation2` = 0.790668, `rotation3` = 0.612245 WHERE `guid` = 151933 AND `id` = 113770;
UPDATE `gameobject` SET `position_x` = -9494.21, `position_y` = -28.68, `position_z` = 56.7995, `orientation` = 0.253, `rotation2` = 0.126163, `rotation3` = 0.99201 WHERE `guid` = 151934 AND `id` = 113771;
UPDATE `gameobject` SET `position_x` = -9497.95, `position_y` = 3.33, `position_z` = 57.4807, `orientation` = 0.418, `rotation2` = 0.207482, `rotation3` = 0.978239 WHERE `guid` = 151936 AND `id` = 113768;
UPDATE `gameobject` SET `position_x` = -9487.48, `position_y` = -35.6, `position_z` = 58.308, `orientation` = 1.6881, `rotation2` = 0.74734, `rotation3` = 0.664442 WHERE `guid` = 6901118 AND `id` = 95687;

-- ---------------------------------------------------------------------------
-- 3. Quest givers at their CoA turn-in points
-- ---------------------------------------------------------------------------
-- Marshal Dughan (80334): turn-in point of 39, 40, 54, 62, 76, 123, 147 and 176; market plaza by the signpost,
--   facing the road junction
UPDATE `creature` SET `position_x` = -9461.8, `position_y` = 44.434, `position_z` = 56.526, `orientation` = 0.9 WHERE `guid` = 80334 AND `id` = 240;
-- Merissa Stilwell (79949): turn-in point of 5805 (stock spawn is in Northshire; the Exiles site also lists her in
--   Goldshire); outside the moved inn's west side, facing the market
UPDATE `creature` SET `position_x` = -9496.06, `position_y` = 14.682, `position_z` = 56.695, `orientation` = 0.53 WHERE `guid` = 79949 AND `id` = 11940;
-- Elwynn Forest Flame Warden (245655): turn-in point of 11816; north-west corner of the market plaza, facing the
--   plaza
UPDATE `creature` SET `position_x` = -9448.86, `position_y` = 51.965, `position_z` = 56.799, `orientation` = 3.95 WHERE `guid` = 245655 AND `id` = 25898;
-- Spring Collector (244815): turn-in point of 13480 and 13484; north-west corner of the market plaza beside the
--   Flame Warden, facing the plaza
UPDATE `creature` SET `position_x` = -9453.86, `position_y` = 44.74, `position_z` = 57.041, `orientation` = 3.88 WHERE `guid` = 244815 AND `id` = 32799;
-- Morja (56324): turn-in point of 7946; faire ground south of the town hall, facing the hall
UPDATE `creature` SET `position_x` = -9593.82, `position_y` = 48.035, `position_z` = 59.666, `orientation` = 0 WHERE `guid` = 56324 AND `id` = 14871;
-- Elder Stormbrow (70557): turn-in point of 8649; facing the village
UPDATE `creature` SET `position_x` = -9391.43, `position_y` = 142.467, `position_z` = 61.14, `orientation` = 4.11 WHERE `guid` = 70557 AND `id` = 15565;
-- Marshal McBride (79970): turn-in point of 7, 15, 21 and 783 (-8909.23, -131.39), 1.8 yd west of it, clear of the
--   Northshire mailbox 6901512; outside the abbey front, facing the human start point
UPDATE `creature` SET `position_x` = -8909.6, `position_y` = -129.6, `position_z` = 80.95, `orientation` = 3.17 WHERE `guid` = 79970 AND `id` = 197;
-- Brother Neals (79968): turn-in point of 3905; same abbey upper floor as the stock spawn, stock facing
UPDATE `creature` SET `position_x` = -8892.94, `position_y` = -172.944, `position_z` = 113.158, `orientation` = 0.87 WHERE `guid` = 79968 AND `id` = 952;

-- ---------------------------------------------------------------------------
-- 4. Stock spawns out of new walls, floors and ground
-- ---------------------------------------------------------------------------
-- Young Wolf (79648): wolf too close to the Stormwind/Northshire road fork (playtest); 45+ yd from both roads in
--   the woods
UPDATE `creature` SET `position_x` = -9414.8, `position_y` = 139.9, `position_z` = 58.46, `orientation` = 3.16 WHERE `guid` = 79648 AND `id` = 299;
-- Young Wolf (80341): wolf too close to the Stormwind/Northshire road fork (playtest); 45+ yd from both roads in
--   the woods
UPDATE `creature` SET `position_x` = -9312, `position_y` = 77.6, `position_z` = 68.11, `orientation` = 4.11 WHERE `guid` = 80341 AND `id` = 299;
-- Mangy Wolf (80342): wolf too close to the Stormwind/Northshire road fork (playtest); 45+ yd from both roads in
--   the woods
UPDATE `creature` SET `position_x` = -9323.6, `position_y` = 79, `position_z` = 61.58, `orientation` = 2.74 WHERE `guid` = 80342 AND `id` = 525;
-- Young Wolf (79920): wolf too close to the Stormwind/Northshire road fork (playtest); 45+ yd from both roads in
--   the woods
UPDATE `creature` SET `position_x` = -9265.9, `position_y` = -3.8, `position_z` = 73.34, `orientation` = 5.7 WHERE `guid` = 79920 AND `id` = 299;
-- Young Wolf (80343): wolf too close to Goldshire's north edge by the Northshire/Stormwind fork (playtest); 55+ yd
--   out in the woods
UPDATE `creature` SET `position_x` = -9336.3, `position_y` = 69.8, `position_z` = 60.76, `orientation` = 2.97 WHERE `guid` = 80343 AND `id` = 299;
-- Mangy Wolf (80351): wolf too close to Goldshire's north edge by the Northshire/Stormwind fork (playtest); 55+ yd
--   out in the woods
UPDATE `creature` SET `position_x` = -9334.5, `position_y` = 48, `position_z` = 59.86, `orientation` = 4.33 WHERE `guid` = 80351 AND `id` = 525;
-- Kobold Worker (80105): kobold worker off the roof of the Old Northshire ruins (playtest); kobold camp, 32+ yd
--   from the village
UPDATE `creature` SET `position_x` = -8779, `position_y` = -244.5, `position_z` = 83.32, `orientation` = 1.05 WHERE `guid` = 80105 AND `id` = 257;
-- Kobold Worker (80107): kobold worker that wandered onto the Old Northshire ruins (playtest); kobold camp, 32+ yd
--   from the village
UPDATE `creature` SET `position_x` = -8768.5, `position_y` = -244.5, `position_z` = 83.51, `orientation` = 2.59 WHERE `guid` = 80107 AND `id` = 257;
-- Kobold Vermin (80100): kobold crowding the Old Northshire village (playtest); kobold camp, 32+ yd from its
--   ruined buildings
UPDATE `creature` SET `position_x` = -8774.4, `position_y` = -247.8, `position_z` = 82.93, `orientation` = 3.87 WHERE `guid` = 80100 AND `id` = 6;
-- Kobold Worker (80103): kobold crowding the Old Northshire village (playtest); kobold camp, 32+ yd from its
--   ruined buildings
UPDATE `creature` SET `position_x` = -8781.8, `position_y` = -240.3, `position_z` = 83.68, `orientation` = 1.81 WHERE `guid` = 80103 AND `id` = 257;
-- Kobold Vermin (80116): kobold crowding the Old Northshire village (playtest); kobold camp, 32+ yd from its
--   ruined buildings
UPDATE `creature` SET `position_x` = -8790.9, `position_y` = -247.1, `position_z` = 82.63, `orientation` = 2.71 WHERE `guid` = 80116 AND `id` = 6;
-- Kobold Worker (80117): kobold crowding the Old Northshire village (playtest); kobold camp, 32+ yd from its
--   ruined buildings
UPDATE `creature` SET `position_x` = -8788.4, `position_y` = -241.8, `position_z` = 82.97, `orientation` = 2.23 WHERE `guid` = 80117 AND `id` = 257;
-- Kobold Worker (80121): kobold crowding the Old Northshire village (playtest); kobold camp, 32+ yd from its
--   ruined buildings
UPDATE `creature` SET `position_x` = -8819.6, `position_y` = -240.9, `position_z` = 82.22, `orientation` = 0.52 WHERE `guid` = 80121 AND `id` = 257;
-- Kobold Worker (80122): kobold crowding the Old Northshire village (playtest); kobold camp, 32+ yd from its
--   ruined buildings
UPDATE `creature` SET `position_x` = -8818, `position_y` = -245.7, `position_z` = 82.38, `orientation` = 3.19 WHERE `guid` = 80122 AND `id` = 257;
-- Timber Wolf (80106): timber wolf out of the ruined farmhouse of Old Northshire (playtest); open woods south of
--   it
UPDATE `creature` SET `position_x` = -8745, `position_y` = -322, `position_z` = 82.39, `orientation` = 5.62 WHERE `guid` = 80106 AND `id` = 69;
-- Defias Bandit (80381): Mirror Lake camp bandit out of the Spada manor house; Mirror Lake Orchard (quest 17008:
--   'The Defias have overrun the Mirror Lake Orchard'), below the farmhouse's south wall facing the orchard
UPDATE `creature` SET `position_x` = -9455.5, `position_y` = 463, `position_z` = 53.13, `orientation` = 3.14 WHERE `guid` = 80381 AND `id` = 116;
-- Defias Bandit (80385): Mirror Lake camp bandit out of the walled manor grounds; Mirror Lake Orchard, between the
--   west tree rows
UPDATE `creature` SET `position_x` = -9466, `position_y` = 481, `position_z` = 53.06, `orientation` = 3.8 WHERE `guid` = 80385 AND `id` = 116;
-- Defias Bandit (80387): Mirror Lake camp bandit out of the walled manor grounds; Mirror Lake Orchard, east tree
--   rows by the fence
UPDATE `creature` SET `position_x` = -9475, `position_y` = 456, `position_z` = 51.82, `orientation` = 2.5 WHERE `guid` = 80387 AND `id` = 116;
-- Thuros Lightfingers (134009): Thuros Lightfingers spawn point (pool 1002) out of the walled manor grounds;
--   Mirror Lake Orchard at the farmhouse's west corner
UPDATE `creature` SET `position_x` = -9448, `position_y` = 487.5, `position_z` = 53.42, `orientation` = 5.5 WHERE `guid` = 134009 AND `id` = 61;
-- Defias Bandit (80386): Mirror Lake camp bandit out from beside the manor's north-west wall (playtest: too close
--   to the manor); Mirror Lake Orchard, south tree rows
UPDATE `creature` SET `position_x` = -9452, `position_y` = 450, `position_z` = 52.85, `orientation` = 2.15 WHERE `guid` = 80386 AND `id` = 116;
-- Defias Bandit (80384): Mirror Lake camp bandit out from behind the manor's north wall (playtest: too close to
--   the manor); Mirror Lake Orchard, west edge
UPDATE `creature` SET `position_x` = -9480, `position_y` = 472, `position_z` = 51.66, `orientation` = 6.15 WHERE `guid` = 80384 AND `id` = 116;
-- Sheep (80290): sheep out of the space under the manor's ground floor; manor's south lawn
UPDATE `creature` SET `position_x` = -9308.5, `position_y` = 466, `position_z` = 78.48, `orientation` = 2.8 WHERE `guid` = 80290 AND `id` = 1933;
-- Forest Spider (80288): forest spider floating in the manor's east garden; on the ground a yard clear of the tree
--   trunk
UPDATE `creature` SET `position_x` = -9258, `position_y` = 447, `position_z` = 80.89, `orientation` = 5.12 WHERE `guid` = 80288 AND `id` = 30;
-- Defias Rogue Wizard (80383): Defias Rogue Wizard out of the Mirror Lake slope below the manor (playtest: too
--   close to the manor, and stock spot inside a tree trunk); Mirror Lake Orchard, north-west corner
UPDATE `creature` SET `position_x` = -9485, `position_y` = 486, `position_z` = 51.73, `orientation` = 5.61 WHERE `guid` = 80383 AND `id` = 474;
-- Defias Rogue Wizard (80412): Defias Rogue Wizard out from under the manor by the falls (playtest: too close to
--   the manor); Mirror Lake Orchard, south edge
UPDATE `creature` SET `position_x` = -9468, `position_y` = 446, `position_z` = 53.29, `orientation` = 1.45 WHERE `guid` = 80412 AND `id` = 474;
-- Deer (80356): deer against the moved inn's window planters; grass strip between the inn's north wall and the
--   orchard
UPDATE `creature` SET `position_x` = -9468.5, `position_y` = -25, `position_z` = 57.08, `orientation` = 5.97 WHERE `guid` = 80356 AND `id` = 883;
-- Fawn (80357): fawn on a window planter of the moved inn; beside deer 80356 on the grass strip north of the inn
UPDATE `creature` SET `position_x` = -9466.5, `position_y` = -27.5, `position_z` = 57.13, `orientation` = 3.9 WHERE `guid` = 80357 AND `id` = 890;
-- Deer (81090): deer inside the moved inn's gazebo garden; open grass east of the inn, south of its fountain
UPDATE `creature` SET `position_x` = -9492.5, `position_y` = -51, `position_z` = 57.09, `orientation` = 2 WHERE `guid` = 81090 AND `id` = 883;
-- Fawn (81091): fawn on the gazebo bench; beside deer 81090 east of the inn
UPDATE `creature` SET `position_x` = -9494, `position_y` = -53, `position_z` = 57.19, `orientation` = 1.2 WHERE `guid` = 81091 AND `id` = 890;
-- Chicken (80332): chicken inside a market water wagon; market edge east of the gypsy wagon
UPDATE `creature` SET `position_x` = -9459, `position_y` = 52.5, `position_z` = 56.58, `orientation` = 4.2 WHERE `guid` = 80332 AND `id` = 620;
-- Rabbit (80365): rabbit under the town hall dais; grass west of the town hall
UPDATE `creature` SET `position_x` = -9563.5, `position_y` = 78, `position_z` = 58.88, `orientation` = 2 WHERE `guid` = 80365 AND `id` = 721;
-- Rabbit (80132): rabbit against a new Old Northshire ruin wall; 3 yd clear of the wall
UPDATE `creature` SET `position_x` = -8797.5, `position_y` = -299, `position_z` = 73.67, `orientation` = 4.5 WHERE `guid` = 80132 AND `id` = 721;
-- Diseased Timber Wolf (80136): wolf on a CoA fence post; ground beside the fence
UPDATE `creature` SET `position_x` = -8838.5, `position_y` = -309, `position_z` = 73.48, `orientation` = 1.2 WHERE `guid` = 80136 AND `id` = 69;
-- Defias Thug (80257): Defias Thug inside a vineyard tree stump; ground 3.5 yd from the stump
UPDATE `creature` SET `position_x` = -8932.95, `position_y` = -358.02, `position_z` = 72.61, `orientation` = 2.2 WHERE `guid` = 80257 AND `id` = 38;
-- Deer (80063): deer inside a tree trunk in the new Redridge-style farm yard; open yard west of the tree
UPDATE `creature` SET `position_x` = -8690, `position_y` = -199.5, `position_z` = 91.69, `orientation` = 1 WHERE `guid` = 80063 AND `id` = 883;
-- Rabbit (80062): rabbit inside the new farmhouse; yard north of the farmhouse
UPDATE `creature` SET `position_x` = -8668, `position_y` = -192, `position_z` = 91.07, `orientation` = 3.3 WHERE `guid` = 80062 AND `id` = 721;
-- Defias Cutpurse (80377): Defias Cutpurse standing on a tree canopy 4 yd up; ground beside that tree
UPDATE `creature` SET `position_x` = -9492, `position_y` = 309.5, `position_z` = 52.24, `orientation` = 1.9 WHERE `guid` = 80377 AND `id` = 94;
-- Wild Turkey (241320): turkey inside the moved inn; grass between the inn and the orchard
UPDATE `creature` SET `position_x` = -9464, `position_y` = -35, `position_z` = 57.16, `orientation` = 0 WHERE `guid` = 241320 AND `id` = 32820;
-- Wild Turkey (241322): turkey inside the moved inn; grass east of the inn
UPDATE `creature` SET `position_x` = -9497, `position_y` = -49, `position_z` = 57.09, `orientation` = 0 WHERE `guid` = 241322 AND `id` = 32820;
-- Wild Turkey (241323): turkey inside the moved inn; grass east of the inn
UPDATE `creature` SET `position_x` = -9489, `position_y` = -54.5, `position_z` = 57.28, `orientation` = 0 WHERE `guid` = 241323 AND `id` = 32820;
-- Wild Turkey (241342): turkey under the moved inn's porch; grass north of the porch
UPDATE `creature` SET `position_x` = -9467, `position_y` = -19, `position_z` = 57.1, `orientation` = 0 WHERE `guid` = 241342 AND `id` = 32820;
-- Wild Turkey (241576): turkey inside the Spada manor house; manor's south lawn
UPDATE `creature` SET `position_x` = -9309.5, `position_y` = 476, `position_z` = 78.24, `orientation` = 0 WHERE `guid` = 241576 AND `id` = 32820;
-- Wild Turkey (241578): turkey inside the Spada manor house; manor's south lawn
UPDATE `creature` SET `position_x` = -9310, `position_y` = 457, `position_z` = 78.5, `orientation` = 0 WHERE `guid` = 241578 AND `id` = 32820;
-- Wild Turkey (241581): turkey under the Spada manor floor; manor's south lawn
UPDATE `creature` SET `position_x` = -9308.5, `position_y` = 449, `position_z` = 78.65, `orientation` = 0 WHERE `guid` = 241581 AND `id` = 32820;
-- Wild Turkey (241591): turkey inside the Spada manor house; manor's north lawn
UPDATE `creature` SET `position_x` = -9259.5, `position_y` = 478, `position_z` = 80.24, `orientation` = 0 WHERE `guid` = 241591 AND `id` = 32820;
-- Wild Turkey (241599): turkey inside the Spada manor house; manor's north lawn
UPDATE `creature` SET `position_x` = -9258.5, `position_y` = 470, `position_z` = 80.01, `orientation` = 0 WHERE `guid` = 241599 AND `id` = 32820;
-- Wild Turkey (241565): turkey inside the Spada manor house; manor's south lawn by the hedge
UPDATE `creature` SET `position_x` = -9308.5, `position_y` = 481, `position_z` = 78.07, `orientation` = 0 WHERE `guid` = 241565 AND `id` = 32820;
-- Wild Turkey (241934): turkey inside the new farm wall near Echo Ridge; open yard
UPDATE `creature` SET `position_x` = -8689, `position_y` = -187, `position_z` = 91.36, `orientation` = 0 WHERE `guid` = 241934 AND `id` = 32820;
-- Wild Turkey (241937): turkey against the new farm wall; open yard
UPDATE `creature` SET `position_x` = -8681, `position_y` = -196.5, `position_z` = 90.98, `orientation` = 0 WHERE `guid` = 241937 AND `id` = 32820;
-- Wild Turkey (244253): turkey inside the damaged guard tower wall; open ground west of the tower
UPDATE `creature` SET `position_x` = -8856, `position_y` = -371, `position_z` = 70.94, `orientation` = 0 WHERE `guid` = 244253 AND `id` = 32820;
-- Water Buckets (66928): Hallow's End water buckets inside a tree stump; 2 yd off the stump
UPDATE `gameobject` SET `position_x` = -9434, `position_y` = 60.5, `position_z` = 56.56, `orientation` = 4.31097 WHERE `guid` = 66928 AND `id` = 186615;
-- Brightly Colored Egg (151924): Noblegarden egg inside the smithy's new bellows; grass beside the bellows
UPDATE `gameobject` SET `position_x` = -9436, `position_y` = 110.5, `position_z` = 57.46, `orientation` = 4.86507 WHERE `guid` = 151924 AND `id` = 113771;
-- Brightly Colored Egg (151926): Noblegarden egg inside the new two-storey house wall; by the fence east of the
--   house
UPDATE `gameobject` SET `position_x` = -9427.5, `position_y` = 66.5, `position_z` = 56.91, `orientation` = 4.42918 WHERE `guid` = 151926 AND `id` = 113768;
-- Brightly Colored Egg (151937): Noblegarden egg under a market wagon; beside the wagon
UPDATE `gameobject` SET `position_x` = -9483, `position_y` = 49, `position_z` = 56.6, `orientation` = 0.242232 WHERE `guid` = 151937 AND `id` = 113769;
-- Brightly Colored Egg (151944): Noblegarden egg inside the new smithy wall; at the wall's foot
UPDATE `gameobject` SET `position_x` = -9471.5, `position_y` = 101, `position_z` = 57.92, `orientation` = 0.693849 WHERE `guid` = 151944 AND `id` = 113771;
-- Peacebloom (206537): Peacebloom inside a tree trunk at the Goldshire entrance; grass beside the tree
UPDATE `gameobject` SET `position_x` = -9412, `position_y` = -30.5, `position_z` = 63.33, `orientation` = 0.0698117 WHERE `guid` = 206537 AND `id` = 1618;
-- Silverleaf (206455): Silverleaf under the Spada manor house; wooded hillside above the manor's north lawn
UPDATE `gameobject` SET `position_x` = -9263, `position_y` = 500, `position_z` = 93.91, `orientation` = 0.122173 WHERE `guid` = 206455 AND `id` = 1617;
-- Earthroot (206618): Earthroot in a terrain crevice behind the manor wall tower; open slope 3 yd away
UPDATE `gameobject` SET `position_x` = -9289.5, `position_y` = 533, `position_z` = 89.7, `orientation` = 5.68977 WHERE `guid` = 206618 AND `id` = 1619;
-- Earthroot (206594): Earthroot 16 yd under the raised Bandit's Bastion hill; hilltop east of the camp palisade
UPDATE `gameobject` SET `position_x` = -9752, `position_y` = -466, `position_z` = 58.95, `orientation` = 1.5708 WHERE `guid` = 206594 AND `id` = 1619;
-- Copper Vein (206677): Copper Vein 17 yd under the raised Bandit's Bastion hill; against the hill rock east of
--   the palisade
UPDATE `gameobject` SET `position_x` = -9748, `position_y` = -462, `position_z` = 57.66, `orientation` = 5.70723 WHERE `guid` = 206677 AND `id` = 1731;
-- Copper Vein (206682): Copper Vein inside the Bandit's Bastion palisade posts; slope north-east of the palisade
UPDATE `gameobject` SET `position_x` = -9768, `position_y` = -414.5, `position_z` = 49.95, `orientation` = 3.47321 WHERE `guid` = 206682 AND `id` = 1731;
-- Servant of Azora (80924): servant on the 17002/17003 turn-in point, the post CoA gave Esyra; Tower of Azora
--   ground floor beside the water barrel, facing the reading table
UPDATE `creature` SET `position_x` = -9570.9, `position_y` = -719.2, `position_z` = 64.74, `orientation` = 0.02 WHERE `guid` = 80924 AND `id` = 1949;
-- Rockhide Boar (80812): boar against the farmhouse inside the Bandit's Bastion camp; open meadow south-east of
--   the camp, past its supply wagons
UPDATE `creature` SET `position_x` = -9812, `position_y` = -514, `position_z` = 30.28, `orientation` = 3.69274 WHERE `guid` = 80812 AND `id` = 524;
-- Rockhide Boar (80794): boar among the Defias at the Bandit's Bastion's south end; open slope east of the camp,
--   beyond the supply tent
UPDATE `creature` SET `position_x` = -9780, `position_y` = -522, `position_z` = 32.75, `orientation` = 5.83775 WHERE `guid` = 80794 AND `id` = 524;
-- Rockhide Boar (80796): boar against an oak trunk on a terrain step of the raised Bastion hill; 1.5 yd off the
--   trunk on level ground
UPDATE `creature` SET `position_x` = -9706.5, `position_y` = -450, `position_z` = 51.89, `orientation` = 2.7737 WHERE `guid` = 80796 AND `id` = 524;
-- Mailbox (26784): Lion's Pride Inn mailbox; the inn's move would put it inside CoA's entrance barrels, so it
--   stands 2 yd north-west of them at the moved front door, keeping its stock facing turned with the inn
UPDATE `gameobject` SET `position_x` = -9474.5, `position_y` = 14, `position_z` = 56.574, `orientation` = 1.506, `rotation2` = 0.683831, `rotation3` = 0.729641 WHERE `guid` = 26784 AND `id` = 142075;
-- Rabbit (79644): Goldshire: CoA lowered the ground 2.18 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9455.02, `position_y` = -29.2894, `position_z` = 57.33, `orientation` = 3.34436 WHERE `guid` = 79644 AND `id` = 721;
-- Mangy Wolf (79876): around the Spada manor: CoA lowered the ground 1.78 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9224.23, `position_y` = 418.613, `position_z` = 86.33, `orientation` = 0.047608 WHERE `guid` = 79876 AND `id` = 525;
-- Mangy Wolf (80382): around the Spada manor: CoA lowered the ground 3.17 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9239.91, `position_y` = 421.35, `position_z` = 84.03, `orientation` = 0.125324 WHERE `guid` = 80382 AND `id` = 525;
-- Diseased Timber Wolf (80131): Northshire: CoA lowered the ground 3.29 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -8827.58, `position_y` = -292.02, `position_z` = 76.07, `orientation` = 0.334482 WHERE `guid` = 80131 AND `id` = 69;
-- Diseased Timber Wolf (80144): Northshire: CoA raised the ground 0.41 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -8937.8, `position_y` = -259.455, `position_z` = 77.46, `orientation` = 0.676014 WHERE `guid` = 80144 AND `id` = 69;
-- Eagan Peltskinner (79971): Northshire Abbey yard: 0.77 yd above the ground, as in stock; onto the ground
UPDATE `creature` SET `position_x` = -8869.22, `position_y` = -163.237, `position_z` = 80.21, `orientation` = 0.959931 WHERE `guid` = 79971 AND `id` = 196;
-- Stonetusk Boar (80361): Goldshire refugee camp: CoA lowered the ground 0.60 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9545.4, `position_y` = 4.4072, `position_z` = 60.05, `orientation` = 5.20721 WHERE `guid` = 80361 AND `id` = 113;
-- Peacebloom (206542): Goldshire refugee camp: CoA lowered the ground 0.65 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9582.88, `position_y` = 16.6436, `position_z` = 59.46, `orientation` = 3.47321 WHERE `guid` = 206542 AND `id` = 1618;
-- Water Barrel (32313): Goldshire, south of the melon plot: CoA lowered the ground 0.53 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9500.53, `position_y` = 81.368, `position_z` = 56.93, `orientation` = 0.017453 WHERE `guid` = 32313 AND `id` = 3658;
-- Food Crate (32754): Goldshire, south of the melon plot: CoA lowered the ground 0.53 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9500.53, `position_y` = 81.368, `position_z` = 56.93, `orientation` = 0.017453 WHERE `guid` = 32754 AND `id` = 3719;
-- Sheep (80366): Goldshire: CoA raised the ground 1.51 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9574.03, `position_y` = 2.28607, `position_z` = 63.22, `orientation` = 1.8693 WHERE `guid` = 80366 AND `id` = 1933;
-- Rabbit (80699): Goldshire refugee camp: CoA lowered the ground 0.77 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9581.12, `position_y` = 18.7787, `position_z` = 59.66, `orientation` = 1.52829 WHERE `guid` = 80699 AND `id` = 721;
-- Stonetusk Boar (80695): Goldshire: CoA lowered the ground 1.14 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9593.61, `position_y` = 54.719, `position_z` = 59.78, `orientation` = 2.22424 WHERE `guid` = 80695 AND `id` = 113;
-- Rockhide Boar (80782): Bandit's Bastion: CoA raised the ground 0.66 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9713.58, `position_y` = -391.615, `position_z` = 51.77, `orientation` = 2.21899 WHERE `guid` = 80782 AND `id` = 524;
-- Sheep (80799): Bandit's Bastion: CoA raised the ground 0.44 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9676.52, `position_y` = -432.06, `position_z` = 54.19, `orientation` = 4.64567 WHERE `guid` = 80799 AND `id` = 1933;
-- Cow (80800): Bandit's Bastion: CoA raised the ground 0.95 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9657.26, `position_y` = -424.879, `position_z` = 58.1, `orientation` = 3.13311 WHERE `guid` = 80800 AND `id` = 2442;
-- Deer (80801): Bandit's Bastion: CoA raised the ground 0.56 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9655.27, `position_y` = -438.494, `position_z` = 56.38, `orientation` = 3.97765 WHERE `guid` = 80801 AND `id` = 883;
-- Rockhide Boar (80802): Bandit's Bastion: CoA lowered the ground 1.65 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9647.33, `position_y` = -393.739, `position_z` = 57.98, `orientation` = 2.92458 WHERE `guid` = 80802 AND `id` = 524;
-- Rabbit (80803): Bandit's Bastion: CoA raised the ground 1.27 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9677.63, `position_y` = -392.864, `position_z` = 54.43, `orientation` = 1.29131 WHERE `guid` = 80803 AND `id` = 721;
-- Mangy Wolf (80810): Crystal Lake: CoA lowered the ground 0.92 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9585.82, `position_y` = -411.112, `position_z` = 62.94, `orientation` = 2.12572 WHERE `guid` = 80810 AND `id` = 525;
-- Deer (80923): Tower of Azora: CoA lowered the ground 0.86 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9609.2, `position_y` = -882.045, `position_z` = 48.72, `orientation` = 0.314179 WHERE `guid` = 80923 AND `id` = 883;
-- Murloc Forager (81325): Stone Cairn Lake: CoA lowered the ground 1.08 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -8913.71, `position_y` = -1191.35, `position_z` = 73.78, `orientation` = 5.07544 WHERE `guid` = 81325 AND `id` = 46;
-- Wild Turkey (240990): south Elwynn: CoA lowered the ground 0.71 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9738, `position_y` = -1213, `position_z` = 46.92, `orientation` = 2.495 WHERE `guid` = 240990 AND `id` = 32820;
-- Wild Turkey (241095): Bandit's Bastion: CoA raised the ground 1.33 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9681, `position_y` = -416, `position_z` = 55.66, `orientation` = 3.698 WHERE `guid` = 241095 AND `id` = 32820;
-- Wild Turkey (241116): Bandit's Bastion: CoA raised the ground 0.83 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9667, `position_y` = -434, `position_z` = 55.67, `orientation` = 0.73 WHERE `guid` = 241116 AND `id` = 32820;
-- Wild Turkey (241117): Bandit's Bastion: CoA raised the ground 0.96 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9667, `position_y` = -429, `position_z` = 56.24, `orientation` = 2.6 WHERE `guid` = 241117 AND `id` = 32820;
-- Wild Turkey (241132): Bandit's Bastion: CoA raised the ground 0.92 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9655, `position_y` = -430, `position_z` = 57.77, `orientation` = 3.104 WHERE `guid` = 241132 AND `id` = 32820;
-- Wild Turkey (241149): Bandit's Bastion: CoA lowered the ground 2.68 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9643, `position_y` = -390, `position_z` = 57.77, `orientation` = 1.07 WHERE `guid` = 241149 AND `id` = 32820;
-- Wild Turkey (241289): north of Mirror Lake: CoA lowered the ground 1.40 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9516, `position_y` = 427.811, `position_z` = 53.48, `orientation` = 0.716 WHERE `guid` = 241289 AND `id` = 32820;
-- Wild Turkey (241308): Goldshire: CoA lowered the ground 2.40 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9499, `position_y` = -56, `position_z` = 57.59, `orientation` = 1.879 WHERE `guid` = 241308 AND `id` = 32820;
-- Wild Turkey (241319): Goldshire: CoA lowered the ground 3.22 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9491, `position_y` = -53, `position_z` = 57.27, `orientation` = 5.207 WHERE `guid` = 241319 AND `id` = 32820;
-- Wild Turkey (241446): north of Mirror Lake: CoA lowered the ground 3.17 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9402, `position_y` = 324.172, `position_z` = 55.05, `orientation` = 0.634 WHERE `guid` = 241446 AND `id` = 32820;
-- Wild Turkey (241452): north of Mirror Lake: CoA lowered the ground 1.22 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9395, `position_y` = 312.681, `position_z` = 60.37, `orientation` = 1.533 WHERE `guid` = 241452 AND `id` = 32820;
-- Wild Turkey (241555): east of Goldshire: CoA lowered the ground 5.58 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9303, `position_y` = -27, `position_z` = 64.3, `orientation` = 4.012 WHERE `guid` = 241555 AND `id` = 32820;
-- Wild Turkey (241549): around the Spada manor: CoA raised the ground 0.89 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9308, `position_y` = 454.329, `position_z` = 78.6, `orientation` = 2.505 WHERE `guid` = 241549 AND `id` = 32820;
-- Wild Turkey (241613): around the Spada manor: CoA lowered the ground 2.80 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9253, `position_y` = 437.779, `position_z` = 82.76, `orientation` = 2.492 WHERE `guid` = 241613 AND `id` = 32820;
-- Wild Turkey (241618): around the Spada manor: CoA raised the ground 0.58 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9249, `position_y` = 382.408, `position_z` = 80.7, `orientation` = 4.058 WHERE `guid` = 241618 AND `id` = 32820;
-- Wild Turkey (241648): around the Spada manor: CoA lowered the ground 2.17 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9217, `position_y` = 427.754, `position_z` = 87.52, `orientation` = 0.175 WHERE `guid` = 241648 AND `id` = 32820;
-- Wild Turkey (241652): around the Spada manor: CoA lowered the ground 1.16 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9213, `position_y` = 426.235, `position_z` = 87.7, `orientation` = 0.441 WHERE `guid` = 241652 AND `id` = 32820;
-- Wild Turkey (241670): around the Spada manor: CoA raised the ground 0.49 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9177, `position_y` = 418.347, `position_z` = 91.82, `orientation` = 0.86 WHERE `guid` = 241670 AND `id` = 32820;
-- Wild Turkey (241892): Northshire: CoA lowered the ground 1.37 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -8785, `position_y` = -278, `position_z` = 77.37, `orientation` = 0.996 WHERE `guid` = 241892 AND `id` = 32820;
-- Wild Turkey (241474): Goldshire Midsummer field: CoA lowered the ground 1.32 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9380, `position_y` = 29.617, `position_z` = 59.86, `orientation` = 2.488 WHERE `guid` = 241474 AND `id` = 32820;
-- Wild Turkey (241495): Goldshire Midsummer field: CoA lowered the ground 1.48 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9364, `position_y` = 11.024, `position_z` = 60.33, `orientation` = 2.506 WHERE `guid` = 241495 AND `id` = 32820;
-- Wild Turkey (244095): Goldshire Midsummer field: CoA lowered the ground 1.97 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9375.14, `position_y` = 26.3486, `position_z` = 59.74, `orientation` = 4.83456 WHERE `guid` = 244095 AND `id` = 32820;
-- Wild Turkey (244096): Goldshire Midsummer field: CoA lowered the ground 1.50 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9383.17, `position_y` = 11.5458, `position_z` = 59.64, `orientation` = 1.44862 WHERE `guid` = 244096 AND `id` = 32820;
-- Wild Turkey (244097): Goldshire Midsummer field: CoA lowered the ground 2.46 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9373.36, `position_y` = 22.8965, `position_z` = 59.63, `orientation` = 2.21657 WHERE `guid` = 244097 AND `id` = 32820;
-- Wild Turkey (244123): Goldshire Midsummer field: CoA lowered the ground 2.09 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9382.33, `position_y` = 14.4817, `position_z` = 59.53, `orientation` = 4.2586 WHERE `guid` = 244123 AND `id` = 32820;
-- Fire Eater (86714): Goldshire Midsummer field: CoA lowered the ground 2.66 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9379.87, `position_y` = 18.9105, `position_z` = 59.52, `orientation` = 5.11381 WHERE `guid` = 86714 AND `id` = 25962;
-- Midsummer Celebrant (94559): Goldshire Midsummer field: CoA lowered the ground 1.97 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9375.14, `position_y` = 26.3486, `position_z` = 59.74, `orientation` = 4.83456 WHERE `guid` = 94559 AND `id` = 16781;
-- Midsummer Celebrant (94560): Goldshire Midsummer field: CoA lowered the ground 1.50 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9383.17, `position_y` = 11.5458, `position_z` = 59.64, `orientation` = 1.44862 WHERE `guid` = 94560 AND `id` = 16781;
-- Midsummer Celebrant (94561): Goldshire Midsummer field: CoA lowered the ground 2.46 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9373.36, `position_y` = 22.8965, `position_z` = 59.63, `orientation` = 2.21657 WHERE `guid` = 94561 AND `id` = 16781;
-- Midsummer Celebrant (94619): Goldshire Midsummer field: CoA lowered the ground 2.09 yd; same spot, CoA floor
UPDATE `creature` SET `position_x` = -9382.33, `position_y` = 14.4817, `position_z` = 59.53, `orientation` = 4.2586 WHERE `guid` = 94619 AND `id` = 16781;
-- Headless Horseman Flame Bunny (240165): Hallow's End fire on the smithy roof; onto the replacement smithy's roof
UPDATE `creature` SET `position_x` = -9457.31, `position_y` = 81.8038, `position_z` = 69.03, `orientation` = 0.0327492 WHERE `guid` = 240165 AND `id` = 23686;
-- Headless Horseman Flame Bunny (240167): Hallow's End fire on the smithy roof; onto the replacement smithy's roof
UPDATE `creature` SET `position_x` = -9460.53, `position_y` = 84.1486, `position_z` = 69.86, `orientation` = 1.83131 WHERE `guid` = 240167 AND `id` = 23686;
-- Bundle of Wood (27032): Bundle of Wood (quest 5545) under raised terrain at Stone Cairn Lake; onto the CoA
--   ground
UPDATE `gameobject` SET `position_x` = -9186.53, `position_y` = -1271.85, `position_z` = 77.53, `orientation` = -1.74533 WHERE `guid` = 27032 AND `id` = 176793;
-- XMasGift06 (40862): Goldshire Winter Veil tree by the market: CoA lowered the ground 1.02 yd; same spot, CoA
--   floor
UPDATE `gameobject` SET `position_x` = -9442.94, `position_y` = 36.8943, `position_z` = 56.89, `orientation` = 4.85202 WHERE `guid` = 40862 AND `id` = 178433;
-- XMasGift04 (40864): Goldshire Winter Veil tree by the market: CoA lowered the ground 0.96 yd; same spot, CoA
--   floor
UPDATE `gameobject` SET `position_x` = -9442.55, `position_y` = 39.3654, `position_z` = 56.89, `orientation` = 3.31614 WHERE `guid` = 40864 AND `id` = 178431;
-- XMasGift06 (40866): Goldshire Winter Veil tree by the market: CoA lowered the ground 1.05 yd; same spot, CoA
--   floor
UPDATE `gameobject` SET `position_x` = -9443.25, `position_y` = 38.6544, `position_z` = 57.23, `orientation` = 2.60054 WHERE `guid` = 40866 AND `id` = 178433;
-- XMasGift04 (40887): Goldshire Winter Veil tree by the market: CoA lowered the ground 1.06 yd; same spot, CoA
--   floor
UPDATE `gameobject` SET `position_x` = -9442.88, `position_y` = 37.7384, `position_z` = 56.86, `orientation` = 1.98967 WHERE `guid` = 40887 AND `id` = 178431;
-- XMasGift01 (40889): Goldshire Winter Veil tree by the market: CoA lowered the ground 1.15 yd; same spot, CoA
--   floor
UPDATE `gameobject` SET `position_x` = -9441.79, `position_y` = 37.9808, `position_z` = 56.82, `orientation` = 4.45059 WHERE `guid` = 40889 AND `id` = 178428;
-- XMasGift06 (40890): Goldshire Winter Veil tree by the market: CoA lowered the ground 0.98 yd; same spot, CoA
--   floor
UPDATE `gameobject` SET `position_x` = -9441.67, `position_y` = 38.9009, `position_z` = 56.82, `orientation` = 1.43117 WHERE `guid` = 40890 AND `id` = 178433;
-- XMasGift05 (40894): Goldshire Winter Veil tree by the market: CoA lowered the ground 0.86 yd; same spot, CoA
--   floor
UPDATE `gameobject` SET `position_x` = -9443.99, `position_y` = 37.3294, `position_z` = 57.01, `orientation` = 1.32645 WHERE `guid` = 40894 AND `id` = 178432;
-- XMasGift05 (40900): Goldshire Winter Veil tree by the market: CoA lowered the ground 0.88 yd; same spot, CoA
--   floor
UPDATE `gameobject` SET `position_x` = -9443.25, `position_y` = 40.0653, `position_z` = 57, `orientation` = 1.18682 WHERE `guid` = 40900 AND `id` = 178432;
-- XMasGift03 (41505): Goldshire Winter Veil tree by the market: CoA lowered the ground 1.05 yd; same spot, CoA
--   floor
UPDATE `gameobject` SET `position_x` = -9443.3, `position_y` = 38.843, `position_z` = 56.9, `orientation` = 0.418879 WHERE `guid` = 41505 AND `id` = 178430;
-- Christmas Tree (Large) (41656): Goldshire Winter Veil tree by the market: CoA lowered the ground 0.84 yd; same
--   spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9444.12, `position_y` = 39.8997, `position_z` = 57.06, `orientation` = 1.95477 WHERE `guid` = 41656 AND `id` = 178425;
-- G_Pumpkin_01 (68030): Hallow's End pumpkin on the smithy ridge; onto the replacement smithy's roof
UPDATE `gameobject` SET `position_x` = -9456.98, `position_y` = 96.8744, `position_z` = 74.51, `orientation` = 2.79252 WHERE `guid` = 68030 AND `id` = 180405;
-- G_Pumpkin_02 (68341): Hallow's End pumpkin on the smithy ridge; onto the replacement smithy's roof
UPDATE `gameobject` SET `position_x` = -9463.06, `position_y` = 91.5218, `position_z` = 74.56, `orientation` = 5.79449 WHERE `guid` = 68341 AND `id` = 180406;
-- G_Pumpkin_03 (68647): Hallow's End pumpkin on the smithy ridge; onto the replacement smithy's roof
UPDATE `gameobject` SET `position_x` = -9456.86, `position_y` = 91.6574, `position_z` = 74.52, `orientation` = 1.18682 WHERE `guid` = 68647 AND `id` = 180407;
-- G_Pumpkin_03 (68648): Hallow's End pumpkin on the smithy ridge; onto the replacement smithy's roof
UPDATE `gameobject` SET `position_x` = -9463.02, `position_y` = 96.6597, `position_z` = 74.6, `orientation` = 4.38078 WHERE `guid` = 68648 AND `id` = 180407;
-- Brightly Colored Egg (151927): Noblegarden egg floating in the new two-storey house; onto its floor
UPDATE `gameobject` SET `position_x` = -9416.75, `position_y` = 54.7442, `position_z` = 58.32, `orientation` = 5.99605 WHERE `guid` = 151927 AND `id` = 113769;
-- Brightly Colored Egg (151942): Goldshire: CoA lowered the ground 0.24 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9511.45, `position_y` = 101.96, `position_z` = 58.45, `orientation` = 3.55663 WHERE `guid` = 151942 AND `id` = 113769;
-- Earthroot (206595): Bandit's Bastion: CoA lowered the ground 2.98 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9764.79, `position_y` = -505.546, `position_z` = 35.41, `orientation` = 0.383971 WHERE `guid` = 206595 AND `id` = 1619;
-- Copper Vein (206641): Mirror Lake cliff: CoA raised the ground 3.94 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9333.82, `position_y` = 494.622, `position_z` = 69.75, `orientation` = 3.29869 WHERE `guid` = 206641 AND `id` = 1731;
-- G_Pumpkin_01 (36183): Goldshire: CoA lowered the ground 0.95 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9485.53, `position_y` = 20.3553, `position_z` = 56.61, `orientation` = 5.02655 WHERE `guid` = 36183 AND `id` = 180405;
-- G_Pumpkin_02 (36627): Goldshire: CoA lowered the ground 1.23 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9483.64, `position_y` = 32.7722, `position_z` = 56.64, `orientation` = 4.93928 WHERE `guid` = 36627 AND `id` = 180406;
-- G_Pumpkin_03 (37049): Goldshire: CoA lowered the ground 0.93 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9484.71, `position_y` = 26.726, `position_z` = 56.63, `orientation` = 4.97419 WHERE `guid` = 37049 AND `id` = 180407;
-- Camp Crate (50805): Goldshire Midsummer field: CoA lowered the ground 1.16 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9382.95, `position_y` = 29.5739, `position_z` = 59.48, `orientation` = 2.9496 WHERE `guid` = 50805 AND `id` = 181302;
-- Camp Table (50822): Goldshire Midsummer field: CoA lowered the ground 1.62 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9383.36, `position_y` = 23.5157, `position_z` = 59.56, `orientation` = 2.26893 WHERE `guid` = 50822 AND `id` = 181305;
-- Camp Jug (50891): Goldshire Midsummer field: CoA lowered the ground 1.00 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9384.07, `position_y` = 27.6846, `position_z` = 59.65, `orientation` = 2.00713 WHERE `guid` = 50891 AND `id` = 181306;
-- Ribbon Pole (51040): Goldshire Midsummer field: CoA lowered the ground 3.64 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9376.28, `position_y` = 10.366, `position_z` = 59.26, `orientation` = 5.77704 WHERE `guid` = 51040 AND `id` = 181605;
-- Standing, Exterior, Medium - MFF (51592): Goldshire Midsummer field: CoA lowered the ground 0.88 yd; same spot,
--   CoA floor
UPDATE `gameobject` SET `position_x` = -9392.81, `position_y` = 47.6417, `position_z` = 58.99, `orientation` = 0.855211 WHERE `guid` = 51592 AND `id` = 181355;
-- Standing, Exterior, Medium - MFF (51593): Goldshire Midsummer field: CoA lowered the ground 2.10 yd; same spot,
--   CoA floor
UPDATE `gameobject` SET `position_x` = -9368.33, `position_y` = 16.2569, `position_z` = 60.03, `orientation` = 5.20108 WHERE `guid` = 51593 AND `id` = 181355;
-- Standing, Exterior, Medium - MFF (51840): Goldshire Midsummer field: CoA lowered the ground 1.28 yd; same spot,
--   CoA floor
UPDATE `gameobject` SET `position_x` = -9390.52, `position_y` = 11.5798, `position_z` = 58.97, `orientation` = 0.855211 WHERE `guid` = 51840 AND `id` = 181355;
-- Standing, Exterior, Medium - MFF (51987): Goldshire Midsummer field: CoA lowered the ground 1.76 yd; same spot,
--   CoA floor
UPDATE `gameobject` SET `position_x` = -9372.2, `position_y` = 27.2544, `position_z` = 59.66, `orientation` = 5.84685 WHERE `guid` = 51987 AND `id` = 181355;
-- Camp Banner (52349): Goldshire Midsummer field: CoA lowered the ground 1.56 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9395.51, `position_y` = 17.4708, `position_z` = 58.14, `orientation` = 3.927 WHERE `guid` = 52349 AND `id` = 188020;
-- Camp Banner (52417): Goldshire Midsummer field: CoA lowered the ground 2.13 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9369.81, `position_y` = 19.1569, `position_z` = 59.95, `orientation` = 0.733038 WHERE `guid` = 52417 AND `id` = 188020;
-- Camp Banner (52418): Goldshire Midsummer field: CoA lowered the ground 1.17 yd; same spot, CoA floor
UPDATE `gameobject` SET `position_x` = -9383.84, `position_y` = 5.59738, `position_z` = 59.68, `orientation` = 0.087266 WHERE `guid` = 52418 AND `id` = 188020;
-- Camp Mug (50933): Midsummer camp mug; kept on the camp table (table z + 0.98)
UPDATE `gameobject` SET `position_x` = -9383.01, `position_y` = 22.8865, `position_z` = 60.54, `orientation` = 1.65806 WHERE `guid` = 50933 AND `id` = 181307;
-- Ribbon Pole Debug Target (94849): ribbon pole target; kept 6.58 yd above the re-seated ribbon pole
UPDATE `creature` SET `position_x` = -9376.28, `position_y` = 10.366, `position_z` = 65.84, `orientation` = 5.77704 WHERE `guid` = 94849 AND `id` = 17066;

-- ---------------------------------------------------------------------------
-- 5. Goldshire's signpost arms, moved to the market plaza post
-- ---------------------------------------------------------------------------
-- Northshire Abbey (26794): direction arm on Goldshire's stock signpost, which CoA replaced with a 1.626-scale
--   post on the market plaza; moved with the post
UPDATE `gameobject` SET `position_x` = -9462.51, `position_y` = 41.52, `position_z` = 56.371, `orientation` = 4.6212, `rotation2` = 0.738601, `rotation3` = -0.674143 WHERE `guid` = 26794 AND `id` = 91;
-- Stormwind City (26795): direction arm on Goldshire's stock signpost, which CoA replaced with a 1.626-scale post
--   on the market plaza; moved with the post
UPDATE `gameobject` SET `position_x` = -9462.53, `position_y` = 41.53, `position_z` = 57.275, `orientation` = 4.6212, `rotation2` = 0.738601, `rotation3` = -0.674143 WHERE `guid` = 26795 AND `id` = 92;
-- Eastvale Logging Camp (26796): direction arm on Goldshire's stock signpost, which CoA replaced with a
--   1.626-scale post on the market plaza; moved with the post
UPDATE `gameobject` SET `position_x` = -9464.15, `position_y` = 40.01, `position_z` = 57.267, `orientation` = 3.0504, `rotation2` = 0.998961, `rotation3` = 0.045581 WHERE `guid` = 26796 AND `id` = 95;
-- Redridge (26797): direction arm on Goldshire's stock signpost, which CoA replaced with a 1.626-scale post on the
--   market plaza; moved with the post
UPDATE `gameobject` SET `position_x` = -9464.11, `position_y` = 40, `position_z` = 56.363, `orientation` = 3.0504, `rotation2` = 0.998961, `rotation3` = 0.045581 WHERE `guid` = 26797 AND `id` = 96;
-- Westbrook Garrison (26798): direction arm on Goldshire's stock signpost, which CoA replaced with a 1.626-scale
--   post on the market plaza; moved with the post
UPDATE `gameobject` SET `position_x` = -9463.93, `position_y` = 43.22, `position_z` = 57.245, `orientation` = 6.192, `rotation2` = 0.045577, `rotation3` = -0.998961 WHERE `guid` = 26798 AND `id` = 93;
-- Westfall (26799): direction arm on Goldshire's stock signpost, which CoA replaced with a 1.626-scale post on the
--   market plaza; moved with the post
UPDATE `gameobject` SET `position_x` = -9463.91, `position_y` = 43.19, `position_z` = 56.34, `orientation` = 6.192, `rotation2` = 0.045577, `rotation3` = -0.998961 WHERE `guid` = 26799 AND `id` = 94;
-- Hanging, Square, Small - MFF (54778): Midsummer decoration on Goldshire's stock signpost, which CoA replaced
--   with a 1.626-scale post on the market plaza; moved with the post
UPDATE `gameobject` SET `position_x` = -9463.39, `position_y` = 41.56, `position_z` = 58.308, `orientation` = 6.2094, `rotation2` = 0.036884, `rotation3` = -0.99932 WHERE `guid` = 54778 AND `id` = 187576;
UPDATE `gameobject_template` SET `size` = 1.626 WHERE `entry` IN (91, 92, 93, 94, 95, 96);

-- ---------------------------------------------------------------------------
-- 6. Lion's Pride Inn rest area
-- ---------------------------------------------------------------------------
UPDATE `areatrigger` SET `x` = -9483.25, `y` = -17.9883, `z` = 56.9634 WHERE `entry` = 562;

-- ---------------------------------------------------------------------------
-- 7. Antonio Perelli's inn visit
-- ---------------------------------------------------------------------------
DELETE FROM `waypoints` WHERE `entry` IN (84402, 84403);
INSERT INTO `waypoints` (`entry`, `pointid`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `point_comment`)
VALUES
(84402, 1, -9470, 62.8, 55.99, NULL, 0, 'AntonioPerelli'),
(84402, 2, -9475.8, 50, 56.74, NULL, 0, 'AntonioPerelli'),
(84402, 3, -9471.5, 40, 56.58, NULL, 0, 'AntonioPerelli'),
(84402, 4, -9480.47, 18.96, 56.2968, NULL, 0, 'AntonioPerelli'),
(84402, 5, -9480.6, 2.18, 56.9501, NULL, 0, 'AntonioPerelli'),
(84402, 6, -9487.35, 1.71, 56.9649, NULL, 0, 'AntonioPerelli'),
(84402, 7, -9487.03, -4.53, 56.9649, NULL, 0, 'AntonioPerelli'),
(84402, 8, -9486.77, -9.46, 56.3399, NULL, 0, 'AntonioPerelli'),
(84402, 9, -9486.91, -15.76, 56.9634, NULL, 0, 'AntonioPerelli'),
(84402, 10, -9484.52, -19.23, 56.9634, NULL, 0, 'AntonioPerelli'),
(84403, 1, -9487.11, -16.19, 56.9634, NULL, 0, 'AntonioPerelli'),
(84403, 2, -9486.81, -11.09, 56.3397, NULL, 0, 'AntonioPerelli'),
(84403, 3, -9486.81, -4.79, 56.9664, NULL, 0, 'AntonioPerelli'),
(84403, 4, -9488.13, 1.11, 56.9664, NULL, 0, 'AntonioPerelli'),
(84403, 5, -9480.63, 2, 56.9516, NULL, 0, 'AntonioPerelli'),
(84403, 6, -9480.13, 16.8, 56.5144, NULL, 0, 'AntonioPerelli'),
(84403, 7, -9471.5, 40, 56.58, NULL, 0, 'AntonioPerelli'),
(84403, 8, -9475.8, 50, 56.74, NULL, 0, 'AntonioPerelli'),
(84403, 9, -9484.57, 68.9656, 56.3056, NULL, 0, 'AntonioPerelli'),
(84403, 10, -9487.32, 79.8572, 56.0447, NULL, 0, 'AntonioPerelli'),
(84403, 11, -9481.79, 116.391, 56.5505, NULL, 0, 'AntonioPerelli'),
(84403, 12, -9481.69, 158.113, 56.0987, NULL, 0, 'AntonioPerelli'),
(84403, 13, -9484.71, 182.812, 55.2594, NULL, 0, 'AntonioPerelli'),
(84403, 14, -9502.95, 212.588, 53.3357, NULL, 0, 'AntonioPerelli'),
(84403, 15, -9523.8, 235.689, 51.3777, NULL, 0, 'AntonioPerelli'),
(84403, 16, -9542.6, 247.273, 50.4008, NULL, 0, 'AntonioPerelli'),
(84403, 17, -9600.25, 250.499, 47.5452, NULL, 0, 'AntonioPerelli'),
(84403, 18, -9650.26, 256.059, 46.5437, NULL, 0, 'AntonioPerelli'),
(84403, 19, -9674.3, 270.692, 46.438, NULL, 0, 'AntonioPerelli'),
(84403, 20, -9694.47, 290.452, 46.2332, NULL, 0, 'AntonioPerelli'),
(84403, 21, -9716.93, 321.307, 44.5799, NULL, 0, 'AntonioPerelli'),
(84403, 22, -9736.52, 357.126, 42.2989, NULL, 0, 'AntonioPerelli'),
(84403, 23, -9752.82, 403.584, 38.9407, NULL, 0, 'AntonioPerelli'),
(84403, 24, -9756.66, 441.174, 36.1087, NULL, 0, 'AntonioPerelli'),
(84403, 25, -9749.32, 484.488, 33.1644, NULL, 0, 'AntonioPerelli'),
(84403, 26, -9745.53, 514.2, 35.3443, NULL, 0, 'AntonioPerelli'),
(84403, 27, -9743.16, 539.005, 36.2891, NULL, 0, 'AntonioPerelli'),
(84403, 28, -9741.47, 554.714, 35.3796, NULL, 0, 'AntonioPerelli');
