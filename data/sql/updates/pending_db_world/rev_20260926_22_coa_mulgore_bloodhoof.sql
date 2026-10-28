-- CoA Mulgore, Bloodhoof Village: the market square CoA raised and turned, with its patrols and holiday
-- rows; the other buried village rows, graveyard 89, guard directions and stock NPCs at their CoA points.

-- ---------------------------------------------------------------------------
-- 1. The market square (transform A)
-- ---------------------------------------------------------------------------
-- Transform A: rotate +1.58178 rad about (-2265.9946, -297.1554), translate to (-2329.1111, -276.4695), z +
-- 13.6865, o + 1.58178. Every row in this section is moved with the Bloodhoof market square (transform A).
UPDATE `creature` SET `position_x` = -2318.31, `position_y` = -258.165, `position_z` = 4.381, `orientation` = 4.5139 WHERE `guid` = 24672 AND `id` = 3076;
UPDATE `creature` SET `position_x` = -2328.343, `position_y` = -290.597, `position_z` = 4.393, `orientation` = 1.1105 WHERE `guid` = 24673 AND `id` = 3077;
UPDATE `creature` SET `position_x` = -2336.896, `position_y` = -286.091, `position_z` = 4.423, `orientation` = 0.7615 WHERE `guid` = 24674 AND `id` = 3078;
UPDATE `creature` SET `position_x` = -2320.08, `position_y` = -293.717, `position_z` = 4.345, `orientation` = 1.3374 WHERE `guid` = 24675 AND `id` = 3079;
UPDATE `creature` SET `position_x` = -2315.804, `position_y` = -294.8, `position_z` = 4.345, `orientation` = 1.4596 WHERE `guid` = 24676 AND `id` = 3080;
UPDATE `creature` SET `position_x` = -2301.839, `position_y` = -275.775, `position_z` = 4.39, `orientation` = 3.4144 WHERE `guid` = 24677 AND `id` = 3081;
UPDATE `creature` SET `position_x` = -2267.307, `position_y` = -314.218, `position_z` = 4.387, `orientation` = 5.5906 WHERE `guid` = 25222 AND `id` = 3212;
UPDATE `creature` SET `position_x` = -2261.646, `position_y` = -297.295, `position_z` = 4.345, `orientation` = 5.2819 WHERE `guid` = 25541 AND `id` = 11407;
UPDATE `creature` SET `position_x` = -2337.939, `position_y` = -262.401, `position_z` = 4.345, `orientation` = 5.5088 WHERE `guid` = 25800 AND `id` = 6290;
UPDATE `creature` SET `position_x` = -2330.334, `position_y` = -269.248, `position_z` = 4.362, `orientation` = 5.6361 WHERE `guid` = 26053 AND `id` = 3224;
UPDATE `creature` SET `position_x` = -2341.355, `position_y` = -273.869, `position_z` = 4.393, `orientation` = 0.0284 WHERE `guid` = 26907 AND `id` = 3067;
UPDATE `creature` SET `position_x` = -2339.859, `position_y` = -265.242, `position_z` = 4.345, `orientation` = 5.788 WHERE `guid` = 26909 AND `id` = 3069;

UPDATE `gameobject` SET `position_x` = -2312.648, `position_y` = -257.173, `position_z` = 4.262, `orientation` = 4.3219, `rotation2` = 0.830855, `rotation3` = -0.556489 WHERE `guid` = 20532 AND `id` = 3719;
UPDATE `gameobject` SET `position_x` = -2321.715, `position_y` = -265.003, `position_z` = 4.262, `orientation` = 4.7234, `rotation2` = 0.703203, `rotation3` = -0.710989 WHERE `guid` = 20816 AND `id` = 74440;
UPDATE `gameobject` SET `position_x` = -2307.971, `position_y` = -274.853, `position_z` = 4.262, `orientation` = 4.7234, `rotation2` = 0.703203, `rotation3` = -0.710989 WHERE `guid` = 20829 AND `id` = 74441;
UPDATE `gameobject` SET `position_x` = -2330.92, `position_y` = -278.355, `position_z` = 4.262, `orientation` = 4.7146, `rotation2` = 0.706325, `rotation3` = -0.707888 WHERE `guid` = 20833 AND `id` = 74442;
UPDATE `gameobject` SET `position_x` = -2344.491, `position_y` = -280.984, `position_z` = 4.261, `orientation` = 5.0114, `rotation2` = 0.593896, `rotation3` = -0.804542 WHERE `guid` = 20853 AND `id` = 74443;
UPDATE `gameobject` SET `position_x` = -2317.059, `position_y` = -287.983, `position_z` = 4.262, `orientation` = 4.2696, `rotation2` = 0.845122, `rotation3` = -0.534574 WHERE `guid` = 20874 AND `id` = 74444;
UPDATE `gameobject` SET `position_x` = -2319.129, `position_y` = -276.235, `position_z` = 4.261, `orientation` = 4.7234, `rotation2` = 0.703203, `rotation3` = -0.710989 WHERE `guid` = 21158 AND `id` = 15068;

