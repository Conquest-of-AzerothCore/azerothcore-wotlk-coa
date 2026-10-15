-- Built from Ascension's combat logs and client data. Regenerate rather than edit by hand.
--
-- Flex health for the classic raid bosses. Molten Core and Onyxia are measured
-- from combat logs; the other raids are built from the same pattern.
--
-- The raids were flex: the difficulty label reads "(10-25 Players)", and the
-- kills show it. Garr had 30.8 million health on Ascended with 13 players and
-- 43.1 million in another raid. Divided by the player count, every boss lands
-- on the same ratio between difficulties:
--
--   per player   Heroic 1  :  Mythic 1.505  :  Ascended 2.194
--
-- So the table holds health PER PLAYER, per difficulty, and the server
-- multiplies by the players in the instance when the boss is pulled.
--
-- Measured as damage minus healing from the first hit to the death. The player
-- count is everyone who hit the boss or was hit by it; a healer who never took
-- a hit is missing, so the count can only be too low, which makes the value per
-- player too high. Where there are several kills, the lowest value stands.
--
-- A difficulty without a kill follows the pattern, anchored on the boss's own
-- measured Heroic:
--
--   Normal    Heroic x 0.75   set, not measured: no Molten Core log is on
--                             Normal. Keeps the step to Heroic smaller than
--                             the ones after it.
--   Mythic    Heroic x 1.505  median of the bosses killed on both
--   Ascended  Heroic x 2.195  median of the bosses killed on both
--
-- Onyxia is aligned to the same pattern on purpose. She was killed on all four
-- difficulties, but her ratio (0.48 : 1 : 1.78 : 2.92) stood apart; only her
-- measured Heroic is kept, everything else follows the pattern.
--
-- Zul'Gurub, Blackwing Lair and both Ahn'Qiraj raids have no logs. Their rows
-- are built, not measured: stock health x 6.92 is Normal at 20 players, and the
-- other difficulties follow the same pattern. 6.92 is what four Molten Core
-- bosses land on exactly. Ragnaros sits at 2.77 - Ascension scaled him down
-- against Blizzard - but a separate end-boss factor from him would have put
-- Nefarian below Broodlord and C'Thun below Viscidus, so one factor holds for
-- all. Two groups that are equal in the original but not in our data are set
-- to their median first: the Blackwing drakes and the Edge of Madness bosses.

