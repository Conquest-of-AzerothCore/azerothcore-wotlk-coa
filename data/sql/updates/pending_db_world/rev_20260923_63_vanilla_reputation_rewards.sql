-- Classic+: vanilla 1.12 quest and kill reputation (source: vmangos world, final 1.12 rows).
-- Only rows still equal to stock ACDB change, for the same quest or creature (same ID and name)
-- that is not level 61+ content. CoA package, migration and Ascension-imported rows are kept.

-- reputation_reward_rate: vanilla has no per-faction multipliers.
UPDATE `reputation_reward_rate` SET `quest_rate` = 1, `quest_daily_rate` = 1, `quest_repeatable_rate` = 1
WHERE `faction` = 576 AND `quest_rate` = 4 AND `quest_daily_rate` = 4 AND `quest_repeatable_rate` = 4;
UPDATE `reputation_reward_rate` SET `spell_rate` = 1 WHERE `faction` IN (529, 609) AND `spell_rate` = 2;

-- quest_template: override = vanilla RewRepValue * 100 (Player::RewardReputation divides it by 100
-- and prefers it over the WotLK QuestFactionReward index). Each slot is guarded by its stock values.
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 21 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
201, 210, 603, 620, 668, 8552);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 21 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
595, 597, 607, 627, 703);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 21 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
614, 8551);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 21 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
189, 209, 213, 351, 485, 575, 577, 578, 580, 587, 600, 601, 604, 605, 609, 610, 617, 621, 628, 662, 664, 665, 669, 670,
1182, 2766);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 21 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
705, 2418);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 21 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
576, 608, 611, 613, 623, 648, 666, 667, 836, 2767, 3601, 5534);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 21 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
4981);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 21 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
348, 618, 3721, 8554);
UPDATE `quest_template` SET `RewardFactionOverride1` = 80000
WHERE `RewardFactionID1` = 21 AND `RewardFactionValue1` = 8 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8857);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 47 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
250, 280, 291, 301, 305, 322, 413, 419, 472, 514, 683, 686, 720, 725, 730, 738, 971, 1339, 1453, 1455, 2990, 3106, 3107,
3108, 3109, 3110, 3364, 3449, 6391, 7806);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 47 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
233, 234, 282, 287, 319, 324, 414, 417, 420, 432, 433, 455, 465, 526, 690, 708, 718, 723, 726, 729, 741, 1457, 1469,
8835);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 47 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
17, 161, 167, 168, 170, 179, 182, 183, 199, 224, 237, 256, 263, 267, 278, 294, 295, 297, 299, 303, 309, 311, 312, 313,
314, 315, 353, 384, 385, 416, 418, 464, 466, 474, 554, 631, 632, 633, 637, 689, 693, 696, 700, 704, 706, 719, 721, 722,
724, 733, 739, 942, 1138, 1141, 1338, 1360, 1448, 1454, 1456, 1458, 1459, 1466, 1467, 1578, 1599, 2078, 2098, 2500,
2501, 2946, 2948, 2964, 3182, 3201, 3361, 3365, 3367, 3368, 3371, 3372, 3701, 3823, 3824, 3825, 4283, 4864, 5541);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 47 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
255, 304, 3181);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 47 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
217, 218, 283, 296, 307, 317, 320, 470, 647, 731, 762, 943, 2279, 6392, 7637, 7802, 7803, 7804, 7805);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 47 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
4286, 4341, 7642);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 47 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
378, 1050, 2240, 2991, 4362);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 47 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1139, 1475, 3461, 3566, 7063);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 54 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1072, 1074, 1075, 1077, 1579, 3112, 3113, 3114, 3115, 7812);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 54 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
2199, 8839);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 54 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
412, 983, 1002, 1003, 1071, 1073, 1076, 1078, 1179, 1580, 2038, 4262);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 54 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1001, 1079, 1080, 2922, 4512, 4513, 7807, 7808, 7809, 7811);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 54 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
2200);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 54 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
2926, 2929, 4263);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 54 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
2924);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 54 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
2361, 2930);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 59 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
6642);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 59 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
7652, 7653, 7655, 7659, 7701, 7704, 7722, 7723, 7724, 7727, 7728, 7729);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 59 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
6645, 7654);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 59 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
6643, 6644, 6646, 7656, 7657, 7658);
UPDATE `quest_template` SET `RewardFactionOverride1` = 80000
WHERE `RewardFactionID1` = 59 AND `RewardFactionValue1` = 8 AND `RewardFactionOverride1` = 0 AND `ID` IN (
7604, 8858);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 67 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
910, 911, 1800, 7732, 8619, 8635, 8636, 8642, 8643, 8644, 8645, 8646, 8647, 8648, 8649, 8650, 8651, 8652, 8653, 8654,
8670, 8671, 8672, 8673, 8674, 8675, 8676, 8677, 8679, 8680, 8681, 8682, 8683, 8684, 8685, 8686, 8688, 8713, 8714, 8715,
8716, 8717, 8718, 8719, 8720, 8721, 8722, 8723, 8724, 8725, 8726, 8727, 8866);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 67 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
915, 925);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 67 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
7730, 8312, 8409);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 67 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
105, 1488, 7667, 7731);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 67 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
7489);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 67 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1394, 4004, 4511, 5502, 7668, 8150, 8258);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 68 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
243, 360, 362, 366, 429, 440, 441, 448, 449, 460, 461, 494, 513, 517, 590, 1159, 1480, 2782, 3095, 3096, 3097, 3098,
3099, 3568, 5230, 5232, 5234, 5236, 5481, 6147, 6323, 7819, 8273);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 68 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
356, 357, 361, 379, 383, 404, 409, 425, 430, 438, 445, 478, 493, 502, 516, 545, 853, 1067, 1391, 8833);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 68 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1470);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 68 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
354, 358, 365, 367, 368, 370, 371, 372, 374, 375, 376, 380, 381, 398, 408, 411, 421, 422, 423, 424, 427, 435, 437, 443,
447, 477, 479, 480, 492, 499, 501, 509, 518, 519, 521, 527, 528, 529, 530, 532, 539, 541, 549, 550, 552, 556, 557, 566,
567, 654, 848, 1066, 1164, 1358, 1434, 1435, 1481, 1482, 2342, 2933, 2934, 2995, 3570, 3901, 3911, 4293, 4294, 4505,
4506, 5049, 5096, 5098, 5231, 5233, 5235, 5482, 6022, 6042, 6133, 6135, 6136, 6145, 6395, 7321, 8458);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 68 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
99, 450, 452, 962);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 68 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
364, 442);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 68 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
426, 491, 515, 520, 544, 546, 547, 553, 864, 1086, 1383, 1657, 3902, 4642, 6148, 6324, 7813, 7814, 7817, 7818);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 68 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1160);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 68 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1013, 1098, 4061, 6163, 7201);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 68 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1051, 1109, 1113, 3341, 4768, 5725);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 68 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
382, 451, 524, 1014, 1048, 2937, 2938, 5511);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 69 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
458, 475, 922, 927, 928, 937, 940, 944, 948, 965, 979, 993, 995, 997, 1010, 1024, 1039, 1056, 1070, 1082, 2867, 3116,
3117, 3118, 3119, 3120, 3803, 3842, 4722, 4723, 4725, 4727, 4728, 4730, 4731, 4732, 4733, 4811, 4812, 6342, 7801);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 69 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
921, 934, 950, 954, 957, 963, 967, 984, 1007, 1023, 1028, 1030, 1437, 1465, 2438, 2866, 2869, 2870, 2943, 2969, 2970,
3524, 3765, 4125, 4131, 4135, 4183, 4281, 4495, 4762, 4901, 7383, 8819, 8831);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 69 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
456, 457, 459, 476, 483, 487, 916, 918, 929, 930, 931, 932, 933, 938, 941, 945, 947, 949, 952, 953, 955, 956, 958, 966,
970, 973, 978, 981, 982, 985, 986, 991, 994, 1008, 1011, 1016, 1021, 1022, 1025, 1026, 1027, 1031, 1032, 1033, 1034,
1045, 1054, 1057, 1059, 1083, 1084, 1134, 1140, 1143, 1438, 1439, 1581, 1582, 2118, 2138, 2139, 2178, 2520, 2541, 2741,
2821, 2871, 2879, 2942, 2944, 2982, 3370, 3521, 3661, 3764, 3785, 3791, 3843, 4161, 4182, 4265, 4297, 4681, 4813, 4986,
5321, 5713, 7733, 7735);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 69 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1275, 2499);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 69 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
486, 917, 919, 923, 935, 951, 968, 1009, 1012, 1017, 1020, 1035, 1044, 1046, 1440, 2459, 2518, 2561, 2972, 3378, 3522,
4261, 4740, 4763, 6343, 7799, 7800);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 69 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
4701);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 69 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1142);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 69 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
489, 976);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 72 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
35, 36, 45, 54, 67, 74, 75, 93, 95, 112, 119, 120, 132, 135, 143, 164, 165, 173, 198, 215, 230, 240, 270, 285, 290, 292,
328, 329, 333, 347, 373, 453, 469, 510, 511, 525, 602, 659, 783, 1041, 1052, 1249, 1264, 1447, 3100, 3101, 3102, 3103,
3104, 3105, 3904, 5022, 5217, 5220, 5223, 5226, 5261, 6281, 7639, 7646, 7796);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 72 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
6, 52, 56, 60, 62, 68, 70, 86, 109, 124, 125, 127, 145, 177, 178, 184, 200, 203, 221, 222, 226, 228, 245, 246, 286, 289,
332, 334, 337, 434, 505, 1324, 1395, 1425, 4184, 8837);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 72 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
248);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 72 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
7, 9, 11, 12, 13, 15, 18, 20, 21, 22, 33, 34, 38, 46, 47, 57, 58, 64, 65, 76, 83, 88, 89, 90, 91, 92, 102, 116, 126,
128, 142, 147, 150, 151, 153, 174, 176, 181, 204, 205, 279, 293, 323, 331, 346, 399, 471, 484, 500, 504, 512, 523, 537,
555, 564, 565, 574, 622, 658, 660, 694, 732, 1043, 1204, 1220, 1222, 1364, 1396, 1398, 1421, 1598, 1618, 3741, 3905,
4186, 4242, 4264, 4765, 5002, 5048, 5092, 5097, 5216, 5219, 5222, 5225, 7640, 7648, 8860);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 72 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
19, 115, 249, 717);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 72 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
202);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 72 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
14, 39, 61, 87, 101, 114, 122, 155, 169, 180, 206, 207, 219, 223, 540, 542, 661, 691, 697, 1387, 6285, 7644, 7791, 7793,
7794, 7795, 7962);
UPDATE `quest_template` SET `RewardFactionOverride1` = 2500
WHERE `RewardFactionID1` = 72 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
4764);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 72 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
214, 377, 386, 391, 2040, 2928, 4241, 4282, 5089);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 72 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
387, 388, 3636, 4322, 5081, 7070);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 72 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
55, 98, 166, 212, 396, 543, 1053, 5505, 6187, 6403, 7495, 7496, 7647, 7781, 7782);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 76 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
785, 787, 805, 809, 822, 823, 829, 840, 1145, 1184, 1418, 1432, 2340, 2383, 2978, 3087, 3088, 3089, 3090, 3121, 3504,
4641, 4882, 5727, 6384, 7832);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 76 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
506, 832, 837, 850, 851, 852, 879, 1146, 1238, 1239, 1420, 2283, 2975, 3505, 3506, 4921, 5052, 8823, 8841);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 76 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
25, 77, 81, 216, 503, 533, 568, 569, 570, 571, 572, 640, 650, 672, 677, 678, 679, 698, 699, 701, 782, 784, 786, 788,
789, 790, 791, 806, 808, 815, 816, 817, 818, 819, 825, 826, 827, 830, 831, 834, 835, 842, 844, 845, 847, 862, 867, 869,
871, 872, 875, 878, 893, 903, 905, 1062, 1068, 1147, 1153, 1201, 1202, 1261, 1262, 1419, 1427, 1428, 1430, 1436, 2950,
2973, 2974, 2979, 2980, 2987, 3281, 3822, 4521, 4721, 4741, 4941, 4983, 5041, 5726, 6162, 6504);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 76 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
498, 508, 573, 680, 792, 793, 812, 821, 855, 876, 881, 899, 924, 1365, 1366, 1424, 1426, 1444, 2976, 3507, 3513, 3514,
4001, 4021, 4121, 5441, 5730, 6386, 6394, 6543, 6544, 6571, 7541, 7824, 7826, 7827, 7831);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 76 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
2284);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 76 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
2841, 3981, 3982, 4081, 4082, 4724, 5728);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 76 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1445, 4132, 4903);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 76 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
794, 906, 4402, 4974, 7490, 7491, 7783, 7784);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 81 AND `RewardFactionValue1` = 0 AND `RewardFactionOverride1` = 0 AND `ID` IN (
914);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 81 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
752, 769, 775, 1149, 1152, 2902, 3091, 3092, 3093, 3094, 3804, 4865, 5881, 6362, 7825);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 81 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
749, 751, 763, 764, 772, 833, 870, 883, 884, 885, 1154, 2862, 2863, 3063, 4767, 5361, 5386, 6301, 6401, 8825, 8843);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 81 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
2, 23, 24, 743, 744, 745, 746, 747, 748, 750, 753, 754, 755, 756, 758, 759, 765, 766, 770, 771, 773, 781, 843, 846, 849,
861, 877, 880, 1065, 1131, 1150, 1197, 1205, 2822, 2903, 2966, 2968, 3301, 3369, 3761, 3786, 3906, 4120, 4770, 4821,
4841, 4881, 4883, 4904, 4966, 4987, 5064, 5088, 5147, 5381, 6282, 6283, 6284, 6381, 6421, 6481, 6548, 7734, 7738, 8861);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 81 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
247, 757, 760, 761, 768, 776, 780, 873, 882, 897, 907, 913, 1151, 1195, 2280, 3062, 5581, 6364, 6482, 7820, 7821, 7822,
7823);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 81 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
5723);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 81 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1049, 3907, 5724);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 81 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1102, 1136, 3376, 7061);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 83 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
5144, 5146);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 86 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
5141, 5145);
UPDATE `quest_template` SET `RewardFactionOverride1` = -50000
WHERE `RewardFactionID1` = 92 AND `RewardFactionValue1` = -5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1367);
UPDATE `quest_template` SET `RewardFactionOverride1` = -50000
WHERE `RewardFactionID1` = 93 AND `RewardFactionValue1` = -5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1368);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 93 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1385);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 169 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
4810, 5519, 6963);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 169 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
4726, 5518, 6984, 7045);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 169 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
5525, 7003, 7429, 7721);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 169 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
4734);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 169 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
4735, 8746, 8762);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 270 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8041, 8042, 8043, 8044, 8045, 8046, 8047, 8048, 8049, 8050, 8051, 8052, 8101, 8102, 8103, 8104, 8106, 8107, 8108, 8109,
8110, 8111, 8112, 8113, 8116, 8117, 8118, 8119, 8141, 8142, 8143, 8144, 8145, 8146, 8147, 8148, 8184, 8185, 8186, 8187,
8188, 8189, 8190, 8191, 8192);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 270 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8053, 8054, 8055, 8056, 8057, 8058, 8059, 8060, 8061, 8062, 8063, 8064, 8065, 8066, 8067, 8068, 8069, 8070, 8071, 8072,
8073, 8074, 8075, 8076, 8077, 8078, 8079, 8240);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 270 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8183, 8201, 9208, 9209, 9210);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 349 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8249);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 349 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
6681, 6701, 8234, 8235);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 349 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8236);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 369 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
82, 992, 1707);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 369 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
10, 1690, 1691, 2605, 2641, 2875, 3161, 3362, 4496, 4504, 5863, 8365, 8366);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 369 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
32, 162, 2781, 2876, 4450);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 369 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
2865);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 369 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
2768, 8585);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 469 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1393, 1479, 1558, 1687);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 469 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
558, 4822);
UPDATE `quest_template` SET `RewardFactionOverride1` = 2500
WHERE `RewardFactionID1` = 469 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
5247);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 469 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1658, 4902, 5253, 8311, 8373);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 469 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
211);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 469 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
7488);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 469 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
171, 253, 1081, 1267, 4266, 4510, 5102, 5237, 8149);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 470 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
900, 1094, 1095, 1190, 1194, 1492, 3921);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 470 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
887, 894, 901, 1092, 5501, 5561);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 470 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
858, 865, 866, 888, 891, 895, 902, 959, 1093, 1096, 1176, 1187, 1270, 3922, 4502, 5821, 5943, 6441);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 470 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
863, 896, 898, 1069, 1090, 3924);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 470 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1221, 1491);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 470 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1144);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 509 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8384, 8391, 8392, 8397, 8398);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 509 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8374, 8393, 8394, 8395, 8396);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 509 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8105, 8115, 8166, 8167, 8168);
UPDATE `quest_template` SET `RewardFactionOverride1` = 80000
WHERE `RewardFactionID1` = 509 AND `RewardFactionValue1` = 8 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8114);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 510 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8390, 8440, 8441, 8442, 8443);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 510 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8370, 8436, 8437, 8438, 8439);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 510 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8120, 8122, 8123, 8160, 8161, 8162, 8169, 8170, 8171, 8299);
UPDATE `quest_template` SET `RewardFactionOverride1` = 80000
WHERE `RewardFactionID1` = 510 AND `RewardFactionValue1` = 8 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8121);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 529 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
5210, 5582, 6028, 6029, 6030, 8416, 9085, 9153, 9178, 9179, 9181, 9182, 9183, 9184, 9185, 9186, 9187, 9188, 9190, 9191,
9194, 9195, 9196, 9197, 9198, 9200, 9201, 9202, 9204, 9205, 9206);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 529 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
5522, 6021);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 529 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
5181, 5206, 5264, 5504, 5507, 5513, 5741, 8414, 9211, 9213, 9221, 9222, 9223, 9224, 9225, 9226, 9227, 9228);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 529 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
5464, 5517, 5521, 5524, 6027);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 529 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
5212, 5213, 5243, 5529);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 529 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1198, 1199, 5251, 5262, 8418);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 529 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1200, 4771, 5265, 5942, 6561, 9033, 9034, 9036, 9037, 9038, 9039, 9040, 9041, 9042, 9043, 9044, 9045, 9046, 9047, 9048,
9049, 9050, 9054, 9055, 9056, 9057, 9058, 9059, 9060, 9061, 9068, 9069, 9071, 9072, 9073, 9074, 9075, 9077, 9078, 9079,
9080, 9081, 9082, 9083, 9084, 9089, 9090, 9091, 9092, 9093, 9095, 9096, 9097, 9098, 9099, 9100, 9101, 9102, 9104, 9106,
9107, 9108, 9109, 9111, 9112, 9113, 9114, 9115, 9116, 9117, 9118, 9121, 9122, 9123, 9124, 9126, 9128, 9131, 9136, 9141,
9229, 9230, 9232);
UPDATE `quest_template` SET `RewardFactionOverride1` = 80000
WHERE `RewardFactionID1` = 529 AND `RewardFactionValue1` = 8 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8859, 9120);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 530 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
3002, 3065, 3082, 3083, 3084, 3085, 3086, 7837);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 530 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
585, 2935, 6564, 8845);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 530 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
581, 582, 584, 586, 589, 596, 598, 629, 639, 643, 644, 671, 673, 676, 824, 868, 969, 1058, 1060, 1148, 1240, 2202, 2203,
2258, 2318, 2341, 2742, 2932, 3123, 3124, 3125, 3126, 3127, 3128, 3129, 3821, 4300, 6142, 6143, 6442, 6461, 6462, 6503,
6563);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 530 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
591);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 530 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
592, 646, 908, 909, 7833, 7834, 7835, 7836);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 530 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
2339);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 530 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
2936, 6565, 6921, 6922, 7068);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 549 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
5143, 5148);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 550 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
3639);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 551 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
3641, 3643);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 576 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8466, 8467, 8469);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 576 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
6241);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 576 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
6031, 6032, 6131);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 576 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8460, 8461, 8464, 8470, 8471);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 576 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8481);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 577 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
4808, 5083, 5123);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 577 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
977, 3783, 5084, 5085);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 577 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
4809, 4842, 5082, 5086, 5087, 5128);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 577 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
5121);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 577 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
5163);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 589 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
4970, 5201);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 589 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
5981);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 609 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1124, 1185, 5929, 5930, 6844, 8285, 8313, 8317, 8362, 8496, 8497, 8498, 8501, 8502, 8534, 8535, 8536, 8537, 8539, 8540,
8541, 8548, 8572, 8573, 8574, 8687, 8737, 8738, 8739, 8740, 8770, 8771, 8772, 8773, 8774, 8775, 8776, 8777, 8778, 8779,
8780, 8781, 8782, 8783, 8785, 8786, 8787, 8804, 8805, 8806, 8807, 8808, 8809, 8810, 8856, 8867);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 609 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
28, 29, 30, 272, 4984, 4985, 6122, 6123, 6124, 6127, 6128, 6129, 8277, 8280, 8314, 8332);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 609 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
1125, 1126, 5527, 6001, 6002, 6125, 6130, 8278, 8279, 8281, 8282, 8283, 8284, 8287, 8304, 8308, 8309, 8310, 8316, 8318,
8320, 8341, 8361, 8363, 8376, 8377, 8378, 8379, 8381, 8382, 8538, 8556, 8557, 8558, 8689, 8690, 8691, 8692, 8693, 8694,
8695, 8696, 8697, 8698, 8699, 8700, 8701, 8702, 8703, 8704, 8705, 8706, 8707, 8708, 8709, 8710, 8711, 8712, 8829, 8868,
9023, 9419, 9422);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 609 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
6845, 8321, 8348, 8364);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 609 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8306, 8315);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 609 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
5526, 7064, 7065, 7066);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 609 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8352, 8446, 8447, 8791, 8801, 8802, 9248, 9338);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 729 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
6847);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 729 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8387);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 729 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8369);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 730 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
6848);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 730 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8383);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 730 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8375);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 749 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
7486);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 809 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
7441, 7463, 7483, 7484, 7485, 7498, 7499, 7500, 7501, 7502, 7503, 7504, 7505, 7506, 7507, 7509, 7649, 7650, 7651);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 889 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8268, 8389, 8431, 8432, 8433, 8434, 8435);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 889 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8368, 8426, 8427, 8428, 8429, 8430);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 889 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
7789, 7874, 7875, 7876, 8294, 8295);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 890 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8266, 8386, 8404, 8405, 8406, 8407, 8408);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 890 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8372, 8399, 8400, 8401, 8402, 8403);
UPDATE `quest_template` SET `RewardFactionOverride1` = 12500
WHERE `RewardFactionID1` = 890 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
7788);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 890 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
7871, 7872, 7873, 8290, 8291);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 909 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
7905, 7926, 7937, 7938, 7944, 7945);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 909 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
7881, 7882, 7883, 7884, 7885, 7889, 7890, 7891, 7892, 7893, 7894, 7895, 7896, 7897, 7898, 7899, 7900, 7901, 7902, 7903,
8222);
UPDATE `quest_template` SET `RewardFactionOverride1` = 15000
WHERE `RewardFactionID1` = 909 AND `RewardFactionValue1` = 6 AND `RewardFactionOverride1` = 0 AND `ID` IN (
7907, 7927, 7928, 7929);
UPDATE `quest_template` SET `RewardFactionOverride1` = 5000
WHERE `RewardFactionID1` = 910 AND `RewardFactionValue1` = 3 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8305);
UPDATE `quest_template` SET `RewardFactionOverride1` = 7500
WHERE `RewardFactionID1` = 910 AND `RewardFactionValue1` = 4 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8620);
UPDATE `quest_template` SET `RewardFactionOverride1` = 10000
WHERE `RewardFactionID1` = 910 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8286, 8728, 8735, 8747, 8751, 8752, 8756, 8757, 8761);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 910 AND `RewardFactionValue1` = 5 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8519);
UPDATE `quest_template` SET `RewardFactionOverride1` = 20000
WHERE `RewardFactionID1` = 910 AND `RewardFactionValue1` = 7 AND `RewardFactionOverride1` = 0 AND `ID` IN (
8288, 8301, 8302, 8303, 8561, 8562, 8592, 8593, 8594, 8596, 8603, 8622, 8625, 8626, 8627, 8628, 8629, 8630, 8631, 8632,
8633, 8634, 8638, 8655, 8656, 8657, 8658, 8659, 8730, 8789, 8790, 9250, 9251, 9269);
UPDATE `quest_template` SET `RewardFactionOverride2` = -50000
WHERE `RewardFactionID2` = 21 AND `RewardFactionValue2` = -5 AND `RewardFactionOverride2` = 0 AND `ID` IN (
9272);
UPDATE `quest_template` SET `RewardFactionOverride2` = -12500
WHERE `RewardFactionID2` = 21 AND `RewardFactionValue2` = -2 AND `RewardFactionOverride2` = 0 AND `ID` IN (
1036);
UPDATE `quest_template` SET `RewardFactionOverride2` = 10000
WHERE `RewardFactionID2` = 47 AND `RewardFactionValue2` = 5 AND `RewardFactionOverride2` = 0 AND `ID` IN (
412);
UPDATE `quest_template` SET `RewardFactionOverride2` = 20000
WHERE `RewardFactionID2` = 47 AND `RewardFactionValue2` = 7 AND `RewardFactionOverride2` = 0 AND `ID` IN (
7781, 7782);
UPDATE `quest_template` SET `RewardFactionOverride2` = 5000
WHERE `RewardFactionID2` = 54 AND `RewardFactionValue2` = 3 AND `RewardFactionOverride2` = 0 AND `ID` IN (
291, 413, 419, 3364, 6391);
UPDATE `quest_template` SET `RewardFactionOverride2` = 7500
WHERE `RewardFactionID2` = 54 AND `RewardFactionValue2` = 4 AND `RewardFactionOverride2` = 0 AND `ID` IN (
233, 234, 282, 287, 319, 414, 417, 420, 432, 433);
UPDATE `quest_template` SET `RewardFactionOverride2` = 10000
WHERE `RewardFactionID2` = 54 AND `RewardFactionValue2` = 5 AND `RewardFactionOverride2` = 0 AND `ID` IN (
170, 179, 182, 183, 311, 312, 313, 314, 315, 384, 1599, 2948, 3361, 3365, 5541);
UPDATE `quest_template` SET `RewardFactionOverride2` = 15000
WHERE `RewardFactionID2` = 54 AND `RewardFactionValue2` = 6 AND `RewardFactionOverride2` = 0 AND `ID` IN (
317, 320, 6392);
UPDATE `quest_template` SET `RewardFactionOverride2` = 10000
WHERE `RewardFactionID2` = 54 AND `RewardFactionValue2` = 7 AND `RewardFactionOverride2` = 0 AND `ID` IN (
2040, 2928);
UPDATE `quest_template` SET `RewardFactionOverride2` = 20000
WHERE `RewardFactionID2` = 54 AND `RewardFactionValue2` = 7 AND `RewardFactionOverride2` = 0 AND `ID` IN (
218);
UPDATE `quest_template` SET `RewardFactionOverride2` = 5000
WHERE `RewardFactionID2` = 67 AND `RewardFactionValue2` = 3 AND `RewardFactionOverride2` = 0 AND `ID` IN (
891, 1393, 3922);
UPDATE `quest_template` SET `RewardFactionOverride2` = 7500
WHERE `RewardFactionID2` = 67 AND `RewardFactionValue2` = 4 AND `RewardFactionOverride2` = 0 AND `ID` IN (
3924);
UPDATE `quest_template` SET `RewardFactionOverride2` = 15000
WHERE `RewardFactionID2` = 67 AND `RewardFactionValue2` = 6 AND `RewardFactionOverride2` = 0 AND `ID` IN (
32);
UPDATE `quest_template` SET `RewardFactionOverride2` = 15000
WHERE `RewardFactionID2` = 69 AND `RewardFactionValue2` = 7 AND `RewardFactionOverride2` = 0 AND `ID` IN (
1198, 1199);
UPDATE `quest_template` SET `RewardFactionOverride2` = 20000
WHERE `RewardFactionID2` = 69 AND `RewardFactionValue2` = 7 AND `RewardFactionOverride2` = 0 AND `ID` IN (
1200);
UPDATE `quest_template` SET `RewardFactionOverride2` = -25000
WHERE `RewardFactionID2` = 70 AND `RewardFactionValue2` = -3 AND `RewardFactionOverride2` = 0 AND `ID` IN (
8249);
UPDATE `quest_template` SET `RewardFactionOverride2` = 5000
WHERE `RewardFactionID2` = 72 AND `RewardFactionValue2` = 3 AND `RewardFactionOverride2` = 0 AND `ID` IN (
1075);
UPDATE `quest_template` SET `RewardFactionOverride2` = 10000
WHERE `RewardFactionID2` = 72 AND `RewardFactionValue2` = 5 AND `RewardFactionOverride2` = 0 AND `ID` IN (
1076, 1078);
UPDATE `quest_template` SET `RewardFactionOverride2` = 10000
WHERE `RewardFactionID2` = 81 AND `RewardFactionValue2` = 5 AND `RewardFactionOverride2` = 0 AND `ID` IN (
2741);
UPDATE `quest_template` SET `RewardFactionOverride2` = 20000
WHERE `RewardFactionID2` = 81 AND `RewardFactionValue2` = 7 AND `RewardFactionOverride2` = 0 AND `ID` IN (
6561);
UPDATE `quest_template` SET `RewardFactionOverride2` = -100000
WHERE `RewardFactionID2` = 87 AND `RewardFactionValue2` = -7 AND `RewardFactionOverride2` = 0 AND `ID` IN (
348, 618, 3721, 8554);
UPDATE `quest_template` SET `RewardFactionOverride2` = -75000
WHERE `RewardFactionID2` = 87 AND `RewardFactionValue2` = -6 AND `RewardFactionOverride2` = 0 AND `ID` IN (
576, 608, 611, 613, 623, 648, 666, 667, 836, 2767, 3601, 5534);
UPDATE `quest_template` SET `RewardFactionOverride2` = -75000
WHERE `RewardFactionID2` = 87 AND `RewardFactionValue2` = -5 AND `RewardFactionOverride2` = 0 AND `ID` IN (
705, 2418);
UPDATE `quest_template` SET `RewardFactionOverride2` = -50000
WHERE `RewardFactionID2` = 87 AND `RewardFactionValue2` = -5 AND `RewardFactionOverride2` = 0 AND `ID` IN (
189, 209, 213, 351, 485, 575, 577, 578, 580, 587, 600, 601, 604, 605, 609, 610, 617, 621, 628, 662, 664, 665, 669, 670,
1182, 2766);
UPDATE `quest_template` SET `RewardFactionOverride2` = -37500
WHERE `RewardFactionID2` = 87 AND `RewardFactionValue2` = -5 AND `RewardFactionOverride2` = 0 AND `ID` IN (
614, 8551);
UPDATE `quest_template` SET `RewardFactionOverride2` = -37500
WHERE `RewardFactionID2` = 87 AND `RewardFactionValue2` = -4 AND `RewardFactionOverride2` = 0 AND `ID` IN (
595, 597, 607, 627, 703);
UPDATE `quest_template` SET `RewardFactionOverride2` = -25000
WHERE `RewardFactionID2` = 87 AND `RewardFactionValue2` = -3 AND `RewardFactionOverride2` = 0 AND `ID` IN (
201, 210, 603, 620, 668, 8552);
UPDATE `quest_template` SET `RewardFactionOverride2` = -12500
WHERE `RewardFactionID2` = 87 AND `RewardFactionValue2` = -2 AND `RewardFactionOverride2` = 0 AND `ID` IN (
599, 606, 663);
UPDATE `quest_template` SET `RewardFactionOverride2` = 10000
WHERE `RewardFactionID2` = 92 AND `RewardFactionValue2` = 5 AND `RewardFactionOverride2` = 0 AND `ID` IN (
1368, 1382);
UPDATE `quest_template` SET `RewardFactionOverride2` = 10000
WHERE `RewardFactionID2` = 93 AND `RewardFactionValue2` = 5 AND `RewardFactionOverride2` = 0 AND `ID` IN (
1367);
UPDATE `quest_template` SET `RewardFactionOverride2` = 7500
WHERE `RewardFactionID2` = 369 AND `RewardFactionValue2` = 4 AND `RewardFactionOverride2` = 0 AND `ID` IN (
379);
UPDATE `quest_template` SET `RewardFactionOverride2` = 5000
WHERE `RewardFactionID2` = 469 AND `RewardFactionValue2` = 3 AND `RewardFactionOverride2` = 0 AND `ID` IN (
8619, 8635, 8636, 8642, 8643, 8644, 8645, 8646, 8647, 8648, 8649, 8650, 8651, 8652, 8653, 8654, 8670, 8671, 8672, 8673,
8674, 8675, 8676, 8677, 8679, 8680, 8681, 8682, 8683, 8684, 8685, 8686, 8688, 8713, 8714, 8715, 8716, 8717, 8718, 8719,
8720, 8721, 8722, 8723, 8724, 8725, 8726, 8727, 8866);
UPDATE `quest_template` SET `RewardFactionOverride2` = 15000
WHERE `RewardFactionID2` = 469 AND `RewardFactionValue2` = 6 AND `RewardFactionOverride2` = 0 AND `ID` IN (
162);
UPDATE `quest_template` SET `RewardFactionOverride2` = 5000
WHERE `RewardFactionID2` = 529 AND `RewardFactionValue2` = 3 AND `RewardFactionOverride2` = 0 AND `ID` IN (
5217, 5220, 5223, 5226, 5230, 5232, 5234, 5236);
UPDATE `quest_template` SET `RewardFactionOverride2` = 10000
WHERE `RewardFactionID2` = 529 AND `RewardFactionValue2` = 5 AND `RewardFactionOverride2` = 0 AND `ID` IN (
5216, 5219, 5222, 5225, 5231, 5233, 5235);
UPDATE `quest_template` SET `RewardFactionOverride2` = 15000
WHERE `RewardFactionID2` = 529 AND `RewardFactionValue2` = 6 AND `RewardFactionOverride2` = 0 AND `ID` IN (
105, 211);
UPDATE `quest_template` SET `RewardFactionOverride2` = 20000
WHERE `RewardFactionID2` = 529 AND `RewardFactionValue2` = 7 AND `RewardFactionOverride2` = 0 AND `ID` IN (
5237, 9250, 9251, 9269);
UPDATE `quest_template` SET `RewardFactionOverride2` = 5000
WHERE `RewardFactionID2` = 530 AND `RewardFactionValue2` = 3 AND `RewardFactionOverride2` = 0 AND `ID` IN (
785, 787, 805, 809, 823, 829, 840, 4641, 6384);
UPDATE `quest_template` SET `RewardFactionOverride2` = 7500
WHERE `RewardFactionID2` = 530 AND `RewardFactionValue2` = 4 AND `RewardFactionOverride2` = 0 AND `ID` IN (
832, 837);
UPDATE `quest_template` SET `RewardFactionOverride2` = 10000
WHERE `RewardFactionID2` = 530 AND `RewardFactionValue2` = 5 AND `RewardFactionOverride2` = 0 AND `ID` IN (
784, 786, 788, 789, 790, 791, 806, 808, 815, 816, 817, 818, 825, 826, 827, 830, 831, 834, 835, 842);
UPDATE `quest_template` SET `RewardFactionOverride2` = 15000
WHERE `RewardFactionID2` = 530 AND `RewardFactionValue2` = 6 AND `RewardFactionOverride2` = 0 AND `ID` IN (
792, 812, 5441, 6386, 6394);
UPDATE `quest_template` SET `RewardFactionOverride2` = 20000
WHERE `RewardFactionID2` = 530 AND `RewardFactionValue2` = 7 AND `RewardFactionOverride2` = 0 AND `ID` IN (
794, 4402, 4974, 7783, 7784);
UPDATE `quest_template` SET `RewardFactionOverride2` = 5000
WHERE `RewardFactionID2` = 577 AND `RewardFactionValue2` = 3 AND `RewardFactionOverride2` = 0 AND `ID` IN (
6028, 6029, 6030);
UPDATE `quest_template` SET `RewardFactionOverride2` = 10000
WHERE `RewardFactionID2` = 609 AND `RewardFactionValue2` = 5 AND `RewardFactionOverride2` = 0 AND `ID` IN (
8735);
UPDATE `quest_template` SET `RewardFactionOverride2` = 15000
WHERE `RewardFactionID2` = 609 AND `RewardFactionValue2` = 5 AND `RewardFactionOverride2` = 0 AND `ID` IN (
8734);
UPDATE `quest_template` SET `RewardFactionOverride2` = 20000
WHERE `RewardFactionID2` = 889 AND `RewardFactionValue2` = 7 AND `RewardFactionOverride2` = 0 AND `ID` IN (
7789, 7874, 7875, 7876, 8294, 8295);
UPDATE `quest_template` SET `RewardFactionOverride2` = 12500
WHERE `RewardFactionID2` = 890 AND `RewardFactionValue2` = 7 AND `RewardFactionOverride2` = 0 AND `ID` IN (
7788);
UPDATE `quest_template` SET `RewardFactionOverride2` = 20000
WHERE `RewardFactionID2` = 890 AND `RewardFactionValue2` = 7 AND `RewardFactionOverride2` = 0 AND `ID` IN (
7871, 7872, 7873, 8291);
UPDATE `quest_template` SET `RewardFactionOverride2` = 20000
WHERE `RewardFactionID2` = 910 AND `RewardFactionValue2` = 7 AND `RewardFactionOverride2` = 0 AND `ID` IN (
8791, 8801);
UPDATE `quest_template` SET `RewardFactionOverride3` = 20000
WHERE `RewardFactionID3` = 68 AND `RewardFactionValue3` = 7 AND `RewardFactionOverride3` = 0 AND `ID` IN (
4974);
UPDATE `quest_template` SET `RewardFactionOverride3` = 20000
WHERE `RewardFactionID3` = 69 AND `RewardFactionValue3` = 7 AND `RewardFactionOverride3` = 0 AND `ID` IN (
7781, 7782);
UPDATE `quest_template` SET `RewardFactionOverride3` = 20000
WHERE `RewardFactionID3` = 81 AND `RewardFactionValue3` = 7 AND `RewardFactionOverride3` = 0 AND `ID` IN (
7783, 7784);
UPDATE `quest_template` SET `RewardFactionOverride3` = -12500
WHERE `RewardFactionID3` = 87 AND `RewardFactionValue3` = -2 AND `RewardFactionOverride3` = 0 AND `ID` IN (
1180);
UPDATE `quest_template` SET `RewardFactionOverride3` = 10000
WHERE `RewardFactionID3` = 470 AND `RewardFactionValue3` = 5 AND `RewardFactionOverride3` = 0 AND `ID` IN (
834, 835);
UPDATE `quest_template` SET `RewardFactionOverride3` = 20000
WHERE `RewardFactionID3` = 889 AND `RewardFactionValue3` = 7 AND `RewardFactionOverride3` = 0 AND `ID` IN (
7789, 7874, 7875, 7876, 8294, 8295);
UPDATE `quest_template` SET `RewardFactionOverride3` = 12500
WHERE `RewardFactionID3` = 890 AND `RewardFactionValue3` = 7 AND `RewardFactionOverride3` = 0 AND `ID` IN (
7788);
UPDATE `quest_template` SET `RewardFactionOverride3` = 20000
WHERE `RewardFactionID3` = 890 AND `RewardFactionValue3` = 7 AND `RewardFactionOverride3` = 0 AND `ID` IN (
7871, 7872, 7873, 8291);
UPDATE `quest_template` SET `RewardFactionOverride4` = 20000
WHERE `RewardFactionID4` = 54 AND `RewardFactionValue4` = 7 AND `RewardFactionOverride4` = 0 AND `ID` IN (
7781, 7782);
UPDATE `quest_template` SET `RewardFactionOverride4` = 20000
WHERE `RewardFactionID4` = 68 AND `RewardFactionValue4` = 7 AND `RewardFactionOverride4` = 0 AND `ID` IN (
7783, 7784);
UPDATE `quest_template` SET `RewardFactionOverride4` = 20000
WHERE `RewardFactionID4` = 81 AND `RewardFactionValue4` = 7 AND `RewardFactionOverride4` = 0 AND `ID` IN (
4974);
UPDATE `quest_template` SET `RewardFactionOverride4` = 20000
WHERE `RewardFactionID4` = 889 AND `RewardFactionValue4` = 7 AND `RewardFactionOverride4` = 0 AND `ID` IN (
7789, 7874, 7875, 7876, 8294, 8295);
UPDATE `quest_template` SET `RewardFactionOverride4` = 12500
WHERE `RewardFactionID4` = 890 AND `RewardFactionValue4` = 7 AND `RewardFactionOverride4` = 0 AND `ID` IN (
7788);
UPDATE `quest_template` SET `RewardFactionOverride4` = 20000
WHERE `RewardFactionID4` = 890 AND `RewardFactionValue4` = 7 AND `RewardFactionOverride4` = 0 AND `ID` IN (
7871, 7872, 7873, 8291);