-- Brave Ironhorn's patrol path 252220.
UPDATE `waypoint_data` SET `position_x` = -2263.555, `position_y` = -312.867, `position_z` = 4.262 WHERE `id` = 252220 AND `point` = 1;
UPDATE `waypoint_data` SET `position_x` = -2256.762, `position_y` = -301.262, `position_z` = 4.275 WHERE `id` = 252220 AND `point` = 2;
UPDATE `waypoint_data` SET `position_x` = -2257.743, `position_y` = -287.302, `position_z` = 4.263 WHERE `id` = 252220 AND `point` = 3;
UPDATE `waypoint_data` SET `position_x` = -2258.584, `position_y` = -273.33, `position_z` = 4.263 WHERE `id` = 252220 AND `point` = 4;
UPDATE `waypoint_data` SET `position_x` = -2259.956, `position_y` = -250.244, `position_z` = 4.263 WHERE `id` = 252220 AND `point` = 5;
UPDATE `waypoint_data` SET `position_x` = -2258.309, `position_y` = -258.986, `position_z` = 4.263 WHERE `id` = 252220 AND `point` = 6;
UPDATE `waypoint_data` SET `position_x` = -2256.999, `position_y` = -272.923, `position_z` = 4.263 WHERE `id` = 252220 AND `point` = 7;
UPDATE `waypoint_data` SET `position_x` = -2256.377, `position_y` = -301.808, `position_z` = 4.277 WHERE `id` = 252220 AND `point` = 8;
UPDATE `waypoint_data` SET `position_x` = -2261.147, `position_y` = -310.24, `position_z` = 4.263 WHERE `id` = 252220 AND `point` = 9;
UPDATE `waypoint_data` SET `position_x` = -2267.501, `position_y` = -313.16, `position_z` = 4.263 WHERE `id` = 252220 AND `point` = 10;
UPDATE `waypoint_data` SET `position_x` = -2267.501, `position_y` = -313.16, `position_z` = 4.263 WHERE `id` = 252220 AND `point` = 11;
UPDATE `waypoint_data` SET `position_x` = -2289.797, `position_y` = -296.234, `position_z` = 4.263 WHERE `id` = 252220 AND `point` = 12;
UPDATE `waypoint_data` SET `position_x` = -2303.384, `position_y` = -286.403, `position_z` = 4.263 WHERE `id` = 252220 AND `point` = 13;
UPDATE `waypoint_data` SET `position_x` = -2303.384, `position_y` = -286.403, `position_z` = 4.263 WHERE `id` = 252220 AND `point` = 14;
UPDATE `waypoint_data` SET `position_x` = -2280.32, `position_y` = -302.261, `position_z` = 4.263 WHERE `id` = 252220 AND `point` = 15;

-- Brave Cloudmane's patrol path 260530.
UPDATE `waypoint_data` SET `position_x` = -2322.261, `position_y` = -271.609, `position_z` = 4.26 WHERE `id` = 260530 AND `point` = 1;
UPDATE `waypoint_data` SET `position_x` = -2313.648, `position_y` = -267.845, `position_z` = 4.26 WHERE `id` = 260530 AND `point` = 2;
UPDATE `waypoint_data` SET `position_x` = -2314.222, `position_y` = -275.441, `position_z` = 4.26 WHERE `id` = 260530 AND `point` = 3;
UPDATE `waypoint_data` SET `position_x` = -2310.471, `position_y` = -283.061, `position_z` = 4.26 WHERE `id` = 260530 AND `point` = 4;
UPDATE `waypoint_data` SET `position_x` = -2317.525, `position_y` = -281.078, `position_z` = 4.26 WHERE `id` = 260530 AND `point` = 5;
UPDATE `waypoint_data` SET `position_x` = -2325.198, `position_y` = -285.132, `position_z` = 4.26 WHERE `id` = 260530 AND `point` = 6;
UPDATE `waypoint_data` SET `position_x` = -2324.81, `position_y` = -276.328, `position_z` = 4.26 WHERE `id` = 260530 AND `point` = 7;
UPDATE `waypoint_data` SET `position_x` = -2329.894, `position_y` = -269.593, `position_z` = 4.26 WHERE `id` = 260530 AND `point` = 8;