CREATE TABLE IF NOT EXISTS `coa_boss_flex` (
  `entry`    INT UNSIGNED NOT NULL COMMENT 'base creature entry',
  `hp_d0`    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'health per player, Normal; 0 no flex',
  `hp_d1`    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Heroic',
  `hp_d2`    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Mythic',
  `hp_d3`    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Ascended',
  `comment`  VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`entry`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_boss_flex` WHERE `entry` IN (12118,12259,12057,12264,12056,12098,11988,11502,10184,14509,14507,14517,14510,14515,11380,11382,15114,15082,15083,15084,15085,14834,12435,13020,12017,11983,14601,11981,14020,11583,15348,15341,15340,15370,15369,15339,15263,15511,15544,15543,15516,15510,15299,15509,15276,15275,15517,15589,15727);
INSERT INTO `coa_boss_flex` VALUES (12118, 431810, 575747, 866550, 1263490, 'Lucifron: Normal = Heroic x 0.750 (set), Heroic measured, Mythic = Heroic x 1.505 (pattern), Ascended measured');
INSERT INTO `coa_boss_flex` VALUES (12259, 647716, 863621, 1299826, 1895236, 'Gehennas: Normal = Heroic x 0.750 (set), Heroic measured, Mythic = Heroic x 1.505 (pattern), Ascended measured');
INSERT INTO `coa_boss_flex` VALUES (12057, 809645, 1079527, 1624782, 2369044, 'Garr: Normal = Heroic x 0.750 (set), Heroic measured, Mythic = Heroic x 1.505 (pattern), Ascended measured');
INSERT INTO `coa_boss_flex` VALUES (12264, 566709, 755612, 1137262, 1657316, 'Shazzrah: Normal = Heroic x 0.750 (set), Heroic measured, Mythic measured, Ascended measured');
INSERT INTO `coa_boss_flex` VALUES (12056, 647716, 863621, 1299826, 1894878, 'Baron Geddon: Normal = Heroic x 0.750 (set), Heroic measured, Mythic measured, Ascended measured');
INSERT INTO `coa_boss_flex` VALUES (12098, 323858, 431811, 649913, 947618, 'Sulfuron Harbinger: Normal = Heroic x 0.750 (set), Heroic measured, Mythic measured, Ascended measured');
INSERT INTO `coa_boss_flex` VALUES (11988, 809645, 1079527, 1624782, 2369044, 'Golemagg the Incinerator: Normal = Heroic x 0.750 (set), Heroic measured, Mythic measured, Ascended measured');
INSERT INTO `coa_boss_flex` VALUES (11502, 842031, 1122708, 1669897, 2463806, 'Ragnaros: Normal = Heroic x 0.750 (set), Heroic measured, Mythic measured, Ascended = Heroic x 2.195 (pattern)');
INSERT INTO `coa_boss_flex` VALUES (10184, 842058, 1122744, 1689827, 2463885, 'Onyxia: Normal = Heroic x 0.750 (set), Heroic measured, Mythic = Heroic x 1.505 (pattern), Ascended = Heroic x 2.195 (pattern)');
INSERT INTO `coa_boss_flex` VALUES (14509, 248964, 331952, 499617, 728476, 'ZG High Priest Thekal: stock 719,550, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (14507, 497928, 663904, 999234, 1456952, 'ZG High Priest Venoxis: stock 1,439,100, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (14517, 497928, 663904, 999234, 1456952, 'ZG High Priestess Jeklik: stock 1,439,100, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (14510, 497928, 663904, 999234, 1456952, 'ZG High Priestess Mar\'li: stock 1,439,100, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (14515, 497928, 663904, 999234, 1456952, 'ZG High Priestess Arlokk: stock 1,439,100, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (11380, 497928, 663904, 999234, 1456952, 'ZG Jin\'do the Hexxer: stock 1,439,100, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (11382, 622364, 829818, 1248949, 1821054, 'ZG Bloodlord Mandokir: stock 1,798,740, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15114, 622364, 829818, 1248949, 1821054, 'ZG Gahz\'ranka: stock 1,798,740, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15082, 108341, 144455, 217417, 317009, 'ZG Gri\'lek: stock 1,798,740 -> Edge of Madness median 313,125, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15083, 108341, 144455, 217417, 317009, 'ZG Hazza\'rah: stock 266,500 -> Edge of Madness median 313,125, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15084, 108341, 144455, 217417, 317009, 'ZG Renataki: stock 333,100 -> Edge of Madness median 313,125, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15085, 108341, 144455, 217417, 317009, 'ZG Wushoolay: stock 293,150 -> Edge of Madness median 313,125, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (14834, 647307, 863076, 1299004, 1894038, 'ZG Hakkar: stock 1,870,830, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (12435, 521444, 695259, 1046425, 1525760, 'BWL Razorgore the Untamed: stock 1,507,064, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (13020, 1997673, 2663564, 4008896, 5845246, 'BWL Vaelastrasz the Corrupt: stock 5,773,622, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (12017, 1281332, 1708443, 2571355, 3749213, 'BWL Broodlord Lashlayer: stock 3,703,273, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (11983, 422837, 563783, 848543, 1237234, 'BWL Firemaw: stock 1,629,432 -> BWL drakes median 1,222,074, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (14601, 422837, 563783, 848543, 1237234, 'BWL Ebonroc: stock 1,222,074 -> BWL drakes median 1,222,074, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (11981, 422837, 563783, 848543, 1237234, 'BWL Flamegor: stock 509,197 -> BWL drakes median 1,222,074, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (14020, 1042888, 1390518, 2092850, 3051520, 'BWL Chromaggus: stock 3,014,129, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (11583, 1558215, 2077620, 3126999, 4559380, 'BWL Nefarian: stock 4,503,512, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15348, 374570, 499427, 751682, 1096004, 'AQ20 Kurinnaxx: stock 1,082,575, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15341, 374570, 499427, 751682, 1096004, 'AQ20 General Rajaxx: stock 1,082,575, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15340, 599358, 799144, 1202782, 1753739, 'AQ20 Moam: stock 1,732,250, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15370, 599358, 799144, 1202782, 1753739, 'AQ20 Buru the Gorger: stock 1,732,250, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15369, 374570, 499427, 751682, 1096004, 'AQ20 Ayamiss the Hunter: stock 1,082,575, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15339, 973884, 1298512, 1954374, 2849612, 'AQ20 Ossirian the Unscarred: stock 2,814,695, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15263, 779166, 1038888, 1563617, 2279861, 'AQ40 The Prophet Skeram: stock 2,251,925, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15511, 325277, 433703, 652761, 951770, 'AQ40 Lord Kri: stock 940,108, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15544, 149828, 199771, 300673, 438401, 'AQ40 Vem: stock 433,030, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15543, 103727, 138303, 208158, 303509, 'AQ40 Princess Yauj: stock 299,790, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15516, 779107, 1038810, 1563499, 2279690, 'AQ40 Battleguard Sartura: stock 2,251,756, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15510, 681719, 908958, 1368062, 1994728, 'AQ40 Fankriss the Unyielding: stock 1,970,286, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15299, 1558215, 2077620, 3126999, 4559380, 'AQ40 Viscidus: stock 4,503,512, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15509, 779107, 1038810, 1563499, 2279690, 'AQ40 Princess Huhuran: stock 2,251,756, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15276, 599358, 799144, 1202782, 1753739, 'AQ40 Emperor Vek\'lor: stock 1,732,250, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15275, 973884, 1298512, 1954374, 2849612, 'AQ40 Emperor Vek\'nilash: stock 2,814,695, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15517, 779107, 1038810, 1563499, 2279690, 'AQ40 Ouro: stock 2,251,756, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15589, 461010, 614680, 925147, 1348929, 'AQ40 Eye of C\'Thun: stock 1,332,400, x6.92 at 20 players (built, not measured)');
INSERT INTO `coa_boss_flex` VALUES (15727, 2025679, 2700906, 4065099, 5927193, 'AQ40 C\'Thun: stock 5,854,566, x6.92 at 20 players (built, not measured)');