-- creature_onkill_reputation: vanilla kill value and standing cap for Argent Dawn (529),
-- Timbermaw Hold (576) and Cenarion Circle (609). Each row is guarded by its stock values.
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 5, `MaxStanding1` = 4
WHERE `RewOnKillRepFaction1` = 529 AND `RewOnKillRepValue1` = 10 AND `MaxStanding1` = 4 AND `creature_id` IN (
1783, 1784, 1785, 1787, 1789, 1791, 1793, 1794, 1795, 1796, 1802, 4472, 4474, 4475, 8523, 8524, 8525, 8526, 8527, 8528,
8529, 8530, 8532, 8534, 8535, 8538, 8539, 8540, 8541, 8542, 8544, 8556, 8557, 10580, 10698, 10801, 10816);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 5, `MaxStanding1` = 4
WHERE `RewOnKillRepFaction1` = 529 AND `RewOnKillRepValue1` = 10 AND `MaxStanding1` = 5 AND `creature_id` IN (
1805, 8531, 8546, 8547, 8548, 8550, 8551, 8553, 10827);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 5, `MaxStanding1` = 4
WHERE `RewOnKillRepFaction1` = 529 AND `RewOnKillRepValue1` = 10 AND `MaxStanding1` = 6 AND `creature_id` IN (
1788, 1804, 8543, 8558, 11873, 12262, 12263);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 5, `MaxStanding1` = 5
WHERE `RewOnKillRepFaction1` = 529 AND `RewOnKillRepValue1` = 10 AND `MaxStanding1` = 6 AND `creature_id` IN (
10381, 10382, 10384, 10385, 10390, 10391, 10398, 10399, 10400, 10405, 10406, 10407, 10408, 10409, 10412, 10413, 10414,
10416, 10417, 10463, 10464, 10469, 10470, 10471, 10476, 10477, 10478, 10480, 10481, 10482, 10485, 10486, 10487, 10488,
10489, 10491, 10495, 10498, 10499, 10500, 11082, 11257, 11551, 11582, 14861);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 15, `MaxStanding1` = 4
WHERE `RewOnKillRepFaction1` = 529 AND `RewOnKillRepValue1` = 30 AND `MaxStanding1` = 5 AND `creature_id` IN (
1847, 10821, 10825, 10826);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 15, `MaxStanding1` = 7
WHERE `RewOnKillRepFaction1` = 529 AND `RewOnKillRepValue1` = 30 AND `MaxStanding1` = 7 AND `creature_id` IN (
16184);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 15, `MaxStanding1` = 7
WHERE `RewOnKillRepFaction1` = 529 AND `RewOnKillRepValue1` = 50 AND `MaxStanding1` = 6 AND `creature_id` IN (
1852);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 25, `MaxStanding1` = 7
WHERE `RewOnKillRepFaction1` = 529 AND `RewOnKillRepValue1` = 50 AND `MaxStanding1` = 7 AND `creature_id` IN (
10432, 10433, 10435, 10436, 10437, 10438, 10502, 10503, 10504, 10505, 10507, 10558, 10809, 10901, 11261, 11622);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 50, `MaxStanding1` = 7
WHERE `RewOnKillRepFaction1` = 529 AND `RewOnKillRepValue1` = 100 AND `MaxStanding1` = 7 AND `creature_id` IN (
10440, 10508);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 5, `MaxStanding1` = 5
WHERE `RewOnKillRepFaction1` = 576 AND `RewOnKillRepValue1` = 20 AND `MaxStanding1` = 5 AND `creature_id` IN (
7153, 7154, 7155, 7156, 7157, 7158, 7438, 7439, 7440, 7441, 10916);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 6, `MaxStanding1` = 5
WHERE `RewOnKillRepFaction1` = 576 AND `RewOnKillRepValue1` = 20 AND `MaxStanding1` = 5 AND `creature_id` IN (
7442);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 25, `MaxStanding1` = 7
WHERE `RewOnKillRepFaction1` = 576 AND `RewOnKillRepValue1` = 40 AND `MaxStanding1` = 7 AND `creature_id` IN (
10738);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 15, `MaxStanding1` = 7
WHERE `RewOnKillRepFaction1` = 576 AND `RewOnKillRepValue1` = 60 AND `MaxStanding1` = 7 AND `creature_id` IN (
9462, 9464);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 25, `MaxStanding1` = 7
WHERE `RewOnKillRepFaction1` = 576 AND `RewOnKillRepValue1` = 100 AND `MaxStanding1` = 7 AND `creature_id` IN (
10199, 14342, 15623);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 1, `MaxStanding1` = 5
WHERE `RewOnKillRepFaction1` = 609 AND `RewOnKillRepValue1` = 2 AND `MaxStanding1` = 7 AND `creature_id` IN (
15542);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 3, `MaxStanding1` = 6
WHERE `RewOnKillRepFaction1` = 609 AND `RewOnKillRepValue1` = 5 AND `MaxStanding1` = 7 AND `creature_id` IN (
15462);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 1, `MaxStanding1` = 5
WHERE `RewOnKillRepFaction1` = 609 AND `RewOnKillRepValue1` = 10 AND `MaxStanding1` = 5 AND `creature_id` IN (
15202);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 1, `MaxStanding1` = 5
WHERE `RewOnKillRepFaction1` = 609 AND `RewOnKillRepValue1` = 10 AND `MaxStanding1` = 6 AND `creature_id` IN (
11804);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 5, `MaxStanding1` = 5
WHERE `RewOnKillRepFaction1` = 609 AND `RewOnKillRepValue1` = 10 AND `MaxStanding1` = 6 AND `creature_id` IN (
15209, 15211, 15212, 15307);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 1, `MaxStanding1` = 4
WHERE `RewOnKillRepFaction1` = 609 AND `RewOnKillRepValue1` = 10 AND `MaxStanding1` = 7 AND `creature_id` IN (
11880, 11881, 11882, 11883, 15213);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 1, `MaxStanding1` = 5
WHERE `RewOnKillRepFaction1` = 609 AND `RewOnKillRepValue1` = 10 AND `MaxStanding1` = 7 AND `creature_id` IN (
11803, 15200, 15201);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 3, `MaxStanding1` = 6
WHERE `RewOnKillRepFaction1` = 609 AND `RewOnKillRepValue1` = 10 AND `MaxStanding1` = 7 AND `creature_id` IN (
15168, 15318, 15319, 15320, 15323, 15324, 15325, 15327, 15333, 15335, 15336, 15338, 15355, 15461, 15537, 15538);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 5, `MaxStanding1` = 5
WHERE `RewOnKillRepFaction1` = 609 AND `RewOnKillRepValue1` = 10 AND `MaxStanding1` = 7 AND `creature_id` IN (
15541);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 5, `MaxStanding1` = 7
WHERE `RewOnKillRepFaction1` = 609 AND `RewOnKillRepValue1` = 10 AND `MaxStanding1` = 7 AND `creature_id` IN (
14479);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 5, `MaxStanding1` = 7
WHERE `RewOnKillRepFaction1` = 609 AND `RewOnKillRepValue1` = 30 AND `MaxStanding1` = 7 AND `creature_id` IN (
15308);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 25, `MaxStanding1` = 7
WHERE `RewOnKillRepFaction1` = 609 AND `RewOnKillRepValue1` = 50 AND `MaxStanding1` = 7 AND `creature_id` IN (
15206, 15207, 15208, 15220);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue1` = 50, `MaxStanding1` = 7
WHERE `RewOnKillRepFaction1` = 609 AND `RewOnKillRepValue1` = 100 AND `MaxStanding1` = 7 AND `creature_id` IN (
15204, 15205, 15305);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue2` = 0, `MaxStanding2` = 7
WHERE `RewOnKillRepFaction2` = 609 AND `RewOnKillRepValue2` = 10 AND `MaxStanding2` = 7 AND `creature_id` IN (
15229, 15230, 15235, 15236, 15240, 15249, 15262, 15264, 15277);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue2` = 150, `MaxStanding2` = 7
WHERE `RewOnKillRepFaction2` = 609 AND `RewOnKillRepValue2` = 300 AND `MaxStanding2` = 7 AND `creature_id` IN (
15340, 15348, 15369, 15370);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue2` = 300, `MaxStanding2` = 7
WHERE `RewOnKillRepFaction2` = 609 AND `RewOnKillRepValue2` = 600 AND `MaxStanding2` = 7 AND `creature_id` IN (
15339);
UPDATE `creature_onkill_reputation` SET `RewOnKillRepValue2` = 500, `MaxStanding2` = 7
WHERE `RewOnKillRepFaction2` = 609 AND `RewOnKillRepValue2` = 1000 AND `MaxStanding2` = 7 AND `creature_id` IN (
15727);