-- Kyle the Frenzied's path (quest 11129).
-- Node 13: sunk 0.8 yd in the raised bank; 3.5 yd down the bank so 13-14 follows the ground.
UPDATE `waypoints` SET `position_x` = -2312.4, `position_y` = -368.35, `position_z` = -8.572 WHERE `entry` = 23616 AND `pointid` = 13;
-- Node 14: was 11-14 yd under the raised square; along its south foot.
UPDATE `waypoints` SET `position_x` = -2296, `position_y` = -375, `position_z` = -9.267 WHERE `entry` = 23616 AND `pointid` = 14;
-- Node 15: was 11-14 yd under the raised square; along its south foot.
UPDATE `waypoints` SET `position_x` = -2280, `position_y` = -376, `position_z` = -9.425 WHERE `entry` = 23616 AND `pointid` = 15;
-- Node 16: was 11-14 yd under the raised square; along its south foot.
UPDATE `waypoints` SET `position_x` = -2264, `position_y` = -375.5, `position_z` = -9.425 WHERE `entry` = 23616 AND `pointid` = 16;
-- Node 19: the leg from 18 ran through CoA's new Largebasket01; 0.9 yd clear of it.
UPDATE `waypoints` SET `position_x` = -2230, `position_y` = -416.6, `position_z` = -9.416 WHERE `entry` = 23616 AND `pointid` = 19;
-- Node 20: the legs 19-21 ran through CoA's new Mullgoretree02; west of its trunk.
UPDATE `waypoints` SET `position_x` = -2244.96, `position_y` = -441.5, `position_z` = -9.424 WHERE `entry` = 23616 AND `pointid` = 20;
-- Node 23: the leg to 24 ran through CoA's new Mullgoretree01; around its root.
UPDATE `waypoints` SET `position_x` = -2271.28, `position_y` = -478.18, `position_z` = -7.64 WHERE `entry` = 23616 AND `pointid` = 23;

-- ---------------------------------------------------------------------------
-- 2. Village rows and graveyard 89
-- ---------------------------------------------------------------------------
-- Spirit Healer (40567): on the raised burial ground, 2.7 yd from WorldSafeLocs 89, clear of the offering bowls.
UPDATE `creature` SET `position_x` = -2174.5, `position_y` = -343, `position_z` = 1.674, `orientation` = 3.594 WHERE `guid` = 40567 AND `id` = 6491;
-- Uthan Stillwater (24725): CoA's new ridge cuts his lakeside spot off from the water; on its flat crest, facing
-- the lake.
UPDATE `creature` SET `position_x` = -2353.5, `position_y` = -231, `position_z` = 3.475, `orientation` = 2.44346 WHERE `guid` = 24725 AND `id` = 5938;
-- Brown Riding Kodo (24764): a new Animalcage03 stands on its spot; 3.6 yd north-west, by the other riding
-- kodos.
UPDATE `creature` SET `position_x` = -2284, `position_y` = -401, `position_z` = -8.98, `orientation` = 0.116925 WHERE `guid` = 24764 AND `id` = 12354;
-- Reban Freerunner (24783): boxed in by four new looms; 4.4 yd south under the hut awning.
UPDATE `creature` SET `position_x` = -2178.5, `position_y` = -406, `position_z` = -4.588, `orientation` = 0.10472 WHERE `guid` = 24783 AND `id` = 3688;
-- Ambercorn (20326): buried at the new tent site, whose trees CoA removed; at the foot of the new tree.
UPDATE `gameobject` SET `position_x` = -2331.5, `position_y` = -244, `position_z` = 3.853, `orientation` = 1.69297, `rotation2` = 0.748956, `rotation3` = 0.66262 WHERE `guid` = 20326 AND `id` = 2912;
-- Water Barrel (18434): a new signpost stands 0.7 yd from it and CoA's ground is 0.25 yd lower; 1.2 yd clear, on
-- the ground.
UPDATE `gameobject` SET `position_x` = -2212.2, `position_y` = -377.3, `position_z` = -8.954, `orientation` = 1.69297, `rotation2` = 0.748956, `rotation3` = 0.66262 WHERE `guid` = 18434 AND `id` = 3658;
-- WorldSafeLocs.dbc 89 on the raised burial ground.
UPDATE `game_graveyard` SET `x` = -2177.22, `y` = -343.13, `z` = 1.68 WHERE `ID` = 89;

-- ---------------------------------------------------------------------------
-- 3. Guard directions
-- ---------------------------------------------------------------------------
-- Bloodhoof Brave menu 3330 points at the moved NPCs.
UPDATE `points_of_interest` SET `PositionX` = -2341.36, `PositionY` = -273.87 WHERE `ID` = 425;
UPDATE `points_of_interest` SET `PositionX` = -2353.5, `PositionY` = -231 WHERE `ID` = 427;
UPDATE `points_of_interest` SET `PositionX` = -2339.86, `PositionY` = -265.24 WHERE `ID` = 428;
UPDATE `points_of_interest` SET `PositionX` = -2337.94, `PositionY` = -262.4 WHERE `ID` = 429;

