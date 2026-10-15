-- Ascension's creature families and tameable flags, from the live realms' creature query responses
-- (creaturecache.wdb, Darkmoon, Dawnrise and Area 52, 2026-08-29 to 2026-09-01; no realm disagrees).
-- Their non-beast pet families run from 301 to 859, past what a TINYINT holds.
ALTER TABLE `creature_template` MODIFY COLUMN `family` SMALLINT UNSIGNED NOT NULL DEFAULT 0;

UPDATE `creature_template` SET `family` = 4 WHERE `entry` IN (222999);
UPDATE `creature_template` SET `family` = 10 WHERE `entry` IN (3248, 3463, 3816, 3817, 3818, 4018, 4019, 8759, 8760);
UPDATE `creature_template` SET `family` = 10 WHERE `entry` IN (8761, 17130, 17131, 18258);
UPDATE `creature_template` SET `family` = 44 WHERE `entry` IN (5245, 5441, 5455, 6551, 11727);
UPDATE `creature_template` SET `family` = 105 WHERE `entry` IN (1547, 1548, 1549, 3102, 3774, 4685, 6010, 7462, 8718);
UPDATE `creature_template` SET `family` = 105 WHERE `entry` IN (10356, 254015);
UPDATE `creature_template` SET `family` = 106 WHERE `entry` IN (5760, 12396);
UPDATE `creature_template` SET `family` = 114 WHERE `entry` IN (4677, 7463, 8717, 18661);
UPDATE `creature_template` SET `family` = 118 WHERE `entry` IN (4676, 6073, 7135, 7136, 7137);
UPDATE `creature_template` SET `family` = 128 WHERE `entry` IN (8716, 10813);
UPDATE `creature_template` SET `family` = 134 WHERE `entry` IN (2038, 2212, 3662, 3752, 3754, 3755, 3757, 3758, 3759);
UPDATE `creature_template` SET `family` = 134 WHERE `entry` IN (3762, 3763, 3767, 3770, 3771, 4670, 4671, 4672, 4673);
UPDATE `creature_template` SET `family` = 134 WHERE `entry` IN (4674, 4675, 4798, 4799, 6125, 6126, 6127, 6200, 6201);
UPDATE `creature_template` SET `family` = 134 WHERE `entry` IN (6202, 7105, 7106, 7107, 7108, 7109, 7110, 7111, 9454);
UPDATE `creature_template` SET `family` = 134 WHERE `entry` IN (10648, 11452, 11457, 11492, 11790, 11791, 11792, 12236);
UPDATE `creature_template` SET `family` = 134 WHERE `entry` IN (15625);
UPDATE `creature_template` SET `family` = 136 WHERE `entry` IN (7461, 9860, 9861, 11697, 18660);
UPDATE `creature_template` SET `family` = 140 WHERE `entry` IN (11496);
UPDATE `creature_template` SET `family` = 146 WHERE `entry` IN (15690, 34780);
UPDATE `creature_template` SET `family` = 203 WHERE `entry` IN (1805, 1850, 5624, 5687, 8543, 8567, 10414, 10416);
UPDATE `creature_template` SET `family` = 203 WHERE `entry` IN (10417, 10439, 14682);
UPDATE `creature_template` SET `family` = 204 WHERE `entry` IN (1531, 1533, 1534, 1804, 1983, 2044, 2176, 2178, 2278);
UPDATE `creature_template` SET `family` = 204 WHERE `entry` IN (4606, 6116, 7524, 8540, 8541, 8542, 10436, 10463);
UPDATE `creature_template` SET `family` = 204 WHERE `entry` IN (10464, 10684, 11472);
UPDATE `creature_template` SET `family` = 205 WHERE `entry` IN (10488, 11622);
UPDATE `creature_template` SET `family` = 207 WHERE `entry` IN (8556, 8557, 8558, 10412, 10413, 11551, 16184);
UPDATE `creature_template` SET `family` = 215 WHERE `entry` IN (8534, 8535, 10408, 10409, 10506, 10825, 27829, 29239);
UPDATE `creature_template` SET `family` = 218 WHERE `entry` IN (1794, 1795, 10407);
UPDATE `creature_template` SET `family` = 219 WHERE `entry` IN (1852, 7358, 15990, 17767, 36855);
UPDATE `creature_template` SET `family` = 223 WHERE `entry` IN (7327, 7328, 7329, 7332, 7333, 7334);
UPDATE `creature_template` SET `family` = 224 WHERE `entry` IN (1802, 6427, 7370, 8538, 8539, 10411, 11284);
UPDATE `creature_template` SET `family` = 225 WHERE `entry` IN (48, 202, 522, 531, 771, 785, 787, 1110, 1520, 1522);
UPDATE `creature_template` SET `family` = 225 WHERE `entry` IN (1523, 1658, 1783, 1787, 1788, 1789, 1865, 1869, 1870);
UPDATE `creature_template` SET `family` = 225 WHERE `entry` IN (1890, 1916, 1973, 6412, 7341, 7343, 7344, 7345, 7346);
UPDATE `creature_template` SET `family` = 225 WHERE `entry` IN (8523, 8525, 8526, 8527, 8529, 10390, 10391, 10478);
UPDATE `creature_template` SET `family` = 225 WHERE `entry` IN (10482, 10485, 10486, 10487, 10489, 11155, 11477, 11561);
UPDATE `creature_template` SET `family` = 225 WHERE `entry` IN (12341, 12342, 12343, 16805, 17878, 28500, 34238);
UPDATE `creature_template` SET `family` = 229 WHERE `entry` IN (1946, 2177, 2623, 3094, 3617, 4308, 4472, 4550, 6117);
UPDATE `creature_template` SET `family` = 229 WHERE `entry` IN (6118, 6493, 7352, 7353, 7523, 10358, 10389, 10516);
UPDATE `creature_template` SET `family` = 229 WHERE `entry` IN (11471, 11473, 11475, 11873, 12377, 12378, 23554);
UPDATE `creature_template` SET `family` = 230 WHERE `entry` IN (3, 210, 503, 570, 572, 604, 624, 626, 948, 1270, 1488);
UPDATE `creature_template` SET `family` = 230 WHERE `entry` IN (1489, 1501, 1502, 1525, 1526, 1527, 1529, 1530, 1654);
UPDATE `creature_template` SET `family` = 230 WHERE `entry` IN (1656, 1791, 1793, 1796, 1866, 1868, 1917, 1918, 1919);
UPDATE `creature_template` SET `family` = 230 WHERE `entry` IN (1974, 4474, 4475, 5263, 5271, 5685, 5686, 5711, 7347);
UPDATE `creature_template` SET `family` = 230 WHERE `entry` IN (7348, 8530, 8532, 10381, 10382, 10383, 10405, 10406);
UPDATE `creature_template` SET `family` = 230 WHERE `entry` IN (10435, 10480, 10481, 10495, 10580, 10698, 10808, 10901);
UPDATE `creature_template` SET `family` = 230 WHERE `entry` IN (11290, 12248, 23555, 24207, 29212, 161749, 161752);
UPDATE `creature_template` SET `family` = 230 WHERE `entry` IN (161753, 161754, 161755);
UPDATE `creature_template` SET `family` = 233 WHERE `entry` IN (203, 1657, 1784, 4543, 7342, 8528, 8551, 10432, 28488);
UPDATE `creature_template` SET `family` = 233 WHERE `entry` IN (50075);
UPDATE `creature_template` SET `family` = 301 WHERE `entry` IN (832, 2762, 8667, 9377, 11576, 11577, 11578, 11744);
UPDATE `creature_template` SET `family` = 301 WHERE `entry` IN (11745, 14399, 14400);
UPDATE `creature_template` SET `family` = 302 WHERE `entry` IN (92, 2258, 2359, 2592, 2735, 2736, 4120, 4661, 11746);
UPDATE `creature_template` SET `family` = 302 WHERE `entry` IN (11778, 15352);
UPDATE `creature_template` SET `family` = 303 WHERE `entry` IN (2745, 2760, 4036, 4037, 4038, 5850, 5852, 6520, 6521);
UPDATE `creature_template` SET `family` = 303 WHERE `entry` IN (8909, 8910, 9017, 9026, 9376, 9816, 12056, 15438);
UPDATE `creature_template` SET `family` = 303 WHERE `entry` IN (26401, 26520);
UPDATE `creature_template` SET `family` = 304 WHERE `entry` IN (510, 691, 2761, 3917, 4978, 5461, 5462, 5897, 6220);
UPDATE `creature_template` SET `family` = 304 WHERE `entry` IN (7079, 7132, 8519, 8520, 8521, 8522, 8837, 10642, 10756);
UPDATE `creature_template` SET `family` = 304 WHERE `entry` IN (10757, 13278, 13322, 14458, 21216);
UPDATE `creature_template` SET `family` = 305 WHERE `entry` IN (4034, 4035, 5855, 7031, 7032, 8278, 9025, 11321, 12057);
UPDATE `creature_template` SET `family` = 305 WHERE `entry` IN (16043);
UPDATE `creature_template` SET `family` = 306 WHERE `entry` IN (11783);
UPDATE `creature_template` SET `family` = 308 WHERE `entry` IN (6550, 11480, 11483, 11484);
UPDATE `creature_template` SET `family` = 309 WHERE `entry` IN (9878, 9879);
UPDATE `creature_template` SET `family` = 350 WHERE `entry` IN (19514);
UPDATE `creature_template` SET `family` = 356 WHERE `entry` IN (13197);
UPDATE `creature_template` SET `family` = 363 WHERE `entry` IN (6509, 6510, 6511, 6512);
UPDATE `creature_template` SET `family` = 365 WHERE `entry` IN (12258, 13285);
UPDATE `creature_template` SET `family` = 368 WHERE `entry` IN (2156, 2157, 2723, 2751, 4857, 4860, 5853, 6560, 7206);
UPDATE `creature_template` SET `family` = 368 WHERE `entry` IN (8400, 10120);
UPDATE `creature_template` SET `family` = 370 WHERE `entry` IN (7039);
UPDATE `creature_template` SET `family` = 372 WHERE `entry` IN (8279, 8905);
UPDATE `creature_template` SET `family` = 373 WHERE `entry` IN (8906);
UPDATE `creature_template` SET `family` = 374 WHERE `entry` IN (8908);
UPDATE `creature_template` SET `family` = 375 WHERE `entry` IN (8982);
UPDATE `creature_template` SET `family` = 382 WHERE `entry` IN (764, 766, 1039, 1040, 1812, 1813, 1953, 1954, 1955);
UPDATE `creature_template` SET `family` = 382 WHERE `entry` IN (1956, 2022, 2027, 3535, 3780, 3782, 3784, 4382, 4385);
UPDATE `creature_template` SET `family` = 382 WHERE `entry` IN (4386, 5481, 5485, 5490, 5761, 6517, 6518, 6519, 6527);
UPDATE `creature_template` SET `family` = 382 WHERE `entry` IN (7100, 7101, 7104, 12223, 12224, 12237);
UPDATE `creature_template` SET `family` = 383 WHERE `entry` IN (16011);
UPDATE `creature_template` SET `family` = 384 WHERE `entry` IN (1964, 3834, 4030, 5806, 21853);
UPDATE `creature_template` SET `family` = 385 WHERE `entry` IN (3919, 4028, 4029, 4423, 7138, 7139, 7584, 11465, 13141);
UPDATE `creature_template` SET `family` = 385 WHERE `entry` IN (13142);
UPDATE `creature_template` SET `family` = 387 WHERE `entry` IN (15271);
UPDATE `creature_template` SET `family` = 402 WHERE `entry` IN (149, 335, 441, 2725, 4323, 4324, 7047, 7048, 7049);
UPDATE `creature_template` SET `family` = 402 WHERE `entry` IN (12417, 14272);
UPDATE `creature_template` SET `family` = 403 WHERE `entry` IN (2726, 4339, 7044, 7045, 7046, 7846, 8964, 8976, 11983);
UPDATE `creature_template` SET `family` = 403 WHERE `entry` IN (23687);
UPDATE `creature_template` SET `family` = 404 WHERE `entry` IN (10184, 11978, 26275, 28860);
UPDATE `creature_template` SET `family` = 405 WHERE `entry` IN (11583);
UPDATE `creature_template` SET `family` = 406 WHERE `entry` IN (12017);
UPDATE `creature_template` SET `family` = 407 WHERE `entry` IN (4328, 4329, 7040, 7042, 9568, 10363, 10371, 12435);
UPDATE `creature_template` SET `family` = 407 WHERE `entry` IN (31218);
UPDATE `creature_template` SET `family` = 408 WHERE `entry` IN (4331, 4334, 7041, 7043, 10372, 31219);
UPDATE `creature_template` SET `family` = 414 WHERE `entry` IN (10659, 10660, 10661, 10740, 27636);
UPDATE `creature_template` SET `family` = 415 WHERE `entry` IN (10662, 26736, 27638, 27682, 28236);
UPDATE `creature_template` SET `family` = 416 WHERE `entry` IN (15411, 25723, 27608, 32434, 33717);
UPDATE `creature_template` SET `family` = 418 WHERE `entry` IN (30666);
UPDATE `creature_template` SET `family` = 419 WHERE `entry` IN (193, 6129, 6130, 7436, 26716, 27633, 31402, 32191);
UPDATE `creature_template` SET `family` = 420 WHERE `entry` IN (6131, 7435, 7437, 26722, 26735, 27635, 30667, 31079);
UPDATE `creature_template` SET `family` = 420 WHERE `entry` IN (31403);
UPDATE `creature_template` SET `family` = 428 WHERE `entry` IN (15192, 15410);
UPDATE `creature_template` SET `family` = 438 WHERE `entry` IN (740, 741, 8319, 8776);
UPDATE `creature_template` SET `family` = 440 WHERE `entry` IN (5709, 14888, 15689, 26278, 36789);
UPDATE `creature_template` SET `family` = 443 WHERE `entry` IN (744, 745, 5319, 5320, 12474, 12475, 12477, 12479);
UPDATE `creature_template` SET `family` = 444 WHERE `entry` IN (742, 12478);
UPDATE `creature_template` SET `family` = 450 WHERE `entry` IN (1042, 1043, 1044, 1069);
UPDATE `creature_template` SET `family` = 451 WHERE `entry` IN (2447, 12899);
UPDATE `creature_template` SET `family` = 452 WHERE `entry` IN (13020);
UPDATE `creature_template` SET `family` = 453 WHERE `entry` IN (26917, 32295, 33536);
UPDATE `creature_template` SET `family` = 455 WHERE `entry` IN (1046, 1047, 1048, 1049, 1050);
UPDATE `creature_template` SET `family` = 470 WHERE `entry` IN (14020);
UPDATE `creature_template` SET `family` = 473 WHERE `entry` IN (33186);
UPDATE `creature_template` SET `family` = 488 WHERE `entry` IN (39863);
UPDATE `creature_template` SET `family` = 499 WHERE `entry` IN (21817, 23031, 23456, 23477, 23478, 26071);
UPDATE `creature_template` SET `family` = 500 WHERE `entry` IN (25721, 26322);
UPDATE `creature_template` SET `family` = 510 WHERE `entry` IN (10678);
UPDATE `creature_template` SET `family` = 541 WHERE `entry` IN (4016, 5276, 5278, 7997);
UPDATE `creature_template` SET `family` = 551 WHERE `entry` IN (50124);
UPDATE `creature_template` SET `family` = 601 WHERE `entry` IN (36, 114, 115, 480);
UPDATE `creature_template` SET `family` = 602 WHERE `entry` IN (8447);
UPDATE `creature_template` SET `family` = 603 WHERE `entry` IN (14224);
UPDATE `creature_template` SET `family` = 611 WHERE `entry` IN (33350);
UPDATE `creature_template` SET `family` = 666 WHERE `entry` IN (510100);
UPDATE `creature_template` SET `family` = 692 WHERE `entry` IN (60070);
UPDATE `creature_template` SET `family` = 693 WHERE `entry` IN (60671);
UPDATE `creature_template` SET `family` = 694 WHERE `entry` IN (60672);
UPDATE `creature_template` SET `family` = 695 WHERE `entry` IN (500481);
UPDATE `creature_template` SET `family` = 696 WHERE `entry` IN (50048);

UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (3, 36, 48, 92, 114, 115, 149, 193);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (202, 203, 210, 335, 416, 417, 441);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (480, 503, 510, 522, 531, 570, 572);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (604, 624, 626, 691, 740, 741, 742);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (744, 745, 764, 766, 771, 785, 787);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (819, 832, 948, 1039, 1040, 1042, 1043);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (1044, 1046, 1047, 1048, 1049, 1050);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (1069, 1110, 1270, 1488, 1489, 1501);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (1502, 1520, 1522, 1523, 1525, 1526);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (1527, 1529, 1530, 1531, 1533, 1534);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (1547, 1548, 1549, 1654, 1656, 1657);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (1658, 1783, 1784, 1787, 1788, 1789);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (1791, 1793, 1794, 1795, 1796, 1802);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (1804, 1805, 1812, 1813, 1850, 1852);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (1860, 1863, 1865, 1866, 1868, 1869);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (1870, 1890, 1916, 1917, 1918, 1919);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (1946, 1953, 1954, 1955, 1956, 1964);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (1973, 1974, 1983, 2022, 2027, 2038);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (2044, 2156, 2157, 2176, 2177, 2178);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (2258, 2359, 2447, 2592, 2623, 2723);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (2725, 2726, 2735, 2736, 2745, 2751);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (2760, 2761, 2762, 3094, 3102, 3248);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (3463, 3535, 3617, 3662, 3752, 3754);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (3755, 3757, 3758, 3759, 3762, 3763);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (3767, 3770, 3771, 3774, 3780, 3782);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (3784, 3816, 3817, 3818, 3834, 3917);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (3919, 4016, 4018, 4019, 4028, 4029);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (4030, 4034, 4035, 4036, 4037, 4038);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (4120, 4308, 4323, 4324, 4328, 4329);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (4331, 4334, 4339, 4382, 4385, 4386);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (4423, 4472, 4474, 4475, 4550, 4661);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (4670, 4671, 4672, 4673, 4674, 4675);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (4676, 4677, 4685, 4798, 4799, 4857);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (4860, 4978, 5058, 5245, 5263, 5271);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (5276, 5278, 5319, 5320, 5441, 5455);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (5461, 5462, 5481, 5485, 5490, 5624);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (5685, 5686, 5687, 5711, 5760, 5761);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (5806, 5850, 5852, 5853, 5855, 5897);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (6010, 6073, 6116, 6117, 6118, 6125);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (6126, 6127, 6129, 6130, 6131, 6200);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (6201, 6202, 6220, 6412, 6427, 6493);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (6509, 6510, 6511, 6512, 6517, 6518);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (6519, 6520, 6521, 6527, 6550, 6551);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (6560, 7031, 7032, 7039, 7040, 7041);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (7042, 7043, 7044, 7045, 7046, 7047);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (7048, 7049, 7100, 7101, 7104, 7105);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (7106, 7107, 7108, 7109, 7110, 7111);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (7132, 7135, 7136, 7137, 7138, 7139);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (7327, 7328, 7329, 7332, 7333, 7334);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (7341, 7342, 7343, 7344, 7345, 7346);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (7347, 7348, 7352, 7353, 7370, 7435);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (7436, 7437, 7461, 7462, 7463, 7523);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (7524, 7584, 7846, 7997, 8278, 8279);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (8319, 8400, 8447, 8519, 8520, 8521);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (8522, 8523, 8525, 8526, 8527, 8528);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (8529, 8530, 8532, 8534, 8535, 8538);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (8539, 8540, 8541, 8542, 8543, 8556);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (8557, 8558, 8596, 8597, 8598, 8667);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (8716, 8717, 8718, 8759, 8760, 8761);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (8776, 8837, 8905, 8906, 8908, 8909);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (8910, 8921, 8922, 8964, 8976, 8982);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (9026, 9376, 9377, 9454, 9860, 9861);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (9878, 9879, 10120, 10356, 10358);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (10371, 10372, 10381, 10382, 10383);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (10389, 10390, 10391, 10405, 10406);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (10407, 10408, 10409, 10411, 10412);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (10413, 10414, 10416, 10417, 10463);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (10464, 10478, 10480, 10481, 10482);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (10485, 10486, 10487, 10488, 10489);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (10495, 10580, 10642, 10648, 10659);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (10660, 10661, 10662, 10678, 10698);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (10756, 10757, 10825, 11024, 11155);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (11284, 11290, 11321, 11452, 11457);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (11465, 11471, 11472, 11473, 11475);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (11477, 11480, 11483, 11484, 11551);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (11561, 11576, 11577, 11578, 11697);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (11727, 11744, 11745, 11746, 11778);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (11783, 11790, 11791, 11792, 11871);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (11873, 12223, 12224, 12236, 12237);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (12248, 12341, 12342, 12343, 12377);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (12378, 12396, 12417, 12474, 12475);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (12477, 12478, 12479, 12899, 13141);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (13142, 13197, 13278, 13285, 13322);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (14224, 14272, 14399, 14400, 14458);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (14682, 15271, 15352, 15438, 16043);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (16184, 16805, 17111, 17112, 17113);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (17130, 17131, 17252, 17878, 18258);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (18660, 18661, 21817, 21853, 23031);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (23456, 23477, 23478, 23554, 23555);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (23687, 25721, 25723, 26071, 26125);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (26275, 26278, 26322, 26401, 26520);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (26716, 26722, 26735, 26736, 27608);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (27633, 27635, 27636, 27638, 27682);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (27829, 28236, 28488, 28500, 29212);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (29239, 30230, 30666, 30667, 31079);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (31218, 31219, 31402, 31403, 32191);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (32434, 33350, 33536, 33717, 34238);
UPDATE `creature_template` SET `type_flags` = `type_flags` | 1 WHERE `entry` IN (222999, 254015, 510100);
UPDATE `creature_template` SET `type_flags` = `type_flags` & ~1 WHERE `entry` IN (756);

-- The four non-beast taming channels and their duplicate rows check their targets the way Tame Beast does.
DELETE FROM `spell_script_names`
WHERE `ScriptName` = 'spell_hun_tame_beast' AND `spell_id` IN (890, 896, 891, 899, 91606, 93569, 91634, 93558);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(890, 'spell_hun_tame_beast'),
(896, 'spell_hun_tame_beast'),
(891, 'spell_hun_tame_beast'),
(899, 'spell_hun_tame_beast'),
(91606, 'spell_hun_tame_beast'),
(93569, 'spell_hun_tame_beast'),
(91634, 'spell_hun_tame_beast'),
(93558, 'spell_hun_tame_beast');

-- Every pet family's call spell: a Hero calls the stored pet of that family, or gets its starter pet.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_ascension_family_call';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(883, 'spell_ascension_family_call'),
(1100883, 'spell_ascension_family_call'),
(1350883, 'spell_ascension_family_call'),
(884, 'spell_ascension_family_call'),
(1100884, 'spell_ascension_family_call'),
(885, 'spell_ascension_family_call'),
(91602, 'spell_ascension_family_call'),
(1441602, 'spell_ascension_family_call'),
(91631, 'spell_ascension_family_call'),
(1441631, 'spell_ascension_family_call');