-- ---------------------------------------------------------------------------
-- 4. Stock quest NPCs at their CoA turn-in points
-- ---------------------------------------------------------------------------
-- Greatmother Hawkwind (26610): QuestSuperTrack 752 (752).
UPDATE `creature` SET `position_x` = -3058.79, `position_y` = -527.073, `position_z` = 26.167, `orientation` = 0.977384 WHERE `guid` = 26610 AND `id` = 2991;
-- Ancestral Spirit (26614): QuestSuperTrack 420 (773).
UPDATE `creature` SET `position_x` = -989.332, `position_y` = -1108.62, `position_z` = 44.413, `orientation` = 2.84489 WHERE `guid` = 26614 AND `id` = 2994;
-- Brave Windfeather (24916): QuestSuperTrack 1549 (3376), the first node of his path 249160.
UPDATE `creature` SET `position_x` = -2895.3, `position_y` = -243.672, `position_z` = 53.121, `orientation` = 4.1973 WHERE `guid` = 24916 AND `id` = 3209;
-- Kar Stormsinger (24787): QuestSuperTrack 3283 (14087).
UPDATE `creature` SET `position_x` = -2276.54, `position_y` = -402.212, `position_z` = -9.355, `orientation` = 0.645772 WHERE `guid` = 24787 AND `id` = 3690;
-- Seer Ravenfeather (24666): QuestSuperTrack 621 (1462).
UPDATE `creature` SET `position_x` = -2884.05, `position_y` = -248.774, `position_z` = 53.874, `orientation` = 4.46804 WHERE `guid` = 24666 AND `id` = 5888;
-- Morin Cloudstalker's 21.6 s stop moves onto QuestSuperTrack 1104 (751, 764, 765).
UPDATE `waypoint_data` SET `position_x` = -2292.3, `position_y` = -581.686, `position_z` = -9.358 WHERE `id` = 265770 AND `point` = 9;

-- ---------------------------------------------------------------------------
-- 5. Holiday rows
-- ---------------------------------------------------------------------------
-- The square's holiday rows, moved with the Bloodhoof market square (transform A); rows 95536, 95540, 42967,
-- 42969, 44808, 44810: the Shaman and Warlock pedestals and their collision blocks sit 0.23 yd into CoA's
-- plateau under transform A; raised 0.31 yd to the stock 0.08 yd offset.
UPDATE `creature` SET `position_x` = -2288.452, `position_y` = -324.001, `position_z` = 4.345, `orientation` = 1.5818 WHERE `guid` = 52746 AND `id` = 32823;
UPDATE `creature` SET `position_x` = -2281.416, `position_y` = -326.794, `position_z` = 4.345, `orientation` = 5.5262 WHERE `guid` = 52791 AND `id` = 34654;
UPDATE `creature` SET `position_x` = -2265.816, `position_y` = -296.281, `position_z` = 4.345, `orientation` = 4.287 WHERE `guid` = 95522 AND `id` = 26759;
UPDATE `creature` SET `position_x` = -2288.563, `position_y` = -309.812, `position_z` = 4.345, `orientation` = 6.1545 WHERE `guid` = 95524 AND `id` = 26748;
UPDATE `creature` SET `position_x` = -2279.149, `position_y` = -296.417, `position_z` = 4.345, `orientation` = 5.1073 WHERE `guid` = 95526 AND `id` = 26756;
UPDATE `creature` SET `position_x` = -2287.184, `position_y` = -305.906, `position_z` = 4.345, `orientation` = 5.8927 WHERE `guid` = 95527 AND `id` = 26753;
UPDATE `creature` SET `position_x` = -2288.563, `position_y` = -309.812, `position_z` = 8.028, `orientation` = 6.1545 WHERE `guid` = 95530 AND `id` = 26307;
UPDATE `creature` SET `position_x` = -2254.545, `position_y` = -317.688, `position_z` = 4.379, `orientation` = 5.3691 WHERE `guid` = 95535 AND `id` = 26741;
UPDATE `creature` SET `position_x` = -2274.685, `position_y` = -295.208, `position_z` = 4.655, `orientation` = 4.8281 WHERE `guid` = 95536 AND `id` = 26757;
UPDATE `creature` SET `position_x` = -2288.241, `position_y` = -318.889, `position_z` = 4.345, `orientation` = 0.4299 WHERE `guid` = 95539 AND `id` = 26751;
UPDATE `creature` SET `position_x` = -2269.945, `position_y` = -295.046, `position_z` = 4.655, `orientation` = 4.5488 WHERE `guid` = 95540 AND `id` = 26758;
UPDATE `creature` SET `position_x` = -2282.971, `position_y` = -298.499, `position_z` = 4.345, `orientation` = 5.3691 WHERE `guid` = 95541 AND `id` = 26755;
UPDATE `creature` SET `position_x` = -2285.812, `position_y` = -301.831, `position_z` = 4.345, `orientation` = 5.6309 WHERE `guid` = 95546 AND `id` = 26754;
UPDATE `creature` SET `position_x` = -2289.202, `position_y` = -314.139, `position_z` = 4.345, `orientation` = 0.1506 WHERE `guid` = 95547 AND `id` = 26752;

UPDATE `gameobject` SET `position_x` = -2288.452, `position_y` = -324.001, `position_z` = 4.262, `orientation` = 1.5818, `rotation2` = 0.710986, `rotation3` = 0.703206 WHERE `guid` = 3354 AND `id` = 195664;
UPDATE `gameobject` SET `position_x` = -2290.734, `position_y` = -314.816, `position_z` = 4.262, `orientation` = 5.0724, `rotation2` = 0.569085, `rotation3` = -0.822279 WHERE `guid` = 16346 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = -2283.794, `position_y` = -319, `position_z` = 4.262, `orientation` = 1.5818, `rotation2` = 0.710986, `rotation3` = 0.703206 WHERE `guid` = 16347 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = -2297.898, `position_y` = -319.985, `position_z` = 4.262, `orientation` = 5.0724, `rotation2` = 0.569085, `rotation3` = -0.822279 WHERE `guid` = 16348 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = -2304.894, `position_y` = -324.892, `position_z` = 4.262, `orientation` = 1.5818, `rotation2` = 0.710986, `rotation3` = 0.703206 WHERE `guid` = 16349 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = -2282.837, `position_y` = -326.09, `position_z` = 4.262, `orientation` = 1.5818, `rotation2` = 0.710986, `rotation3` = 0.703206 WHERE `guid` = 16350 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = -2290.252, `position_y` = -331.331, `position_z` = 4.262, `orientation` = 1.5818, `rotation2` = 0.710986, `rotation3` = 0.703206 WHERE `guid` = 16351 AND `id` = 180353;
UPDATE `gameobject` SET `position_x` = -2289.7, `position_y` = -314.534, `position_z` = 4.938, `orientation` = 4.9503, `rotation2` = 0.618194, `rotation3` = -0.786026 WHERE `guid` = 19099 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = -2291.447, `position_y` = -315.474, `position_z` = 4.938, `orientation` = 5.3168, `rotation2` = 0.464609, `rotation3` = -0.885516 WHERE `guid` = 19100 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = -2284.286, `position_y` = -318.065, `position_z` = 4.938, `orientation` = 3.8682, `rotation2` = 0.934728, `rotation3` = -0.355364 WHERE `guid` = 19101 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = -2297.169, `position_y` = -319.337, `position_z` = 4.938, `orientation` = 5.0201, `rotation2` = 0.590391, `rotation3` = -0.807118 WHERE `guid` = 19102 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = -2283.255, `position_y` = -319.814, `position_z` = 4.938, `orientation` = 3.7634, `rotation2` = 0.952058, `rotation3` = -0.305919 WHERE `guid` = 19103 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = -2298.71, `position_y` = -320.534, `position_z` = 4.938, `orientation` = 5.3168, `rotation2` = 0.464609, `rotation3` = -0.885516 WHERE `guid` = 19104 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = -2303.945, `position_y` = -324.311, `position_z` = 4.938, `orientation` = 5.2644, `rotation2` = 0.487647, `rotation3` = -0.873041 WHERE `guid` = 19105 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = -2282.211, `position_y` = -325.243, `position_z` = 4.938, `orientation` = 2.8384, `rotation2` = 0.988531, `rotation3` = 0.151016 WHERE `guid` = 19106 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = -2305.025, `position_y` = -326.043, `position_z` = 4.938, `orientation` = 5.8927, `rotation2` = 0.194005, `rotation3` = -0.981001 WHERE `guid` = 19107 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = -2283.572, `position_y` = -326.788, `position_z` = 4.938, `orientation` = 5.4739, `rotation2` = 0.39369, `rotation3` = -0.919243 WHERE `guid` = 19108 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = -2289.153, `position_y` = -330.609, `position_z` = 4.938, `orientation` = 2.245, `rotation2` = 0.901187, `rotation3` = 0.433431 WHERE `guid` = 19109 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = -2290.964, `position_y` = -332.139, `position_z` = 4.938, `orientation` = 2.245, `rotation2` = 0.901187, `rotation3` = 0.433431 WHERE `guid` = 19110 AND `id` = 195164;
UPDATE `gameobject` SET `position_x` = -2295.539, `position_y` = -297.017, `position_z` = 4.262, `orientation` = 1.3898, `rotation2` = 0.640309, `rotation3` = 0.768118 WHERE `guid` = 36816 AND `id` = 180406;
UPDATE `gameobject` SET `position_x` = -2291.058, `position_y` = -290.128, `position_z` = 4.262, `orientation` = 1.2327, `rotation2` = 0.578061, `rotation3` = 0.815994 WHERE `guid` = 37242 AND `id` = 180407;
UPDATE `gameobject` SET `position_x` = -2288.241, `position_y` = -318.889, `position_z` = 8.028, `orientation` = 0.4299, `rotation2` = 0.213299, `rotation3` = 0.976987 WHERE `guid` = 42074 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2288.241, `position_y` = -318.889, `position_z` = 4.345, `orientation` = 0.4299, `rotation2` = 0.213299, `rotation3` = 0.976987 WHERE `guid` = 42444 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2254.545, `position_y` = -317.688, `position_z` = 8.063, `orientation` = 5.3691, `rotation2` = 0.441296, `rotation3` = -0.897361 WHERE `guid` = 42445 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2254.545, `position_y` = -317.688, `position_z` = 4.379, `orientation` = 5.3691, `rotation2` = 0.441296, `rotation3` = -0.897361 WHERE `guid` = 42446 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2288.563, `position_y` = -309.812, `position_z` = 8.028, `orientation` = 6.1545, `rotation2` = 0.064298, `rotation3` = -0.997931 WHERE `guid` = 42937 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2288.563, `position_y` = -309.812, `position_z` = 4.345, `orientation` = 6.1545, `rotation2` = 0.064298, `rotation3` = -0.997931 WHERE `guid` = 42939 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2287.184, `position_y` = -305.906, `position_z` = 8.028, `orientation` = 5.8927, `rotation2` = 0.194005, `rotation3` = -0.981001 WHERE `guid` = 42940 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2287.184, `position_y` = -305.906, `position_z` = 4.345, `orientation` = 5.8927, `rotation2` = 0.194005, `rotation3` = -0.981001 WHERE `guid` = 42941 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2285.812, `position_y` = -301.831, `position_z` = 8.028, `orientation` = 5.6309, `rotation2` = 0.320391, `rotation3` = -0.947285 WHERE `guid` = 42942 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2285.812, `position_y` = -301.831, `position_z` = 4.345, `orientation` = 5.6309, `rotation2` = 0.320391, `rotation3` = -0.947285 WHERE `guid` = 42943 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2282.971, `position_y` = -298.499, `position_z` = 8.028, `orientation` = 5.3691, `rotation2` = 0.441296, `rotation3` = -0.897361 WHERE `guid` = 42944 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2282.971, `position_y` = -298.499, `position_z` = 4.345, `orientation` = 5.3691, `rotation2` = 0.441296, `rotation3` = -0.897361 WHERE `guid` = 42947 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2265.816, `position_y` = -296.281, `position_z` = 8.028, `orientation` = 4.287, `rotation2` = 0.840439, `rotation3` = -0.541906 WHERE `guid` = 42948 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2265.816, `position_y` = -296.281, `position_z` = 4.345, `orientation` = 4.287, `rotation2` = 0.840439, `rotation3` = -0.541906 WHERE `guid` = 42949 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2279.149, `position_y` = -296.417, `position_z` = 8.028, `orientation` = 5.1073, `rotation2` = 0.55465, `rotation3` = -0.832084 WHERE `guid` = 42961 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2279.149, `position_y` = -296.417, `position_z` = 4.345, `orientation` = 5.1073, `rotation2` = 0.55465, `rotation3` = -0.832084 WHERE `guid` = 42966 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2274.685, `position_y` = -295.208, `position_z` = 8.338, `orientation` = 4.8281, `rotation2` = 0.665036, `rotation3` = -0.746811 WHERE `guid` = 42967 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2274.685, `position_y` = -295.208, `position_z` = 4.655, `orientation` = 4.8281, `rotation2` = 0.665036, `rotation3` = -0.746811 WHERE `guid` = 42969 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2289.684, `position_y` = -314.474, `position_z` = 4.262, `orientation` = 4.9503, `rotation2` = 0.618194, `rotation3` = -0.786026 WHERE `guid` = 43687 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = -2291.541, `position_y` = -315.435, `position_z` = 4.262, `orientation` = 5.3342, `rotation2` = 0.456887, `rotation3` = -0.889525 WHERE `guid` = 43688 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = -2284.166, `position_y` = -318.204, `position_z` = 4.262, `orientation` = 3.7983, `rotation2` = 0.946575, `rotation3` = -0.322485 WHERE `guid` = 43689 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = -2297.153, `position_y` = -319.266, `position_z` = 4.262, `orientation` = 5.2644, `rotation2` = 0.487647, `rotation3` = -0.873041 WHERE `guid` = 43690 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = -2283.186, `position_y` = -319.773, `position_z` = 4.262, `orientation` = 3.7634, `rotation2` = 0.952058, `rotation3` = -0.305919 WHERE `guid` = 43691 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = -2298.804, `position_y` = -320.495, `position_z` = 4.262, `orientation` = 5.3342, `rotation2` = 0.456887, `rotation3` = -0.889525 WHERE `guid` = 43692 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = -2303.974, `position_y` = -324.222, `position_z` = 4.262, `orientation` = 5.2644, `rotation2` = 0.487647, `rotation3` = -0.873041 WHERE `guid` = 43693 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = -2282.142, `position_y` = -325.172, `position_z` = 4.262, `orientation` = 2.8559, `rotation2` = 0.989815, `rotation3` = 0.142361 WHERE `guid` = 43694 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = -2305.168, `position_y` = -325.905, `position_z` = 4.262, `orientation` = 5.8753, `rotation2` = 0.202532, `rotation3` = -0.979276 WHERE `guid` = 43695 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = -2283.527, `position_y` = -326.837, `position_z` = 4.262, `orientation` = 5.4739, `rotation2` = 0.39369, `rotation3` = -0.919243 WHERE `guid` = 43696 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = -2289.198, `position_y` = -330.71, `position_z` = 4.262, `orientation` = 2.2101, `rotation2` = 0.893487, `rotation3` = 0.44909 WHERE `guid` = 43697 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = -2291.009, `position_y` = -332.12, `position_z` = 4.262, `orientation` = 2.2276, `rotation2` = 0.897382, `rotation3` = 0.441255 WHERE `guid` = 43698 AND `id` = 179968;
UPDATE `gameobject` SET `position_x` = -2269.945, `position_y` = -295.046, `position_z` = 8.338, `orientation` = 4.5488, `rotation2` = 0.762516, `rotation3` = -0.64697 WHERE `guid` = 44808 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2269.945, `position_y` = -295.046, `position_z` = 4.655, `orientation` = 4.5488, `rotation2` = 0.762516, `rotation3` = -0.64697 WHERE `guid` = 44810 AND `id` = 188215;
UPDATE `gameobject` SET `position_x` = -2287.729, `position_y` = -290.841, `position_z` = 4.262, `orientation` = 5.0375, `rotation2` = 0.583346, `rotation3` = -0.812223 WHERE `guid` = 78461 AND `id` = 181355;
UPDATE `gameobject` SET `position_x` = -2294.137, `position_y` = -299.942, `position_z` = 4.262, `orientation` = 6.2244, `rotation2` = 0.029388, `rotation3` = -0.999568 WHERE `guid` = 78462 AND `id` = 181355;
UPDATE `gameobject` SET `position_x` = -2295.236, `position_y` = -291.874, `position_z` = 14.032, `orientation` = 5.7008, `rotation2` = 0.287095, `rotation3` = -0.957902 WHERE `guid` = 79337 AND `id` = 181401;
UPDATE `gameobject` SET `position_x` = -2306.71, `position_y` = -250.817, `position_z` = 4.262, `orientation` = 5.1002, `rotation2` = 0.557601, `rotation3` = -0.830109 WHERE `guid` = 152090 AND `id` = 113772;
UPDATE `gameobject` SET `position_x` = -2295.241, `position_y` = -265.672, `position_z` = 4.551, `orientation` = 2.5437, `rotation2` = 0.955647, `rotation3` = 0.294513 WHERE `guid` = 152091 AND `id` = 113768;
UPDATE `gameobject` SET `position_x` = -2341.394, `position_y` = -255.669, `position_z` = 4.262, `orientation` = 5.0806, `rotation2` = 0.565709, `rotation3` = -0.824605 WHERE `guid` = 152094 AND `id` = 113771;

-- Pilgrim's Bounty rows that transform A leaves in CoA's new ground or windbreak south of the tent.
-- Bountiful Table (52747): transform A x and y; re-floored on the rising ground south of the tent.
UPDATE `creature` SET `position_x` = -2298.379, `position_y` = -331.151, `position_z` = 4.863, `orientation` = 1.5818 WHERE `guid` = 52747 AND `id` = 32823;

-- [DND] Collision Thanksgiving Table Size (3355): under its table; re-floored with it.
UPDATE `gameobject` SET `position_x` = -2298.379, `position_y` = -331.151, `position_z` = 4.783, `orientation` = 1.5818, `rotation2` = 0.710986, `rotation3` = 0.703206 WHERE `guid` = 3355 AND `id` = 195664;
-- Haystack 01 (43699): transform A x and y; re-floored.
UPDATE `gameobject` SET `position_x` = -2305.151, `position_y` = -332.565, `position_z` = 4.871, `orientation` = 0.552, `rotation2` = 0.272509, `rotation3` = 0.962153 WHERE `guid` = 43699 AND `id` = 179968;
-- Pumpkin (19111): on haystack 43699.
UPDATE `gameobject` SET `position_x` = -2305.122, `position_y` = -332.655, `position_z` = 5.547, `orientation` = 0.552, `rotation2` = 0.272509, `rotation3` = 0.962153 WHERE `guid` = 19111 AND `id` = 195164;
-- Haystack 01 (43700): transform A x and y; re-floored.
UPDATE `gameobject` SET `position_x` = -2303.856, `position_y` = -334.601, `position_z` = 5.055, `orientation` = 0.5869, `rotation2` = 0.289256, `rotation3` = 0.957252 WHERE `guid` = 43700 AND `id` = 179968;
-- Pumpkin (19112): on haystack 43700.
UPDATE `gameobject` SET `position_x` = -2303.712, `position_y` = -334.739, `position_z` = 5.731, `orientation` = 0.6044, `rotation2` = 0.297621, `rotation3` = 0.954684 WHERE `guid` = 19112 AND `id` = 195164;
-- Freestanding Torch 01 (16352): transform A x and y; re-floored.
UPDATE `gameobject` SET `position_x` = -2304.53, `position_y` = -333.548, `position_z` = 5.015, `orientation` = 1.5818, `rotation2` = 0.710986, `rotation3` = 0.703206 WHERE `guid` = 16352 AND `id` = 180353;
-- Haystack 01 (43701): transform A put it inside CoA's new windbreak; open ground at the table's south-east
-- corner.
UPDATE `gameobject` SET `position_x` = -2294.5, `position_y` = -334, `position_z` = 4.528, `orientation` = 2.2101, `rotation2` = 0.893487, `rotation3` = 0.44909 WHERE `guid` = 43701 AND `id` = 179968;
-- Pumpkin (19113): on haystack 43701.
UPDATE `gameobject` SET `position_x` = -2294.456, `position_y` = -333.91, `position_z` = 5.204, `orientation` = 2.245, `rotation2` = 0.901187, `rotation3` = 0.433431 WHERE `guid` = 19113 AND `id` = 195164;
-- Haystack 01 (43702): transform A put it inside CoA's new windbreak; open ground at the table's south-west
-- corner, 3 yd clear.
UPDATE `gameobject` SET `position_x` = -2300.5, `position_y` = -335.5, `position_z` = 4.938, `orientation` = 1.6516, `rotation2` = 0.73509, `rotation3` = 0.677969 WHERE `guid` = 43702 AND `id` = 179968;
-- Pumpkin (19114): on haystack 43702.
UPDATE `gameobject` SET `position_x` = -2300.455, `position_y` = -335.529, `position_z` = 5.614, `orientation` = 1.6516, `rotation2` = 0.73509, `rotation3` = 0.677969 WHERE `guid` = 19114 AND `id` = 195164;
-- Freestanding Torch 01 (16353): transform A put it inside CoA's new windbreak; between the two south seats.
UPDATE `gameobject` SET `position_x` = -2296.5, `position_y` = -333.5, `position_z` = 4.747, `orientation` = 1.5818, `rotation2` = 0.710986, `rotation3` = 0.703206 WHERE `guid` = 16353 AND `id` = 180353;

-- Chicken hut rows (rotate +0.10914 rad about (-2341.08, -309.47), translate to (-2335.67, -311.84), z onto the
-- CoA floor).
UPDATE `gameobject` SET `position_x` = -2332.975, `position_y` = -321.283, `position_z` = 4.214, `orientation` = 1.453, `rotation2` = 0.664257, `rotation3` = 0.747504 WHERE `guid` = 36385 AND `id` = 180405;
UPDATE `gameobject` SET `position_x` = -2345.272, `position_y` = -309.039, `position_z` = 4.157, `orientation` = 4.9902, `rotation2` = 0.602391, `rotation3` = -0.798201 WHERE `guid` = 152099 AND `id` = 113771;
UPDATE `gameobject` SET `position_x` = -2334.78, `position_y` = -319.775, `position_z` = 4.198, `orientation` = 4.6721, `rotation2` = 0.721207, `rotation3` = -0.69272 WHERE `guid` = 152109 AND `id` = 113771;

-- Brightly Colored Egg (152095): under the raised plateau; same x and y.
UPDATE `gameobject` SET `position_x` = -2250.85, `position_y` = -256.279, `position_z` = 4.458 WHERE `guid` = 152095 AND `id` = 113772;
-- Brightly Colored Egg (152096): under the raised plateau; same x and y.
UPDATE `gameobject` SET `position_x` = -2282.03, `position_y` = -257.974, `position_z` = 4.513 WHERE `guid` = 152096 AND `id` = 113768;
-- Brightly Colored Egg (152097): under the raised plateau; same x and y.
UPDATE `gameobject` SET `position_x` = -2318.96, `position_y` = -265.509, `position_z` = 4.295 WHERE `guid` = 152097 AND `id` = 113769;
-- Brightly Colored Egg (152098): under the raised plateau; same x and y.
UPDATE `gameobject` SET `position_x` = -2334.42, `position_y` = -275.734, `position_z` = 4.293 WHERE `guid` = 152098 AND `id` = 113770;
-- Brightly Colored Egg (152111): inside the root of CoA's new Mullgoretree01; 1.1 yd to the open side of the same tree nook.
UPDATE `gameobject` SET `position_x` = -2295.8, `position_y` = -386.6, `position_z` = -9.022 WHERE `guid` = 152111 AND `id` = 113768;
-- Arena Tournament rows: sunk 0.36 yd into CoA's reshaped ground by Stonefather's Circle; same x and y.
UPDATE `creature` SET `position_x` = -2035.25, `position_y` = -323.459, `position_z` = -8.43 WHERE `guid` = 95501 AND `id` = 26007;
UPDATE `gameobject` SET `position_x` = -2035.25, `position_y` = -323.459, `position_z` = -8.43 WHERE `guid` = 45077 AND `id` = 188215;
-- Elder Bloodhoof (70572): QuestSuperTrack 377 (8673).
UPDATE `creature` SET `position_x` = -2104.57, `position_y` = -446.089, `position_z` = -8.08, `orientation` = 1.44862 WHERE `guid` = 70572 AND `id` = 15575;
-- Spring Gatherer (244808): QuestSuperTrack 8910 (13483) at the inn front; faces the village like Skorn
-- Whitecloud beside it.
UPDATE `creature` SET `position_x` = -2336.63, `position_y` = -355.656, `position_z` = -8.748, `orientation` = 5.0091 WHERE `guid` = 244808 AND `id` = 32798;
-- Mulgore Flame Keeper (245692): QuestSuperTrack 896 (11852), under the Midsummer pavilion.
UPDATE `creature` SET `position_x` = -2321.77, `position_y` = -614.483, `position_z` = -9.271, `orientation` = 5.67232 WHERE `guid` = 245692 AND `id` = 25936;
-- Noblegarden Merchant (244812): QuestSuperTrack 8911 (13503) at the inn front (the Exiles spawn agrees); faces
-- the village.
UPDATE `creature` SET `position_x` = -2343.08, `position_y` = -364.618, `position_z` = -8.406, `orientation` = 5.0091 WHERE `guid` = 244812 AND `id` = 32837;
