-- Classic+ creature combat data: WotLK-era values restored to vanilla 1.12. Source: vmangos world (final 1.12
-- rows, patch <= 10; spell_threat build 5875). A value changes only where the current world still carries the
-- stock AzerothCore value, the creature or spell keeps its vanilla ID and name, and the creature is level 1-63
-- outside Naxxramas/Onyxia. Ascension imports and hand-authored CoA creature restorations are left alone.

-- Caster base armor, unit_class 2 and 8, levels 1-60 (vmangos creature_classlevelstats.armor).
UPDATE `creature_classlevelstats` SET `basearmor` = 0 WHERE `level` = 1 AND `class` = 2; -- was 7
UPDATE `creature_classlevelstats` SET `basearmor` = 0 WHERE `level` = 2 AND `class` = 2; -- was 19
UPDATE `creature_classlevelstats` SET `basearmor` = 16 WHERE `level` = 3 AND `class` = 2; -- was 33
UPDATE `creature_classlevelstats` SET `basearmor` = 45 WHERE `level` = 4 AND `class` = 2; -- was 66
UPDATE `creature_classlevelstats` SET `basearmor` = 83 WHERE `level` = 5 AND `class` = 2; -- was 109
UPDATE `creature_classlevelstats` SET `basearmor` = 127 WHERE `level` = 6 AND `class` = 2; -- was 163
UPDATE `creature_classlevelstats` SET `basearmor` = 182 WHERE `level` = 7 AND `class` = 2; -- was 208
UPDATE `creature_classlevelstats` SET `basearmor` = 244 WHERE `level` = 8 AND `class` = 2; -- was 303
UPDATE `creature_classlevelstats` SET `basearmor` = 318 WHERE `level` = 9 AND `class` = 2; -- was 369
UPDATE `creature_classlevelstats` SET `basearmor` = 401 WHERE `level` = 10 AND `class` = 2; -- was 460
UPDATE `creature_classlevelstats` SET `basearmor` = 425 WHERE `level` = 11 AND `class` = 2; -- was 526
UPDATE `creature_classlevelstats` SET `basearmor` = 453 WHERE `level` = 12 AND `class` = 2; -- was 560
UPDATE `creature_classlevelstats` SET `basearmor` = 479 WHERE `level` = 13 AND `class` = 2; -- was 596
UPDATE `creature_classlevelstats` SET `basearmor` = 509 WHERE `level` = 14 AND `class` = 2; -- was 630
UPDATE `creature_classlevelstats` SET `basearmor` = 536 WHERE `level` = 15 AND `class` = 2; -- was 665
UPDATE `creature_classlevelstats` SET `basearmor` = 566 WHERE `level` = 16 AND `class` = 2; -- was 700
UPDATE `creature_classlevelstats` SET `basearmor` = 594 WHERE `level` = 17 AND `class` = 2; -- was 734
UPDATE `creature_classlevelstats` SET `basearmor` = 620 WHERE `level` = 18 AND `class` = 2; -- was 768
UPDATE `creature_classlevelstats` SET `basearmor` = 651 WHERE `level` = 19 AND `class` = 2; -- was 802
UPDATE `creature_classlevelstats` SET `basearmor` = 677 WHERE `level` = 20 AND `class` = 2; -- was 836
UPDATE `creature_classlevelstats` SET `basearmor` = 705 WHERE `level` = 21 AND `class` = 2; -- was 872
UPDATE `creature_classlevelstats` SET `basearmor` = 735 WHERE `level` = 22 AND `class` = 2; -- was 906
UPDATE `creature_classlevelstats` SET `basearmor` = 762 WHERE `level` = 23 AND `class` = 2; -- was 940
UPDATE `creature_classlevelstats` SET `basearmor` = 790 WHERE `level` = 24 AND `class` = 2; -- was 975
UPDATE `creature_classlevelstats` SET `basearmor` = 818 WHERE `level` = 25 AND `class` = 2; -- was 1008
UPDATE `creature_classlevelstats` SET `basearmor` = 846 WHERE `level` = 26 AND `class` = 2; -- was 1042
UPDATE `creature_classlevelstats` SET `basearmor` = 875 WHERE `level` = 27 AND `class` = 2; -- was 1078
UPDATE `creature_classlevelstats` SET `basearmor` = 903 WHERE `level` = 28 AND `class` = 2; -- was 1110
UPDATE `creature_classlevelstats` SET `basearmor` = 931 WHERE `level` = 29 AND `class` = 2; -- was 1145
UPDATE `creature_classlevelstats` SET `basearmor` = 958 WHERE `level` = 30 AND `class` = 2; -- was 1178
UPDATE `creature_classlevelstats` SET `basearmor` = 986 WHERE `level` = 31 AND `class` = 2; -- was 1213
UPDATE `creature_classlevelstats` SET `basearmor` = 1016 WHERE `level` = 32 AND `class` = 2; -- was 1248
UPDATE `creature_classlevelstats` SET `basearmor` = 1042 WHERE `level` = 33 AND `class` = 2; -- was 1281
UPDATE `creature_classlevelstats` SET `basearmor` = 1071 WHERE `level` = 34 AND `class` = 2; -- was 1316
UPDATE `creature_classlevelstats` SET `basearmor` = 1097 WHERE `level` = 35 AND `class` = 2; -- was 1349
UPDATE `creature_classlevelstats` SET `basearmor` = 1181 WHERE `level` = 36 AND `class` = 2; -- was 1455
UPDATE `creature_classlevelstats` SET `basearmor` = 1272 WHERE `level` = 37 AND `class` = 2; -- was 1567
UPDATE `creature_classlevelstats` SET `basearmor` = 1363 WHERE `level` = 38 AND `class` = 2; -- was 1683
UPDATE `creature_classlevelstats` SET `basearmor` = 1461 WHERE `level` = 39 AND `class` = 2; -- was 1807
UPDATE `creature_classlevelstats` SET `basearmor` = 1561 WHERE `level` = 40 AND `class` = 2; -- was 1937
UPDATE `creature_classlevelstats` SET `basearmor` = 1668 WHERE `level` = 41 AND `class` = 2; -- was 2072
UPDATE `creature_classlevelstats` SET `basearmor` = 1782 WHERE `level` = 42 AND `class` = 2; -- was 2216
UPDATE `creature_classlevelstats` SET `basearmor` = 1897 WHERE `level` = 43 AND `class` = 2; -- was 2367
UPDATE `creature_classlevelstats` SET `basearmor` = 2020 WHERE `level` = 44 AND `class` = 2; -- was 2527
UPDATE `creature_classlevelstats` SET `basearmor` = 2147 WHERE `level` = 45 AND `class` = 2; -- was 2692
UPDATE `creature_classlevelstats` SET `basearmor` = 2190 WHERE `level` = 46 AND `class` = 2; -- was 2749
UPDATE `creature_classlevelstats` SET `basearmor` = 2234 WHERE `level` = 47 AND `class` = 2; -- was 2802
UPDATE `creature_classlevelstats` SET `basearmor` = 2276 WHERE `level` = 48 AND `class` = 2; -- was 2855
UPDATE `creature_classlevelstats` SET `basearmor` = 2320 WHERE `level` = 49 AND `class` = 2; -- was 2910
UPDATE `creature_classlevelstats` SET `basearmor` = 2361 WHERE `level` = 50 AND `class` = 2; -- was 2964
UPDATE `creature_classlevelstats` SET `basearmor` = 2405 WHERE `level` = 51 AND `class` = 2; -- was 3017
UPDATE `creature_classlevelstats` SET `basearmor` = 2449 WHERE `level` = 52 AND `class` = 2; -- was 3072
UPDATE `creature_classlevelstats` SET `basearmor` = 2491 WHERE `level` = 53 AND `class` = 2; -- was 3126
UPDATE `creature_classlevelstats` SET `basearmor` = 2534 WHERE `level` = 54 AND `class` = 2; -- was 3178
UPDATE `creature_classlevelstats` SET `basearmor` = 2576 WHERE `level` = 55 AND `class` = 2; -- was 3232
UPDATE `creature_classlevelstats` SET `basearmor` = 2620 WHERE `level` = 56 AND `class` = 2; -- was 3287
UPDATE `creature_classlevelstats` SET `basearmor` = 2664 WHERE `level` = 57 AND `class` = 2; -- was 3340
UPDATE `creature_classlevelstats` SET `basearmor` = 2706 WHERE `level` = 58 AND `class` = 2; -- was 3394
UPDATE `creature_classlevelstats` SET `basearmor` = 2749 WHERE `level` = 59 AND `class` = 2; -- was 3447
UPDATE `creature_classlevelstats` SET `basearmor` = 2791 WHERE `level` = 60 AND `class` = 2; -- was 3748
UPDATE `creature_classlevelstats` SET `basearmor` = 0 WHERE `level` = 1 AND `class` = 8; -- was 5
UPDATE `creature_classlevelstats` SET `basearmor` = 0 WHERE `level` = 2 AND `class` = 8; -- was 16
UPDATE `creature_classlevelstats` SET `basearmor` = 0 WHERE `level` = 3 AND `class` = 8; -- was 28
UPDATE `creature_classlevelstats` SET `basearmor` = 19 WHERE `level` = 4 AND `class` = 8; -- was 57
UPDATE `creature_classlevelstats` SET `basearmor` = 28 WHERE `level` = 5 AND `class` = 8; -- was 93
UPDATE `creature_classlevelstats` SET `basearmor` = 48 WHERE `level` = 6 AND `class` = 8; -- was 139
UPDATE `creature_classlevelstats` SET `basearmor` = 111 WHERE `level` = 7 AND `class` = 8; -- was 194
UPDATE `creature_classlevelstats` SET `basearmor` = 151 WHERE `level` = 8 AND `class` = 8; -- was 265
UPDATE `creature_classlevelstats` SET `basearmor` = 198 WHERE `level` = 9 AND `class` = 8; -- was 339
UPDATE `creature_classlevelstats` SET `basearmor` = 248 WHERE `level` = 10 AND `class` = 8; -- was 423
UPDATE `creature_classlevelstats` SET `basearmor` = 264 WHERE `level` = 11 AND `class` = 8; -- was 447
UPDATE `creature_classlevelstats` SET `basearmor` = 283 WHERE `level` = 12 AND `class` = 8; -- was 475
UPDATE `creature_classlevelstats` SET `basearmor` = 303 WHERE `level` = 13 AND `class` = 8; -- was 509
UPDATE `creature_classlevelstats` SET `basearmor` = 322 WHERE `level` = 14 AND `class` = 8; -- was 523
UPDATE `creature_classlevelstats` SET `basearmor` = 340 WHERE `level` = 15 AND `class` = 8; -- was 559
UPDATE `creature_classlevelstats` SET `basearmor` = 360 WHERE `level` = 16 AND `class` = 8; -- was 589
UPDATE `creature_classlevelstats` SET `basearmor` = 379 WHERE `level` = 17 AND `class` = 8; -- was 617
UPDATE `creature_classlevelstats` SET `basearmor` = 399 WHERE `level` = 18 AND `class` = 8; -- was 643
UPDATE `creature_classlevelstats` SET `basearmor` = 419 WHERE `level` = 19 AND `class` = 8; -- was 674
UPDATE `creature_classlevelstats` SET `basearmor` = 436 WHERE `level` = 20 AND `class` = 8; -- was 701
UPDATE `creature_classlevelstats` SET `basearmor` = 456 WHERE `level` = 21 AND `class` = 8; -- was 729
UPDATE `creature_classlevelstats` SET `basearmor` = 475 WHERE `level` = 22 AND `class` = 8; -- was 759
UPDATE `creature_classlevelstats` SET `basearmor` = 495 WHERE `level` = 23 AND `class` = 8; -- was 786
UPDATE `creature_classlevelstats` SET `basearmor` = 513 WHERE `level` = 24 AND `class` = 8; -- was 815
UPDATE `creature_classlevelstats` SET `basearmor` = 532 WHERE `level` = 25 AND `class` = 8; -- was 843
UPDATE `creature_classlevelstats` SET `basearmor` = 552 WHERE `level` = 26 AND `class` = 8; -- was 871
UPDATE `creature_classlevelstats` SET `basearmor` = 571 WHERE `level` = 27 AND `class` = 8; -- was 900
UPDATE `creature_classlevelstats` SET `basearmor` = 591 WHERE `level` = 28 AND `class` = 8; -- was 928
UPDATE `creature_classlevelstats` SET `basearmor` = 609 WHERE `level` = 29 AND `class` = 8; -- was 957
UPDATE `creature_classlevelstats` SET `basearmor` = 628 WHERE `level` = 30 AND `class` = 8; -- was 984
UPDATE `creature_classlevelstats` SET `basearmor` = 648 WHERE `level` = 31 AND `class` = 8; -- was 1012
UPDATE `creature_classlevelstats` SET `basearmor` = 668 WHERE `level` = 32 AND `class` = 8; -- was 1042
UPDATE `creature_classlevelstats` SET `basearmor` = 685 WHERE `level` = 33 AND `class` = 8; -- was 1065
UPDATE `creature_classlevelstats` SET `basearmor` = 705 WHERE `level` = 34 AND `class` = 8; -- was 1098
UPDATE `creature_classlevelstats` SET `basearmor` = 724 WHERE `level` = 35 AND `class` = 8; -- was 1124
UPDATE `creature_classlevelstats` SET `basearmor` = 775 WHERE `level` = 36 AND `class` = 8; -- was 1241
UPDATE `creature_classlevelstats` SET `basearmor` = 830 WHERE `level` = 37 AND `class` = 8; -- was 1300
UPDATE `creature_classlevelstats` SET `basearmor` = 887 WHERE `level` = 38 AND `class` = 8; -- was 1391
UPDATE `creature_classlevelstats` SET `basearmor` = 946 WHERE `level` = 39 AND `class` = 8; -- was 1489
UPDATE `creature_classlevelstats` SET `basearmor` = 1006 WHERE `level` = 40 AND `class` = 8; -- was 1590
UPDATE `creature_classlevelstats` SET `basearmor` = 1069 WHERE `level` = 41 AND `class` = 8; -- was 1697
UPDATE `creature_classlevelstats` SET `basearmor` = 1136 WHERE `level` = 42 AND `class` = 8; -- was 1811
UPDATE `creature_classlevelstats` SET `basearmor` = 1205 WHERE `level` = 43 AND `class` = 8; -- was 1926
UPDATE `creature_classlevelstats` SET `basearmor` = 1274 WHERE `level` = 44 AND `class` = 8; -- was 2078
UPDATE `creature_classlevelstats` SET `basearmor` = 1348 WHERE `level` = 45 AND `class` = 8; -- was 2177
UPDATE `creature_classlevelstats` SET `basearmor` = 1376 WHERE `level` = 46 AND `class` = 8; -- was 2220
UPDATE `creature_classlevelstats` SET `basearmor` = 1403 WHERE `level` = 47 AND `class` = 8; -- was 2265
UPDATE `creature_classlevelstats` SET `basearmor` = 1431 WHERE `level` = 48 AND `class` = 8; -- was 2307
UPDATE `creature_classlevelstats` SET `basearmor` = 1459 WHERE `level` = 49 AND `class` = 8; -- was 2349
UPDATE `creature_classlevelstats` SET `basearmor` = 1486 WHERE `level` = 50 AND `class` = 8; -- was 2393
UPDATE `creature_classlevelstats` SET `basearmor` = 1514 WHERE `level` = 51 AND `class` = 8; -- was 2437
UPDATE `creature_classlevelstats` SET `basearmor` = 1542 WHERE `level` = 52 AND `class` = 8; -- was 2481
UPDATE `creature_classlevelstats` SET `basearmor` = 1569 WHERE `level` = 53 AND `class` = 8; -- was 2524
UPDATE `creature_classlevelstats` SET `basearmor` = 1597 WHERE `level` = 54 AND `class` = 8; -- was 2567
UPDATE `creature_classlevelstats` SET `basearmor` = 1625 WHERE `level` = 55 AND `class` = 8; -- was 2609
UPDATE `creature_classlevelstats` SET `basearmor` = 1652 WHERE `level` = 56 AND `class` = 8; -- was 2654
UPDATE `creature_classlevelstats` SET `basearmor` = 1680 WHERE `level` = 57 AND `class` = 8; -- was 2698
UPDATE `creature_classlevelstats` SET `basearmor` = 1708 WHERE `level` = 58 AND `class` = 8; -- was 2740
UPDATE `creature_classlevelstats` SET `basearmor` = 1735 WHERE `level` = 59 AND `class` = 8; -- was 2784
UPDATE `creature_classlevelstats` SET `basearmor` = 1763 WHERE `level` = 60 AND `class` = 8; -- was 3025

-- Creature ranged attack power, unit_class 1, 2 and 8, levels 1-60 (vmangos ranged_attack_power).
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 20 WHERE `level` = 1 AND `class` = 1; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 22 WHERE `level` = 2 AND `class` = 1; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 22 WHERE `level` = 3 AND `class` = 1; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 24 WHERE `level` = 4 AND `class` = 1; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 26 WHERE `level` = 5 AND `class` = 1; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 28 WHERE `level` = 6 AND `class` = 1; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 28 WHERE `level` = 7 AND `class` = 1; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 30 WHERE `level` = 8 AND `class` = 1; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 32 WHERE `level` = 9 AND `class` = 1; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 32 WHERE `level` = 10 AND `class` = 1; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 34 WHERE `level` = 11 AND `class` = 1; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 36 WHERE `level` = 12 AND `class` = 1; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 40 WHERE `level` = 13 AND `class` = 1; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 42 WHERE `level` = 14 AND `class` = 1; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 44 WHERE `level` = 15 AND `class` = 1; -- was 2
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 46 WHERE `level` = 16 AND `class` = 1; -- was 2
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 48 WHERE `level` = 17 AND `class` = 1; -- was 2
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 52 WHERE `level` = 18 AND `class` = 1; -- was 3
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 54 WHERE `level` = 19 AND `class` = 1; -- was 3
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 58 WHERE `level` = 20 AND `class` = 1; -- was 4
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 58 WHERE `level` = 21 AND `class` = 1; -- was 4
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 60 WHERE `level` = 22 AND `class` = 1; -- was 4
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 64 WHERE `level` = 23 AND `class` = 1; -- was 5
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 66 WHERE `level` = 24 AND `class` = 1; -- was 6
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 70 WHERE `level` = 25 AND `class` = 1; -- was 6
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 72 WHERE `level` = 26 AND `class` = 1; -- was 7
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 74 WHERE `level` = 27 AND `class` = 1; -- was 7
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 78 WHERE `level` = 28 AND `class` = 1; -- was 8
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 80 WHERE `level` = 29 AND `class` = 1; -- was 8
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 84 WHERE `level` = 30 AND `class` = 1; -- was 9
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 86 WHERE `level` = 31 AND `class` = 1; -- was 9
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 88 WHERE `level` = 32 AND `class` = 1; -- was 10
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 92 WHERE `level` = 33 AND `class` = 1; -- was 10
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 94 WHERE `level` = 34 AND `class` = 1; -- was 11
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 98 WHERE `level` = 35 AND `class` = 1; -- was 11
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 100 WHERE `level` = 36 AND `class` = 1; -- was 12
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 102 WHERE `level` = 37 AND `class` = 1; -- was 12
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 106 WHERE `level` = 38 AND `class` = 1; -- was 13
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 108 WHERE `level` = 39 AND `class` = 1; -- was 13
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 112 WHERE `level` = 40 AND `class` = 1; -- was 14
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 116 WHERE `level` = 41 AND `class` = 1; -- was 15
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 118 WHERE `level` = 42 AND `class` = 1; -- was 15
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 122 WHERE `level` = 43 AND `class` = 1; -- was 16
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 124 WHERE `level` = 44 AND `class` = 1; -- was 16
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 128 WHERE `level` = 45 AND `class` = 1; -- was 17
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 130 WHERE `level` = 46 AND `class` = 1; -- was 17
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 134 WHERE `level` = 47 AND `class` = 1; -- was 18
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 138 WHERE `level` = 48 AND `class` = 1; -- was 19
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 140 WHERE `level` = 49 AND `class` = 1; -- was 19
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 144 WHERE `level` = 50 AND `class` = 1; -- was 20
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 148 WHERE `level` = 51 AND `class` = 1; -- was 20
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 150 WHERE `level` = 52 AND `class` = 1; -- was 21
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 154 WHERE `level` = 53 AND `class` = 1; -- was 22
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 158 WHERE `level` = 54 AND `class` = 1; -- was 22
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 162 WHERE `level` = 55 AND `class` = 1; -- was 23
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 164 WHERE `level` = 56 AND `class` = 1; -- was 23
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 168 WHERE `level` = 57 AND `class` = 1; -- was 24
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 172 WHERE `level` = 58 AND `class` = 1; -- was 25
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 176 WHERE `level` = 59 AND `class` = 1; -- was 25
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 180 WHERE `level` = 60 AND `class` = 1; -- was 26
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 20 WHERE `level` = 1 AND `class` = 2; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 22 WHERE `level` = 2 AND `class` = 2; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 22 WHERE `level` = 3 AND `class` = 2; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 24 WHERE `level` = 4 AND `class` = 2; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 24 WHERE `level` = 5 AND `class` = 2; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 26 WHERE `level` = 6 AND `class` = 2; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 26 WHERE `level` = 7 AND `class` = 2; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 28 WHERE `level` = 8 AND `class` = 2; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 28 WHERE `level` = 9 AND `class` = 2; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 30 WHERE `level` = 10 AND `class` = 2; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 30 WHERE `level` = 11 AND `class` = 2; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 32 WHERE `level` = 12 AND `class` = 2; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 36 WHERE `level` = 13 AND `class` = 2; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 36 WHERE `level` = 14 AND `class` = 2; -- was 1
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 40 WHERE `level` = 15 AND `class` = 2; -- was 2
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 40 WHERE `level` = 16 AND `class` = 2; -- was 2
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 42 WHERE `level` = 17 AND `class` = 2; -- was 2
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 46 WHERE `level` = 18 AND `class` = 2; -- was 3
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 46 WHERE `level` = 19 AND `class` = 2; -- was 3
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 50 WHERE `level` = 20 AND `class` = 2; -- was 4
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 52 WHERE `level` = 21 AND `class` = 2; -- was 4
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 52 WHERE `level` = 22 AND `class` = 2; -- was 5
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 56 WHERE `level` = 23 AND `class` = 2; -- was 5
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 58 WHERE `level` = 24 AND `class` = 2; -- was 6
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 60 WHERE `level` = 25 AND `class` = 2; -- was 6
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 62 WHERE `level` = 26 AND `class` = 2; -- was 6
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 64 WHERE `level` = 27 AND `class` = 2; -- was 7
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 66 WHERE `level` = 28 AND `class` = 2; -- was 7
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 68 WHERE `level` = 29 AND `class` = 2; -- was 8
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 72 WHERE `level` = 30 AND `class` = 2; -- was 8
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 74 WHERE `level` = 31 AND `class` = 2; -- was 9
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 74 WHERE `level` = 32 AND `class` = 2; -- was 9
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 78 WHERE `level` = 33 AND `class` = 2; -- was 10
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 80 WHERE `level` = 34 AND `class` = 2; -- was 10
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 84 WHERE `level` = 35 AND `class` = 2; -- was 11
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 86 WHERE `level` = 36 AND `class` = 2; -- was 11
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 86 WHERE `level` = 37 AND `class` = 2; -- was 11
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 90 WHERE `level` = 38 AND `class` = 2; -- was 12
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 92 WHERE `level` = 39 AND `class` = 2; -- was 12
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 96 WHERE `level` = 40 AND `class` = 2; -- was 13
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 98 WHERE `level` = 41 AND `class` = 2; -- was 13
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 98 WHERE `level` = 42 AND `class` = 2; -- was 15
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 102 WHERE `level` = 43 AND `class` = 2; -- was 14
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 104 WHERE `level` = 44 AND `class` = 2; -- was 15
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 108 WHERE `level` = 45 AND `class` = 2; -- was 15
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 110 WHERE `level` = 46 AND `class` = 2; -- was 16
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 112 WHERE `level` = 47 AND `class` = 2; -- was 16
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 116 WHERE `level` = 48 AND `class` = 2; -- was 17
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 118 WHERE `level` = 49 AND `class` = 2; -- was 17
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 122 WHERE `level` = 50 AND `class` = 2; -- was 18
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 124 WHERE `level` = 51 AND `class` = 2; -- was 19
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 126 WHERE `level` = 52 AND `class` = 2; -- was 19
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 130 WHERE `level` = 53 AND `class` = 2; -- was 20
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 132 WHERE `level` = 54 AND `class` = 2; -- was 20
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 136 WHERE `level` = 55 AND `class` = 2; -- was 21
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 138 WHERE `level` = 56 AND `class` = 2; -- was 21
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 140 WHERE `level` = 57 AND `class` = 2; -- was 22
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 144 WHERE `level` = 58 AND `class` = 2; -- was 23
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 146 WHERE `level` = 59 AND `class` = 2; -- was 23
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 150 WHERE `level` = 60 AND `class` = 2; -- was 24
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 18 WHERE `level` = 1 AND `class` = 8; -- was 10
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 20 WHERE `level` = 2 AND `class` = 8; -- was 10
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 20 WHERE `level` = 3 AND `class` = 8; -- was 10
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 22 WHERE `level` = 4 AND `class` = 8; -- was 11
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 22 WHERE `level` = 5 AND `class` = 8; -- was 11
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 22 WHERE `level` = 6 AND `class` = 8; -- was 11
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 22 WHERE `level` = 7 AND `class` = 8; -- was 11
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 22 WHERE `level` = 8 AND `class` = 8; -- was 11
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 22 WHERE `level` = 9 AND `class` = 8; -- was 11
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 24 WHERE `level` = 10 AND `class` = 8; -- was 12
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 24 WHERE `level` = 11 AND `class` = 8; -- was 12
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 24 WHERE `level` = 12 AND `class` = 8; -- was 12
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 24 WHERE `level` = 13 AND `class` = 8; -- was 12
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 24 WHERE `level` = 14 AND `class` = 8; -- was 12
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 26 WHERE `level` = 15 AND `class` = 8; -- was 13
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 26 WHERE `level` = 16 AND `class` = 8; -- was 13
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 26 WHERE `level` = 17 AND `class` = 8; -- was 13
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 26 WHERE `level` = 18 AND `class` = 8; -- was 13
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 26 WHERE `level` = 19 AND `class` = 8; -- was 13
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 28 WHERE `level` = 20 AND `class` = 8; -- was 14
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 28 WHERE `level` = 21 AND `class` = 8; -- was 14
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 28 WHERE `level` = 22 AND `class` = 8; -- was 14
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 28 WHERE `level` = 23 AND `class` = 8; -- was 14
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 30 WHERE `level` = 24 AND `class` = 8; -- was 15
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 30 WHERE `level` = 25 AND `class` = 8; -- was 15
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 30 WHERE `level` = 26 AND `class` = 8; -- was 15
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 30 WHERE `level` = 27 AND `class` = 8; -- was 15
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 30 WHERE `level` = 28 AND `class` = 8; -- was 15
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 32 WHERE `level` = 29 AND `class` = 8; -- was 16
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 32 WHERE `level` = 30 AND `class` = 8; -- was 16
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 32 WHERE `level` = 31 AND `class` = 8; -- was 16
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 32 WHERE `level` = 32 AND `class` = 8; -- was 16
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 34 WHERE `level` = 33 AND `class` = 8; -- was 17
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 34 WHERE `level` = 34 AND `class` = 8; -- was 17
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 34 WHERE `level` = 35 AND `class` = 8; -- was 17
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 36 WHERE `level` = 36 AND `class` = 8; -- was 18
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 36 WHERE `level` = 37 AND `class` = 8; -- was 18
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 36 WHERE `level` = 38 AND `class` = 8; -- was 18
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 36 WHERE `level` = 39 AND `class` = 8; -- was 18
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 38 WHERE `level` = 40 AND `class` = 8; -- was 19
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 38 WHERE `level` = 41 AND `class` = 8; -- was 19
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 38 WHERE `level` = 42 AND `class` = 8; -- was 19
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 38 WHERE `level` = 43 AND `class` = 8; -- was 19
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 40 WHERE `level` = 44 AND `class` = 8; -- was 20
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 40 WHERE `level` = 45 AND `class` = 8; -- was 20
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 40 WHERE `level` = 46 AND `class` = 8; -- was 20
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 42 WHERE `level` = 47 AND `class` = 8; -- was 21
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 42 WHERE `level` = 48 AND `class` = 8; -- was 21
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 42 WHERE `level` = 49 AND `class` = 8; -- was 21
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 44 WHERE `level` = 50 AND `class` = 8; -- was 22
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 44 WHERE `level` = 51 AND `class` = 8; -- was 22
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 44 WHERE `level` = 52 AND `class` = 8; -- was 22
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 46 WHERE `level` = 53 AND `class` = 8; -- was 23
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 46 WHERE `level` = 54 AND `class` = 8; -- was 23
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 46 WHERE `level` = 55 AND `class` = 8; -- was 23
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 48 WHERE `level` = 56 AND `class` = 8; -- was 24
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 48 WHERE `level` = 57 AND `class` = 8; -- was 24
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 48 WHERE `level` = 58 AND `class` = 8; -- was 24
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 50 WHERE `level` = 59 AND `class` = 8; -- was 25
UPDATE `creature_classlevelstats` SET `rangedattackpower` = 50 WHERE `level` = 60 AND `class` = 8; -- was 25

-- Melee damage of creatures whose vmangos damage_multiplier comes from 1.12 combat captures
-- (migrations 20231011030405 and 20231113003847). AzerothCore scales a hit by BaseAttackTime and vmangos
-- does not, so DamageModifier = vanilla hit / ((1.25 * damage_base + AP / 14) * BaseAttackTime / 1000),
-- at the vanilla attack time and levels. Scripted raid and world bosses are not included.
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 234; -- Gryan Stoutmantle (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.6 WHERE `entry` = 264; -- Commander Althea Ebonlocke (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.6 WHERE `entry` = 335; -- Singe (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 349; -- Corporal Keeshan (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 522; -- MorLadim (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 575; -- Fire Elemental (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 583; -- Defias Ambusher (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 596; -- Brainwashed Noble (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 599; -- Marisa duPaige (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.075 WHERE `entry` = 691; -- Lesser Water Elemental (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.308 WHERE `entry` = 1061; -- Ganzulah (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 1200; -- Morbent Fel (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 0.933 WHERE `entry` = 1379; -- Miran (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 1436; -- Watcher Cutford (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 1489; -- Zanzil Hunter (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.635 WHERE `entry` = 1501; -- Mindless Zombie (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 1522; -- Darkeye Bonecaster (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.85 WHERE `entry` = 1525; -- Rotting Dead (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 1526; -- Ravaged Corpse (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 1529; -- Bleeding Horror (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 1531; -- Lost Soul (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 1656; -- Thurman Agamand (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 1657; -- Devlin Agamand (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.6 WHERE `entry` = 1729; -- Defias Evoker (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 2.3 WHERE `entry` = 1763; -- Gilnid (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 1842; -- Highlord Taelan Fordring (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 2.2 WHERE `entry` = 1852; -- Araj the Summoner (was 2)
UPDATE `creature_template` SET `DamageModifier` = 2.5 WHERE `entry` = 1853; -- Darkmaster Gandling (was 2.3)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 1855; -- Tirion Fordring (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 0.65 WHERE `entry` = 1890; -- Rattlecage Skeleton (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.8 WHERE `entry` = 1916; -- Stephen Bhartec (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.85 WHERE `entry` = 1917; -- Daniel Ulfman (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 1918; -- Karrel Grayves (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.85 WHERE `entry` = 1919; -- Samuel Fipps (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.933 WHERE `entry` = 1943; -- Raging Rot Hide (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.85 WHERE `entry` = 2022; -- Timberling (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.6 WHERE `entry` = 2041; -- Ancient Protector (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.253 WHERE `entry` = 2060; -- Councilman Smithers (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1, `BaseAttackTime` = 2000 WHERE `entry` = 2159; -- was 1, 1800
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 2162; -- Agal (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 2189; -- Vile Sprite (was 1)
UPDATE `creature_template` SET `DamageModifier` = 10 WHERE `entry` = 2215; -- High Executor Darthalia (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 2.077 WHERE `entry` = 2275; -- Enraged Stanley (was 1)
UPDATE `creature_template` SET `DamageModifier` = 10 WHERE `entry` = 2276; -- Magistrate Henry Maleb (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 2359; -- Elemental Slave (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 2386; -- Southshore Guard (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 2415; -- Warden Belamoore (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.5 WHERE `entry` = 2433; -- Helculars Remains (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5.35 WHERE `entry` = 2447; -- Narillasanz (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 0.8 WHERE `entry` = 2462; -- Flesh Eating Worm (was 0.5)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 2520; -- Remote-Controlled Golem (was 2)
UPDATE `creature_template` SET `DamageModifier` = 0.4 WHERE `entry` = 2540; -- Dalaran Serpent (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.125 WHERE `entry` = 2694; -- Highvale Ranger (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.7, `BaseAttackTime` = 2000 WHERE `entry` = 2753; -- was 1, 1600
UPDATE `creature_template` SET `DamageModifier` = 3.833, `BaseAttackTime` = 3000 WHERE `entry` = 2754; -- was 3.75, 2000
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 2755; -- Myzrael (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.2 WHERE `entry` = 2763; -- Thenan (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 2946; -- Puppet of Helcular (was 5)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 2951; -- Palemane Poacher (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.85 WHERE `entry` = 2975; -- Venture Co. Hireling (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.911 WHERE `entry` = 2990; -- Baeldun Appraiser (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.85 WHERE `entry` = 3229; -- Squealer Thornmantle (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.95 WHERE `entry` = 3263; -- Bristleback Geomancer (was 1)
UPDATE `creature_template` SET `DamageModifier` = 10 WHERE `entry` = 3338; -- Sergra Darkthorn (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 1.562 WHERE `entry` = 3392; -- Prospector Khazgorm (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.933 WHERE `entry` = 3395; -- Verog the Dervish (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.4 WHERE `entry` = 3398; -- Gesharahan (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 0.45 WHERE `entry` = 3417; -- Living Flame (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 3479; -- Nargal Deatheye (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 3485; -- Wrahk (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.85, `BaseAttackTime` = 2000 WHERE `entry` = 3568; -- was 1, 1500
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 3678; -- Disciple of Naralex (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 3799; -- Severed Druid (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.635 WHERE `entry` = 3835; -- Biletoad (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1.6 WHERE `entry` = 3854; -- Shadowfang Wolfguard (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1.5 WHERE `entry` = 3872; -- Deathsworn Captain (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1, `BaseAttackTime` = 2000 WHERE `entry` = 3893; -- was 1, 1750
UPDATE `creature_template` SET `DamageModifier` = 0.95 WHERE `entry` = 3899; -- Balizar the Umbrage (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.6 WHERE `entry` = 3974; -- Houndmaster Loksey (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.52 WHERE `entry` = 3975; -- Herod (was 3.8)
UPDATE `creature_template` SET `DamageModifier` = 1.654 WHERE `entry` = 4066; -- Naltaszar (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.5 WHERE `entry` = 4278; -- Commander Springvale (was 2.3)
UPDATE `creature_template` SET `DamageModifier` = 1.9 WHERE `entry` = 4300; -- Scarlet Wizard (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 2.65 WHERE `entry` = 4339; -- Brimgore (was 2.5)
UPDATE `creature_template` SET `DamageModifier` = 1.2 WHERE `entry` = 4405; -- Muckshell Razorclaw (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.6 WHERE `entry` = 4418; -- Defias Wizard (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1.6 WHERE `entry` = 4420; -- Overlord Ramtusk (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 4499; -- RokAlim the Pounder (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3.467 WHERE `entry` = 4500; -- Overlord MokMorokk (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 4526; -- Wind Howler (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 4528; -- Stone Rumbler (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1.25 WHERE `entry` = 4534; -- Tamed Hyena (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 4535; -- Tamed Battleboar (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 2.933 WHERE `entry` = 4686; -- Deepstrider Giant (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.933 WHERE `entry` = 4687; -- Deepstrider Searcher (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 0.75 WHERE `entry` = 4823; -- Barbed Crustacean (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 0.75 WHERE `entry` = 4825; -- Akumai Snapjaw (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 4.5 WHERE `entry` = 4829; -- Akumai (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 4857; -- Stone Keeper (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 4860; -- Stone Steward (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.9 WHERE `entry` = 4861; -- Shrike Bat (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1, `BaseAttackTime` = 2000 WHERE `entry` = 4958; -- was 1, 1800
UPDATE `creature_template` SET `DamageModifier` = 0.7 WHERE `entry` = 4977; -- Murkshallow Softshell (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.2 WHERE `entry` = 4978; -- Akumai Servant (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 4979; -- Theramore Guard (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 4995; -- Stockade Guard (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.1 WHERE `entry` = 5081; -- Connor Rivers (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.4 WHERE `entry` = 5097; -- Lupine Delusion (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.8 WHERE `entry` = 5226; -- Murk Worm (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.8 WHERE `entry` = 5228; -- Saturated Ooze (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.9 WHERE `entry` = 5256; -- Atalai Warrior (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 5259; -- Atalai Witch Doctor (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.1 WHERE `entry` = 5271; -- Atalai Deathwalker (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.1 WHERE `entry` = 5273; -- Atalai High Priest (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.1 WHERE `entry` = 5277; -- Nightmare Scalebane (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.1 WHERE `entry` = 5280; -- Nightmare Wyrmkin (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 5291; -- Hakkari Frostwing (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 5314; -- Phantim (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 1, `BaseAttackTime` = 2000 WHERE `entry` = 5346; -- was 1, 1250
UPDATE `creature_template` SET `DamageModifier` = 1.385 WHERE `entry` = 5357; -- Land Walker (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.481 WHERE `entry` = 5358; -- Cliff Giant (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.148 WHERE `entry` = 5359; -- Shore Strider (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.889 WHERE `entry` = 5360; -- Deep Strider (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 5466; -- Coast Strider (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.958 WHERE `entry` = 5469; -- Dune Smasher (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 5676; -- Summoned Voidwalker (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.85 WHERE `entry` = 5680; -- Male Human Captive (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 5685; -- Captive Ghoul (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 5686; -- Captive Zombie (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 5708; -- Spawn of Hakkar (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 5709; -- Shade of Eranikus (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.4 WHERE `entry` = 5710; -- Jammalan the Prophet (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.4 WHERE `entry` = 5711; -- Ogom the Wretched (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 5712; -- Zolo (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 5713; -- Gasher (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.25 WHERE `entry` = 5715; -- Hukku (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.4 WHERE `entry` = 5716; -- ZulLor (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.2 WHERE `entry` = 5717; -- Mijan (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 16.5 WHERE `entry` = 5718; -- Rothos (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 5762; -- Deviate Moccasin (was 1.8)
UPDATE `creature_template` SET `DamageModifier` = 4.629 WHERE `entry` = 5775; -- Verdan the Everliving (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.6 WHERE `entry` = 5780; -- Cloned Ectoplasm (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 5785; -- Sister Hatelash (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 5787; -- Enforcer Emilgund (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 5798; -- Thora Feathermoon (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.25 WHERE `entry` = 5847; -- Heggin Stonewhisker (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.704 WHERE `entry` = 5859; -- Hagg Taurenbane (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 5916; -- Sentinel Amarassan (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 5917; -- Clara Charles (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.65 WHERE `entry` = 5930; -- Sister Riven (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.4 WHERE `entry` = 5932; -- Taskmaster Whipfang (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 0.2 WHERE `entry` = 5955; -- Tooga (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.075 WHERE `entry` = 5974; -- Dreadmaul Ogre (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 6090; -- Bartleby (was 1)
UPDATE `creature_template` SET `DamageModifier` = 5.3 WHERE `entry` = 6140; -- Hetaera (was 1)
UPDATE `creature_template` SET `DamageModifier` = 4.714 WHERE `entry` = 6144; -- Son of Arkkoroc (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 0.635 WHERE `entry` = 6145; -- School of Fish (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.52 WHERE `entry` = 6146; -- Cliff Breaker (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.36 WHERE `entry` = 6147; -- Cliff Thunderer (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.6 WHERE `entry` = 6168; -- Roogug (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1.667 WHERE `entry` = 6210; -- Caverndeep Pillager (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.65 WHERE `entry` = 6228; -- Dark Iron Ambassador (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 6237; -- Stockade Archer (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 6239; -- Cyclonian (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 6426; -- Anguished Dead (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 6427; -- Haunting Phantasm (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 6487; -- Arcanist Doan (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 6488; -- Fallen Champion (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 6489; -- Ironspine (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 6490; -- Azshir the Sleepless (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 6493; -- Illusionary Phantasm (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 6549; -- Demon of the Orb (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4.2 WHERE `entry` = 6560; -- Stone Guardian (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 4.7 WHERE `entry` = 6583; -- Gruff (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 0.86 WHERE `entry` = 6607; -- Harroc (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.85 WHERE `entry` = 6784; -- Calvin Montague (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 6906; -- Baelog (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 6907; -- Eric The Swift (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 0.25 WHERE `entry` = 6908; -- Olaf (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 6910; -- Revelosh (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 0.85 WHERE `entry` = 6927; -- Defias Dockworker (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.148 WHERE `entry` = 7011; -- Earthen Rocksmasher (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.15 WHERE `entry` = 7012; -- Earthen Sculptor (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 7022; -- Venomlash Scorpid (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 7030; -- Shadowforge Geologist (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.217 WHERE `entry` = 7076; -- Earthen Guardian (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.2 WHERE `entry` = 7077; -- Earthen Hallshaper (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 7078; -- Cleft Scorpid (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 7206; -- Ancient Stone Keeper (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.923, `BaseAttackTime` = 1300 WHERE `entry` = 7209; -- was 1, 2000
UPDATE `creature_template` SET `DamageModifier` = 0.1 WHERE `entry` = 7226; -- Sand Storm (was 1)
UPDATE `creature_template` SET `DamageModifier` = 4.483 WHERE `entry` = 7228; -- Ironaya (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.2 WHERE `entry` = 7233; -- Taskmaster Fizzule (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.6 WHERE `entry` = 7247; -- Sandfury Soul Eater (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.588 WHERE `entry` = 7268; -- Sandfury Guardian (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.6 WHERE `entry` = 7271; -- Witch Doctor Zumrah (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.7 WHERE `entry` = 7275; -- Shadowpriest Sezzziz (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.4 WHERE `entry` = 7286; -- ZulFarrak Zombie (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.6 WHERE `entry` = 7288; -- Grand Foreman Puzik Gallywix (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 7328; -- Withered Reaver (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1.8 WHERE `entry` = 7341; -- Skeletal Frostweaver (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 7342; -- Skeletal Summoner (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1.5 WHERE `entry` = 7344; -- Splinterbone Warrior (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 7345; -- Splinterbone Captain (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1.9 WHERE `entry` = 7347; -- Boneflayer Ghoul (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1.8 WHERE `entry` = 7348; -- Thorn Eater Ghoul (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 7351; -- Tomb Reaver (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.8 WHERE `entry` = 7352; -- Frozen Soul (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 7353; -- Freezing Spirit (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 7354; -- Ragglesnout (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.5 WHERE `entry` = 7355; -- Tutenkash (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 7356; -- Plaguemaw the Rotting (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 7357; -- Mordresh Fire Eye (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 4.2 WHERE `entry` = 7358; -- Amnennar the Coldbringer (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 2.4 WHERE `entry` = 7361; -- Grubbis (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.259 WHERE `entry` = 7396; -- Earthen Stonebreaker (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.5 WHERE `entry` = 7397; -- Earthen Stonecarver (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 4.1 WHERE `entry` = 7428; -- Frostmaul Giant (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 7429; -- Frostmaul Preserver (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.4 WHERE `entry` = 7435; -- Cobalt Wyrmkin (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.8 WHERE `entry` = 7436; -- Cobalt Scalebane (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.8 WHERE `entry` = 7437; -- Cobalt Mageweaver (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 7462; -- Hederine Manastalker (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 6.2 WHERE `entry` = 7463; -- Hederine Slayer (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.25 WHERE `entry` = 7604; -- Sergeant Bly (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.2 WHERE `entry` = 7606; -- Oro Eyegouge (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.15 WHERE `entry` = 7607; -- Weegli Blastfuse (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.2 WHERE `entry` = 7608; -- Murta Grimgut (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 7664; -- Razelikh the Defiler (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6.5 WHERE `entry` = 7665; -- Grol the Destroyer (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 7734; -- Ilifar (was 1)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 7735; -- Felcular (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.8 WHERE `entry` = 7768; -- Witherbark Bloodling (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.8 WHERE `entry` = 7769; -- Hazzali Parasite (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3.615 WHERE `entry` = 7797; -- Ruuzlu (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.9 WHERE `entry` = 7875; -- Hadoken Swiftstrider (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 7998; -- Blastmaster Emi Shortfuse (was 1.7)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 8115; -- Witch Doctor Uzeri (was 1)
UPDATE `creature_template` SET `DamageModifier` = 4.3 WHERE `entry` = 8127; -- Antusul (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.8 WHERE `entry` = 8196; -- Occulus (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 9 WHERE `entry` = 8197; -- Chronalis (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 2.9 WHERE `entry` = 8198; -- Tick (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.1 WHERE `entry` = 8212; -- The Reak (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3.5 WHERE `entry` = 8317; -- Atalai Deathwalkers Spirit (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 8336; -- Hakkari Sapper (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 8438; -- Hakkari Bloodkeeper (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 7.744, `BaseAttackTime` = 1225 WHERE `entry` = 8443; -- was 7.5, 2000
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 8477; -- Skeletal Servant (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 8497; -- Nightmare Suppressor (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 0.85 WHERE `entry` = 8554; -- Chief Sharptusk Thornmantle (was 1)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 8580; -- Atalalarion (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1, `BaseAttackTime` = 2000 WHERE `entry` = 8581; -- was 1, 1500
UPDATE `creature_template` SET `DamageModifier` = 0.75 WHERE `entry` = 8615; -- Mithril Dragonling (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.45 WHERE `entry` = 8656; -- Hukkus Voidwalker (was 1)
UPDATE `creature_template` SET `DamageModifier` = 9.7 WHERE `entry` = 8716; -- Dreadlord (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 10 WHERE `entry` = 8717; -- Felguard Elite (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 10 WHERE `entry` = 8718; -- Manahound (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 1.2 WHERE `entry` = 8876; -- Sandfury Acolyte (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3.1 WHERE `entry` = 8891; -- Anvilrage Guardsman (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.3 WHERE `entry` = 8893; -- Anvilrage Soldier (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.3 WHERE `entry` = 8894; -- Anvilrage Medic (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5.5 WHERE `entry` = 8908; -- Molten War Golem (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.2 WHERE `entry` = 8909; -- Fireguard (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.1 WHERE `entry` = 8912; -- Twilights Hammer Torturer (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.3 WHERE `entry` = 8913; -- Twilight Emissary (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 8916; -- Arena Spectator (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 1.8 WHERE `entry` = 8920; -- Weapon Technician (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 8925; -- Dredge Worm (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3.7 WHERE `entry` = 8926; -- Deep Stinger (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.6 WHERE `entry` = 8927; -- Dark Screecher (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 8928; -- Burrowing Thundersnout (was 1)
UPDATE `creature_template` SET `DamageModifier` = 5.746 WHERE `entry` = 8929; -- Princess Moira Bronzebeard (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 1.6 WHERE `entry` = 8932; -- Borer Beetle (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 8933; -- Cave Creeper (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.417, `BaseAttackTime` = 1200 WHERE `entry` = 8981; -- was 1, 2000
UPDATE `creature_template` SET `DamageModifier` = 6.25 WHERE `entry` = 8983; -- Golem Lord Argelmach (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 1.2 WHERE `entry` = 8996; -- Voidwalker Minion (was 1)
UPDATE `creature_template` SET `DamageModifier` = 6.083 WHERE `entry` = 9016; -- BaelGar (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 9017; -- Lord Incendius (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.3 WHERE `entry` = 9018; -- High Interrogator Gerstahn (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 9026; -- Overmaster Pyron (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 9027; -- Gorosh the Dervish (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 9028; -- Grizzle (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5.944 WHERE `entry` = 9031; -- Anubshiah (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5.55 WHERE `entry` = 9032; -- Hedrum the Creeper (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6.556 WHERE `entry` = 9033; -- General Angerforge (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.85 WHERE `entry` = 9035; -- Angerrel (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 9040; -- Doperel (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 7.2 WHERE `entry` = 9056; -- Fineous Darkvire (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 9096; -- Rage Talon Dragonspawn (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 9156; -- Ambassador Flamelash (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 0.03 WHERE `entry` = 9157; -- Bloodpetal Pest (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 9178; -- Burning Spirit (was 1)
UPDATE `creature_template` SET `DamageModifier` = 4.938 WHERE `entry` = 9196; -- Highlord Omokk (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 9197; -- Spirestone Battle Mage (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 9198; -- Spirestone Mystic (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 9199; -- Spirestone Enforcer (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 9200; -- Spirestone Reaver (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 9201; -- Spirestone Ogre Magus (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 9218; -- Spirestone Battle Lord (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 9219; -- Spirestone Butcher (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 7.5 WHERE `entry` = 9237; -- War Master Voone (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.704 WHERE `entry` = 9259; -- Firebrand Grunt (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 1.5 WHERE `entry` = 9261; -- Firebrand Darkweaver (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 1.5 WHERE `entry` = 9262; -- Firebrand Invoker (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 1.5 WHERE `entry` = 9263; -- Firebrand Dreadweaver (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.846 WHERE `entry` = 9264; -- Firebrand Pyromancer (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4.286 WHERE `entry` = 9265; -- Smolderthorn Shadow Hunter (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4.5 WHERE `entry` = 9376; -- Blazerunner (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.2 WHERE `entry` = 9396; -- Ground Pounder (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.5 WHERE `entry` = 9436; -- Spawn of BaelGar (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3.55 WHERE `entry` = 9443; -- Dark Keeper Pelver (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 9456; -- Warlord Kromzar (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 0.3 WHERE `entry` = 9457; -- Horde Defender (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.3 WHERE `entry` = 9458; -- Horde Axe Thrower (was 1)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 9476; -- Watchman Doomgrip (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 9502; -- Phalanx (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.3 WHERE `entry` = 9541; -- Blackbreath Crony (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.6 WHERE `entry` = 9547; -- Guzzling Patron (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.2 WHERE `entry` = 9554; -- Hammered Patron (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4.167 WHERE `entry` = 9583; -- Bloodaxe Veteran (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 1.5 WHERE `entry` = 9596; -- Bannok Grimaxe (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 0.645 WHERE `entry` = 9600; -- Parrot (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.385 WHERE `entry` = 9605; -- Blackrock Raider (was 1)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 9677; -- Ograbisi (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 9680; -- Crest Killer (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4.375 WHERE `entry` = 9681; -- Jaz (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.733 WHERE `entry` = 9696; -- Bloodaxe Worg (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.9 WHERE `entry` = 9718; -- Ghok Bashguud (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 9736; -- Quartermaster Zigris (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 9817; -- Blackhand Dreadweaver (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 9818; -- Blackhand Summoner (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 9819; -- Blackhand Veteran (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6.875 WHERE `entry` = 9938; -- Magmus (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 1.25 WHERE `entry` = 10041; -- Gorishi Hive Queen (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3.2 WHERE `entry` = 10043; -- Ribblys Crony (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 2.5 WHERE `entry` = 10080; -- Sandarr Dunereaver (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.5 WHERE `entry` = 10081; -- Dustwraith (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.5 WHERE `entry` = 10082; -- Zerillis (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3.9 WHERE `entry` = 10083; -- Rage Talon Flamescale (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5.1 WHERE `entry` = 10119; -- Volchan (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 2.5 WHERE `entry` = 10161; -- Rookery Whelp (was 1)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 10258; -- Rookery Guardian (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6.15 WHERE `entry` = 10264; -- Solakar Flamewreath (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6.5 WHERE `entry` = 10268; -- Gizrul the Slavener (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 9.6 WHERE `entry` = 10301; -- Jaron Stoneshaper (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 10316; -- Blackhand Incarcerator (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 10317; -- Blackhand Elite (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 7.5 WHERE `entry` = 10318; -- Blackhand Assassin (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6.6 WHERE `entry` = 10321; -- Emberstrife (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 1.1 WHERE `entry` = 10323; -- Murkdeep (was 1)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 10339; -- Gyth (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 10366; -- Rage Talon Dragon Guard (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.733 WHERE `entry` = 10374; -- Spire Spider (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 1.467 WHERE `entry` = 10375; -- Spire Spiderling (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.867 WHERE `entry` = 10376; -- Crystal Fang (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 0.7 WHERE `entry` = 10387; -- Vengeful Phantom (was 1)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 10394; -- Black Guard Sentry (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3.9 WHERE `entry` = 10398; -- Thuzadin Shadowcaster (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 10399; -- Thuzadin Acolyte (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4.1 WHERE `entry` = 10400; -- Thuzadin Necromancer (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4.778 WHERE `entry` = 10405; -- Plague Ghoul (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.75 WHERE `entry` = 10408; -- Rockwing Gargoyle (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.9 WHERE `entry` = 10412; -- Crypt Crawler (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 10413; -- Crypt Beast (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 10414; -- Patchwork Horror (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 10416; -- Bile Spewer (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6.1 WHERE `entry` = 10417; -- Venom Belcher (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.8 WHERE `entry` = 10419; -- Crimson Conjuror (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.9 WHERE `entry` = 10422; -- Crimson Sorcerer (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 10423; -- Crimson Priest (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 10424; -- Crimson Gallant (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 10425; -- Crimson Battle Mage (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 10426; -- Crimson Inquisitor (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4.7 WHERE `entry` = 10432; -- Vectus (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 10433; -- Marduk Blackpool (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 7.5 WHERE `entry` = 10435; -- Magistrate Barthilas (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 7.65 WHERE `entry` = 10436; -- Baroness Anastari (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 7.55 WHERE `entry` = 10437; -- Nerubenkan (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6.05 WHERE `entry` = 10438; -- Maleki the Pallid (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 8 WHERE `entry` = 10440; -- Baron Rivendare (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 0.4 WHERE `entry` = 10441; -- Plagued Rat (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3.867 WHERE `entry` = 10442; -- Chromatic Whelp (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 10447; -- Chromatic Dragonspawn (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 0.4 WHERE `entry` = 10461; -- Plagued Insect (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3.9 WHERE `entry` = 10464; -- Wailing Banshee (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.8 WHERE `entry` = 10470; -- Scholomance Neophyte (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 8 WHERE `entry` = 10478; -- Splintered Skeleton (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 10480; -- Unstable Corpse (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6.042 WHERE `entry` = 10486; -- Risen Warrior (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.9 WHERE `entry` = 10487; -- Risen Protector (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 7.5 WHERE `entry` = 10488; -- Risen Construct (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.929 WHERE `entry` = 10495; -- Diseased Ghoul (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 10498; -- Spectral Tutor (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.9 WHERE `entry` = 10499; -- Spectral Researcher (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6.5 WHERE `entry` = 10502; -- Lady Illucia Barov (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 10503; -- Jandice Barov (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 10504; -- Lord Alexei Barov (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 10505; -- Instructor Malicia (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 8 WHERE `entry` = 10506; -- Kirtonos the Herald (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 10507; -- The Ravenian (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 10508; -- Ras Frostwhisper (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.8 WHERE `entry` = 10509; -- Jed Runewatcher (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 0.4 WHERE `entry` = 10536; -- Plagued Maggot (was 1)
UPDATE `creature_template` SET `DamageModifier` = 13.447, `BaseAttackTime` = 1175 WHERE `entry` = 10538; -- Vaelastrasz
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 10556; -- Lazy Peon (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3.9 WHERE `entry` = 10558; -- Hearthsinger Forresten (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 10577; -- Crypt Scarab (was 1)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 10584; -- Urok Doomhowl (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5.733 WHERE `entry` = 10596; -- Mother Smolderweb (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 10599; -- Hulfnar Stonetotem (was 1)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 10601; -- Urok Enforcer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 10602; -- Urok Ogre Magus (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 1.5 WHERE `entry` = 10641; -- Branch Snapper (was 1)
UPDATE `creature_template` SET `DamageModifier` = 5.65 WHERE `entry` = 10662; -- Spellmaw (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 5.75 WHERE `entry` = 10663; -- Manaclaw (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.9 WHERE `entry` = 10678; -- Plagued Hatchling (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4.25 WHERE `entry` = 10680; -- was 3.5
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 10681; -- Summoned Blackhand Veteran (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.5 WHERE `entry` = 10683; -- Rookery Hatcher (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 10699; -- Carrion Scarab (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.85 WHERE `entry` = 10721; -- Novice Warrior (was 1)
UPDATE `creature_template` SET `DamageModifier` = 4.25 WHERE `entry` = 10741; -- Sian-Rotam (was 1)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 10742; -- Blackhand Dragon Handler (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6.5 WHERE `entry` = 10762; -- Blackhand Thug (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 6.55 WHERE `entry` = 10811; -- Archivist Galford (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 8.6 WHERE `entry` = 10812; -- Grand Crusader Dathrohan (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 15.478, `BaseAttackTime` = 1150 WHERE `entry` = 10813; -- was 9, 2000
UPDATE `creature_template` SET `DamageModifier` = 1.3 WHERE `entry` = 10817; -- Duggan Wildhammer (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.25 WHERE `entry` = 10821; -- Hedmush the Rotting (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.2 WHERE `entry` = 10824; -- Ranger Lord Hawkspear (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.941 WHERE `entry` = 10836; -- Farmer Dalson (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 10839; -- Argent Officer Garush (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.8 WHERE `entry` = 10876; -- Undead Scarab (was 1)
UPDATE `creature_template` SET `DamageModifier` = 6.1 WHERE `entry` = 10899; -- Goraluk Anvilcrack (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 10901; -- Lorekeeper Polkelt (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 10944; -- Davil Lightfire (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3.8, `BaseAttackTime` = 2000 WHERE `entry` = 10953; -- was 1, 1200
UPDATE `creature_template` SET `DamageModifier` = 4, `BaseAttackTime` = 2000 WHERE `entry` = 10954; -- was 7.5, 1200
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 10982; -- Whitewhisker Vermin (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 10987; -- Irondeep Trogg (was 1)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 10996; -- Fallen Hero (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 10997; -- Cannon Master Willey (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 11016; -- Captured Arkonarin (was 1)
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 11022; -- Alexi Barov (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 12 WHERE `entry` = 11023; -- Weldon Barov (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 0.4 WHERE `entry` = 11027; -- Illusory Wraith (was 1)
UPDATE `creature_template` SET `DamageModifier` = 6.75 WHERE `entry` = 11032; -- Malor the Zealous (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 8.5 WHERE `entry` = 11058; -- Fras Siabi (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6.65 WHERE `entry` = 11082; -- Stratholme Courier (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5.9 WHERE `entry` = 11102; -- Argent Rider (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 11141; -- Spirit of Trey Lightforge (was 1)
UPDATE `creature_template` SET `DamageModifier` = 4.55 WHERE `entry` = 11142; -- Undead Postman (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 8, `BaseAttackTime` = 2200 WHERE `entry` = 11143; -- was 7.5, 2000
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 11257; -- Scholomance Handler (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 10.8 WHERE `entry` = 11261; -- Doctor Theolen Krastinov (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 3.109, `BaseAttackTime` = 1158 WHERE `entry` = 11284; -- was 7.5, 2000
UPDATE `creature_template` SET `DamageModifier` = 12, `BaseAttackTime` = 2000 WHERE `entry` = 11347; -- was 14.2, 2200
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 11357; -- Son of Hakkar (was 7.15)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 11360; -- Zulian Cub (was 3.1)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 11361; -- Zulian Tiger (was 8.85)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 11365; -- Zulian Panther (was 15.7)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 11373; -- Razzashi Cobra (was 9.4)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 11387; -- Sandfury Speaker (was 9.05)
UPDATE `creature_template` SET `DamageModifier` = 5.2 WHERE `entry` = 11388; -- Witherbark Speaker (was 7.4)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 11391; -- Vilebranch Speaker (was 9.05)
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 11439; -- Illusion of Jandice Barov (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3.733 WHERE `entry` = 11452; -- Wildspawn Rogue (was 5)
UPDATE `creature_template` SET `DamageModifier` = 3.8 WHERE `entry` = 11455; -- Wildspawn Felsworn (was 5)
UPDATE `creature_template` SET `DamageModifier` = 3.6 WHERE `entry` = 11456; -- Wildspawn Shadowstalker (was 5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 11459; -- Ironbark Protector (was 5)
UPDATE `creature_template` SET `DamageModifier` = 3.84 WHERE `entry` = 11465; -- Warpwood Stomper (was 5)
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 11466; -- Highborne Summoner (was 5)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 11472; -- Eldreth Spirit (was 5)
UPDATE `creature_template` SET `DamageModifier` = 4.5 WHERE `entry` = 11475; -- Eldreth Phantasm (was 5)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 11477; -- Rotting Highborne (was 5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 11480; -- Arcane Aberration (was 5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 11483; -- Mana Remnant (was 5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 11484; -- Residual Monstrosity (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 10 WHERE `entry` = 11486; -- Prince Tortheldrin (was 5)
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 11487; -- Magister Kalendris (was 5)
UPDATE `creature_template` SET `DamageModifier` = 8 WHERE `entry` = 11489; -- Tendris Warpwood (was 5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 11490; -- Zevrim Thornhoof (was 5)
UPDATE `creature_template` SET `DamageModifier` = 7.75 WHERE `entry` = 11496; -- Immolthar (was 5)
UPDATE `creature_template` SET `DamageModifier` = 12.1 WHERE `entry` = 11497; -- The Razza (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 10.5 WHERE `entry` = 11498; -- Skarr the Unbreakable (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 11551; -- Necrofiend (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 1.333 WHERE `entry` = 11561; -- Undead Ravager (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.292 WHERE `entry` = 11598; -- Risen Guardian (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 11600; -- Irondeep Shaman (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 11602; -- Irondeep Skullthumper (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 11603; -- Whitewhisker Digger (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 11604; -- Whitewhisker Geomancer (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.583, `BaseAttackTime` = 2400 WHERE `entry` = 11605; -- was 1, 2000
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 11622; -- Rattlegore (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 0.4 WHERE `entry` = 11636; -- Servant of Weldon Barov (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.4 WHERE `entry` = 11637; -- Servant of Alexi Barov (was 1)
UPDATE `creature_template` SET `DamageModifier` = 11 WHERE `entry` = 11662; -- Flamewaker Priest (was 13)
UPDATE `creature_template` SET `DamageModifier` = 1.176 WHERE `entry` = 11678; -- Snowblind Ambusher (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 11690; -- Gnarlpine Instigator (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.95 WHERE `entry` = 11713; -- Blackwood Tracker (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 11714; -- Marosh the Devious (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.533 WHERE `entry` = 11790; -- Putridus Satyr (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.667 WHERE `entry` = 11791; -- Putridus Trickster (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.6 WHERE `entry` = 11792; -- Putridus Shadowstalker (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.25 WHERE `entry` = 11839; -- Wildpaw Brute (was 1)
UPDATE `creature_template` SET `DamageModifier` = 10.833 WHERE `entry` = 11878; -- Nathanos Blightcaller (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 11886; -- Mercutio Filthgorger (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.28 WHERE `entry` = 11918; -- Gogger Stonepounder (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.5 WHERE `entry` = 12047; -- Stormpike Mountaineer (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.5, `BaseAttackTime` = 2000 WHERE `entry` = 12048; -- was 1, 1410
UPDATE `creature_template` SET `DamageModifier` = 2.8 WHERE `entry` = 12050; -- Stormpike Defender (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 12051; -- Frostwolf Legionnaire (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.5, `BaseAttackTime` = 2000 WHERE `entry` = 12052; -- was 1, 1410
UPDATE `creature_template` SET `DamageModifier` = 2.8 WHERE `entry` = 12053; -- Frostwolf Guardian (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 12122; -- Duros (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 12201; -- Princess Theradras (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 12203; -- Landslide (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 4.2 WHERE `entry` = 12206; -- Primordial Behemoth (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.8 WHERE `entry` = 12207; -- Thessala Hydra (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 12208; -- Conquered Soul of the Blightcaller (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.6 WHERE `entry` = 12220; -- Constrictor Vine (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.9 WHERE `entry` = 12222; -- Creeping Sludge (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 4.6 WHERE `entry` = 12225; -- Celebras the Cursed (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.9 WHERE `entry` = 12236; -- Lord Vyletongue (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.15 WHERE `entry` = 12241; -- Spirit of Magra (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 12258; -- Razorlash (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.5 WHERE `entry` = 12322; -- QuelLithien Protector (was 1)
UPDATE `creature_template` SET `DamageModifier` = 6.4 WHERE `entry` = 12339; -- Demetria (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 12474; -- Emeraldon Boughguard (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 12475; -- Emeraldon Tree Warder (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 12476; -- Emeraldon Oracle (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 12477; -- Verdantine Boughguard (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 14.6 WHERE `entry` = 12478; -- Verdantine Oracle (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 12479; -- Verdantine Tree Warder (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 12480; -- Melris Malagan (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 12481; -- Justine Demalier (was 1)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 12496; -- Dreamtracker (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 12498; -- Dreamstalker (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 12739; -- Onyxias Elite Guard (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.15 WHERE `entry` = 12759; -- Tideress (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.7 WHERE `entry` = 12836; -- Wandering Protector (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1, `BaseAttackTime` = 2000 WHERE `entry` = 12860; -- was 1, 2660
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 12876; -- Baron Aquanis (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 9 WHERE `entry` = 12899; -- Axtroz (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 12918; -- Chief Murgut (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 12940; -- Vorsha the Lasher (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.635 WHERE `entry` = 13016; -- Deeprun Rat (was 1)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 13021; -- Warpwood Crusher (was 5)
UPDATE `creature_template` SET `DamageModifier` = 0.4 WHERE `entry` = 13080; -- Irondeep Guard (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.4 WHERE `entry` = 13081; -- Irondeep Raider (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1, `BaseAttackTime` = 2000 WHERE `entry` = 13086; -- was 1, 1191
UPDATE `creature_template` SET `DamageModifier` = 0.4, `BaseAttackTime` = 2000 WHERE `entry` = 13087; -- was 1, 1183
UPDATE `creature_template` SET `DamageModifier` = 0.393 WHERE `entry` = 13089; -- Coldmine Guard (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.4 WHERE `entry` = 13096; -- Coldmine Explorer (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.4 WHERE `entry` = 13097; -- Coldmine Surveyor (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.4 WHERE `entry` = 13098; -- Irondeep Surveyor (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.4 WHERE `entry` = 13099; -- Irondeep Explorer (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.2 WHERE `entry` = 13136; -- HiveAshi Drone (was 1)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 13137; -- Lieutenant Rugba (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 13138; -- Lieutenant Spencer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 13139; -- Commander Randolph (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.6 WHERE `entry` = 13142; -- Deeprot Tangler (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 13143; -- Lieutenant Stronghoof (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 13144; -- Lieutenant Voltalar (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 13145; -- Lieutenant Grummus (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4, `BaseAttackTime` = 2000 WHERE `entry` = 13147; -- was 7.5, 2500
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 13152; -- Commander Malgor (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 13153; -- Commander Mulfort (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 13154; -- Commander Louis Philips (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.333 WHERE `entry` = 13160; -- Carrion Swarmer (was 5)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 13176; -- Smith Regzar (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 13179; -- Wing Commander Guse (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 13180; -- Wing Commander Jeztor (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 13181; -- Wing Commander Mulverick (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 13196; -- Phase Lasher (was 5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 13197; -- Fel Lash (was 5)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 13216; -- Gaelden Hammersmith (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 13218; -- Grunnda Wolfheart (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 13236; -- Primalist Thurloga (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 13257; -- Murgot Deepforge (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6.6 WHERE `entry` = 13280; -- Hydrospawn (was 5)
UPDATE `creature_template` SET `DamageModifier` = 3.5 WHERE `entry` = 13282; -- Noxxion (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3.5 WHERE `entry` = 13284; -- Frostwolf Shaman (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 13285; -- Death Lash (was 5)
UPDATE `creature_template` SET `DamageModifier` = 3.298 WHERE `entry` = 13296; -- Lieutenant Largent (was 1.4)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 13297; -- Lieutenant Stouthandle (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 13298; -- Lieutenant Greywand (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 13299; -- Lieutenant Lonadin (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 13300; -- Lieutenant Mancuso (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 0.3 WHERE `entry` = 13316; -- Coldmine Peon (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.3, `BaseAttackTime` = 2000 WHERE `entry` = 13317; -- was 1, 1175
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 13318; -- Commander Mortimer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 13319; -- Commander Duffy (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3.242 WHERE `entry` = 13320; -- Commander Karl Philips (was 2)
UPDATE `creature_template` SET `DamageModifier` = 0.635 WHERE `entry` = 13321; -- Frog (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2.8, `BaseAttackTime` = 2000 WHERE `entry` = 13324; -- was 1, 1410
UPDATE `creature_template` SET `DamageModifier` = 2.6, `BaseAttackTime` = 2000 WHERE `entry` = 13325; -- was 1, 1410
UPDATE `creature_template` SET `DamageModifier` = 2.9 WHERE `entry` = 13326; -- Seasoned Defender (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.6, `BaseAttackTime` = 2000 WHERE `entry` = 13327; -- was 1, 1410
UPDATE `creature_template` SET `DamageModifier` = 2.9 WHERE `entry` = 13328; -- Seasoned Guardian (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2.8, `BaseAttackTime` = 2000 WHERE `entry` = 13329; -- was 1, 1400
UPDATE `creature_template` SET `DamageModifier` = 2.65, `BaseAttackTime` = 2000 WHERE `entry` = 13330; -- was 1, 1410
UPDATE `creature_template` SET `DamageModifier` = 0.3 WHERE `entry` = 13396; -- Irondeep Miner (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.3 WHERE `entry` = 13397; -- Irondeep Peon (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 13421; -- Champion Guardian (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3.1, `BaseAttackTime` = 2000 WHERE `entry` = 13422; -- was 1, 1400
UPDATE `creature_template` SET `DamageModifier` = 3, `BaseAttackTime` = 2000 WHERE `entry` = 13424; -- was 1, 1410
UPDATE `creature_template` SET `DamageModifier` = 3, `BaseAttackTime` = 2000 WHERE `entry` = 13425; -- was 1, 1410
UPDATE `creature_template` SET `DamageModifier` = 2.8, `BaseAttackTime` = 2000 WHERE `entry` = 13426; -- was 1, 1410
UPDATE `creature_template` SET `DamageModifier` = 2.85, `BaseAttackTime` = 2000 WHERE `entry` = 13427; -- was 1, 1410
UPDATE `creature_template` SET `DamageModifier` = 2.8, `BaseAttackTime` = 2000 WHERE `entry` = 13428; -- was 1, 1410
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 13438; -- Wing Commander Slidore (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 13439; -- Wing Commander Vipore (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 13442; -- Arch Druid Renferal (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3.5 WHERE `entry` = 13443; -- Druid of the Grove (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 13447; -- Corporal Noreg Stormpike (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 0.5, `BaseAttackTime` = 2800 WHERE `entry` = 13534; -- was 1, 1183
UPDATE `creature_template` SET `DamageModifier` = 0.571 WHERE `entry` = 13535; -- Veteran Coldmine Guard (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.5, `BaseAttackTime` = 2000 WHERE `entry` = 13537; -- was 1, 1216
UPDATE `creature_template` SET `DamageModifier` = 0.6 WHERE `entry` = 13538; -- Veteran Coldmine Surveyor (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 13540; -- Seasoned Irondeep Explorer (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.558 WHERE `entry` = 13541; -- Veteran Irondeep Explorer (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.651 WHERE `entry` = 13542; -- Champion Irondeep Explorer (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 13543; -- Seasoned Irondeep Raider (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.6 WHERE `entry` = 13544; -- Veteran Irondeep Raider (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.7 WHERE `entry` = 13545; -- Champion Irondeep Raider (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 13546; -- Seasoned Coldmine Explorer (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.6, `BaseAttackTime` = 2000 WHERE `entry` = 13547; -- was 1, 1208
UPDATE `creature_template` SET `DamageModifier` = 0.5, `BaseAttackTime` = 2000 WHERE `entry` = 13549; -- was 1, 1183
UPDATE `creature_template` SET `DamageModifier` = 0.6, `BaseAttackTime` = 2000 WHERE `entry` = 13550; -- was 1, 1200
UPDATE `creature_template` SET `DamageModifier` = 0.7, `BaseAttackTime` = 2000 WHERE `entry` = 13551; -- was 1, 1175
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 13552; -- Seasoned Irondeep Guard (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.6 WHERE `entry` = 13553; -- Veteran Irondeep Guard (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.7, `BaseAttackTime` = 2000 WHERE `entry` = 13554; -- was 1, 1191
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 13555; -- Seasoned Irondeep Surveyor (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.6 WHERE `entry` = 13556; -- Veteran Irondeep Surveyor (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.651, `BaseAttackTime` = 2000 WHERE `entry` = 13557; -- was 1, 1225
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 13577; -- Stormpike Ram Rider Commander (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6.8 WHERE `entry` = 13596; -- Rotgrip (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 4.5 WHERE `entry` = 13601; -- Tinkerer Gizlock (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 13617; -- Stormpike Stable Master (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 13718; -- The Nameless Prophet (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 4.293, `BaseAttackTime` = 1258 WHERE `entry` = 13738; -- was 7.5, 2000
UPDATE `creature_template` SET `DamageModifier` = 4.265, `BaseAttackTime` = 1266 WHERE `entry` = 13739; -- was 7.5, 2000
UPDATE `creature_template` SET `DamageModifier` = 3.657, `BaseAttackTime` = 1258 WHERE `entry` = 13740; -- was 7.5, 2000
UPDATE `creature_template` SET `DamageModifier` = 2.3 WHERE `entry` = 13741; -- Gelk (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.3 WHERE `entry` = 13742; -- Kolk (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 13743; -- Corrupt Force of Nature (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 4.1 WHERE `entry` = 13797; -- Mountaineer Boombellow (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4.1 WHERE `entry` = 13798; -- Jotek (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5.9 WHERE `entry` = 13959; -- Alterac Yeti (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 14.913 WHERE `entry` = 14101; -- Enraged Felguard (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.2 WHERE `entry` = 14236; -- Lord Angler (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.85 WHERE `entry` = 14272; -- Snarlflare (was 1)
UPDATE `creature_template` SET `DamageModifier` = 6.1 WHERE `entry` = 14285; -- Frostwolf Battleguard (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 5.635 WHERE `entry` = 14303; -- Petrified Guardian (was 5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 14308; -- Ferra (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 7.1 WHERE `entry` = 14323; -- Guard Slipkik (was 5)
UPDATE `creature_template` SET `DamageModifier` = 2.5 WHERE `entry` = 14324; -- ChoRush the Observer (was 5)
UPDATE `creature_template` SET `DamageModifier` = 8.1 WHERE `entry` = 14325; -- Captain Kromcrush (was 5)
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 14326; -- Guard Moldar (was 5)
UPDATE `creature_template` SET `DamageModifier` = 0.2 WHERE `entry` = 14350; -- Hydroling (was 5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 14354; -- Pusillin (was 5)
UPDATE `creature_template` SET `DamageModifier` = 1.5 WHERE `entry` = 14370; -- Cadaverous Worm (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.214 WHERE `entry` = 14372; -- Winterfall Ambusher (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.86 WHERE `entry` = 14385; -- Doomguard Minion (was 5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 14389; -- Netherwalker (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.5 WHERE `entry` = 14390; -- Expeditionary Mountaineer (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.75 WHERE `entry` = 14393; -- Expeditionary Priest (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 0.1 WHERE `entry` = 14396; -- Eye of Immolthar (was 5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 14399; -- Arcane Torrent (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.55 WHERE `entry` = 14445; -- Lord Captain Wyrmak (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 1.667 WHERE `entry` = 14448; -- Molt Thorn (was 1)
UPDATE `creature_template` SET `DamageModifier` = 5.496 WHERE `entry` = 14454; -- The Windreaver (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.075 WHERE `entry` = 14455; -- Whirling Invader (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.375 WHERE `entry` = 14458; -- Watery Invader (was 1)
UPDATE `creature_template` SET `DamageModifier` = 6.65 WHERE `entry` = 14471; -- Setis (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 3.5 WHERE `entry` = 14483; -- Dread Guard (was 5)
UPDATE `creature_template` SET `DamageModifier` = 0.7 WHERE `entry` = 14486; -- Scourge Footsoldier (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1, `BaseAttackTime` = 2000 WHERE `entry` = 14492; -- was 1, 1300
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 14502; -- Xorothian Dreadsteed (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 8.083, `BaseAttackTime` = 2400 WHERE `entry` = 14506; -- was 5, 2000
UPDATE `creature_template` SET `DamageModifier` = 4.1 WHERE `entry` = 14511; -- Shadowed Spirit (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4.301 WHERE `entry` = 14512; -- Corrupted Spirit (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 14513; -- Malicious Spirit (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.075 WHERE `entry` = 14514; -- Banal Spirit (was 1)
UPDATE `creature_template` SET `DamageModifier` = 6.773 WHERE `entry` = 14519; -- Aspect of Corruption (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 14520; -- Aspect of Malice (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 14532; -- Razzashi Venombrood (was 10)
UPDATE `creature_template` SET `DamageModifier` = 1.259 WHERE `entry` = 14603; -- Zapped Shore Strider (was 1)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 14605; -- Bone Construct (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.174 WHERE `entry` = 14639; -- Zapped Deep Strider (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.259 WHERE `entry` = 14640; -- Zapped Cliff Giant (was 1)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 14668; -- Corrupted Infernal (was 2.35)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 14682; -- Sever (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.1 WHERE `entry` = 14715; -- Silverwing Elite (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 14762; -- Dun Baldar North Marshal (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 14765; -- Stonehearth Marshal (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 14766; -- Iceblood Marshal (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 14769; -- West Frostwolf Marshal (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 14771; -- Dun Baldar South Warmaster (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 14772; -- East Frostwolf Warmaster (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 14773; -- Iceblood Warmaster (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 14777; -- West Frostwolf Warmaster (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 14825; -- Withered Mistress (was 11.7)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 14826; -- Sacrificed Troll (was 1.5)
UPDATE `creature_template` SET `DamageModifier` = 4.65 WHERE `entry` = 14861; -- Blood Steward of Kirtonos (was 3.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 14880; -- Razzashi Skitterer (was 4.15)
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 14882; -- Atalai Mistress (was 9.6)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 14883; -- Voodoo Slave (was 10.3)
UPDATE `creature_template` SET `DamageModifier` = 0.635 WHERE `entry` = 14884; -- Parasitic Serpent (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.9 WHERE `entry` = 14901; -- Peon (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 14965; -- Frenzied Bloodseeker Bat (was 1)
UPDATE `creature_template` SET `DamageModifier` = 15 WHERE `entry` = 15009; -- Voodoo Spirit (was 0.1)
UPDATE `creature_template` SET `DamageModifier` = 0.635 WHERE `entry` = 15010; -- Jungle Toad (was 1)
UPDATE `creature_template` SET `DamageModifier` = 5.15 WHERE `entry` = 15067; -- Zulian Stalker (was 6.2)
UPDATE `creature_template` SET `DamageModifier` = 7.062 WHERE `entry` = 15068; -- Zulian Guardian (was 3)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 15101; -- Zulian Prowler (was 2.25)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 15111; -- Mad Servant (was 7.45)
UPDATE `creature_template` SET `DamageModifier` = 10.6 WHERE `entry` = 15126; -- Rutherford Twing (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 15128; -- Defiler Elite (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 15130; -- League of Arathor Elite (was 2.4)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 15146; -- Mad Voidwalker (was 5)
UPDATE `creature_template` SET `DamageModifier` = 9.333 WHERE `entry` = 15195; -- Wickerman Guardian (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 9.2 WHERE `entry` = 15208; -- The Duke of Shards (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 9 WHERE `entry` = 15220; -- The Duke of Zephyrs (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 20.25 WHERE `entry` = 15262; -- Obsidian Eradicator (was 22.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 15318; -- HiveZara Drone (was 7.9)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 15319; -- HiveZara Collector (was 12.3)
UPDATE `creature_template` SET `DamageModifier` = 8 WHERE `entry` = 15320; -- HiveZara Soldier (was 20.3)
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 15323; -- HiveZara Sandstalker (was 6.5)
UPDATE `creature_template` SET `DamageModifier` = 10 WHERE `entry` = 15325; -- HiveZara Wasp (was 12.6)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 15327; -- HiveZara Stinger (was 12.6)
UPDATE `creature_template` SET `DamageModifier` = 1.5 WHERE `entry` = 15333; -- Silicate Feeder (was 5.05)
UPDATE `creature_template` SET `DamageModifier` = 10 WHERE `entry` = 15335; -- Flesh Hunter (was 15.95)
UPDATE `creature_template` SET `DamageModifier` = 8 WHERE `entry` = 15336; -- HiveZara Tail Lasher (was 12.1)
UPDATE `creature_template` SET `DamageModifier` = 14 WHERE `entry` = 15338; -- Obsidian Destroyer (was 4.95)
UPDATE `creature_template` SET `DamageModifier` = 20 WHERE `entry` = 15343; -- Qiraji Swarmguard (was 17.65)
UPDATE `creature_template` SET `DamageModifier` = 9.231 WHERE `entry` = 15344; -- Swarmguard Needler (was 12.1)
UPDATE `creature_template` SET `DamageModifier` = 18.1 WHERE `entry` = 15385; -- Colonel Zerran (was 11.65)
UPDATE `creature_template` SET `DamageModifier` = 18.1 WHERE `entry` = 15386; -- Major Yeggeth (was 11.65)
UPDATE `creature_template` SET `DamageModifier` = 18 WHERE `entry` = 15388; -- Major Pakkon (was 11.65)
UPDATE `creature_template` SET `DamageModifier` = 17.5 WHERE `entry` = 15389; -- Captain Drenn (was 11.65)
UPDATE `creature_template` SET `DamageModifier` = 18.1 WHERE `entry` = 15390; -- Captain Xurrem (was 11.65)
UPDATE `creature_template` SET `DamageModifier` = 18 WHERE `entry` = 15391; -- Captain Qeez (was 11.65)
UPDATE `creature_template` SET `DamageModifier` = 18.35 WHERE `entry` = 15392; -- Captain Tuubid (was 14.9)
UPDATE `creature_template` SET `DamageModifier` = 2.4 WHERE `entry` = 15414; -- Qiraji Wasp (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4.4 WHERE `entry` = 15421; -- Qiraji Drone (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.4 WHERE `entry` = 15422; -- Qiraji Tank (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 15424; -- Anubisath Conqueror (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 10, `BaseAttackTime` = 2000 WHERE `entry` = 15440; -- was 7.5, 1250
UPDATE `creature_template` SET `DamageModifier` = 1.5 WHERE `entry` = 15441; -- Ironforge Brigade Rifleman (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 15442; -- Ironforge Brigade Footman (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 15443; -- Janela Stouthammer (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 8.5 WHERE `entry` = 15449; -- HiveZora Abomination (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3.4 WHERE `entry` = 15461; -- Shrieker Scarab (was 2.9)
UPDATE `creature_template` SET `DamageModifier` = 3.4 WHERE `entry` = 15462; -- Spitting Scarab (was 4.15)
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 15471; -- Lieutenant General Andorov (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 15473; -- Kaldorei Elite (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 15495; -- Nighthaven Defender (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 15505; -- Canal Frenzy (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 15521; -- HiveZara Hatchling (was 12.3)
UPDATE `creature_template` SET `DamageModifier` = 1.9 WHERE `entry` = 15541; -- Twilight Marauder Morna (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 1.5 WHERE `entry` = 15546; -- HiveZara Swarmer (was 1.1)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 15591; -- Minion of Weavil (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 9.5 WHERE `entry` = 15612; -- Krug Skullsplit (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 15613; -- Merok Longstride (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 15616; -- Orgrimmar Legion Grunt (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 15617; -- Orgrimmar Legion Axe Thrower (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 8.5, `BaseAttackTime` = 2000 WHERE `entry` = 15620; -- was 7.5, 1500
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 15621; -- Yauj Brood (was 3.3)
UPDATE `creature_template` SET `DamageModifier` = 8 WHERE `entry` = 15622; -- Vekniss Borer (was 7.05)
UPDATE `creature_template` SET `DamageModifier` = 9.1 WHERE `entry` = 15629; -- Nightmare Phantasm (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 15634; -- Priestess of the Moon (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5, `BaseAttackTime` = 1000 WHERE `entry` = 15718; -- was 2.25, 2000
UPDATE `creature_template` SET `DamageModifier` = 22 WHERE `entry` = 15743; -- Colossal Anubisath Warbringer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 22.317 WHERE `entry` = 15744; -- Imperial Qiraji Destroyer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 15747; -- Qiraji Captain (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.2 WHERE `entry` = 15748; -- Lesser Anubisath Warbringer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.2 WHERE `entry` = 15749; -- Lesser Silithid Flayer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3.9 WHERE `entry` = 15750; -- Qiraji Major (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3.4 WHERE `entry` = 15751; -- Anubisath Warbringer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.2 WHERE `entry` = 15752; -- Silithid Flayer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 15753; -- Qiraji Brigadier General (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5 WHERE `entry` = 15754; -- Greater Anubisath Warbringer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.2 WHERE `entry` = 15756; -- Greater Silithid Flayer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 14.25 WHERE `entry` = 15757; -- Qiraji Lieutenant General (was 35)
UPDATE `creature_template` SET `DamageModifier` = 3.2 WHERE `entry` = 15759; -- Supreme Silithid Flayer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.8 WHERE `entry` = 15806; -- Qiraji Lieutenant (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.2 WHERE `entry` = 15807; -- Minor Anubisath Warbringer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.2 WHERE `entry` = 15808; -- Minor Silithid Flayer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2 WHERE `entry` = 15810; -- Eroded Anubisath Warbringer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.2 WHERE `entry` = 15811; -- Faltering Silithid Flayer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.8 WHERE `entry` = 15812; -- Qiraji Officer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 2.8 WHERE `entry` = 15813; -- Qiraji Officer Zod (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 15815; -- Qiraji Captain Kaark (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 21.25 WHERE `entry` = 15818; -- Lieutenant General Nokhor (was 35)
UPDATE `creature_template` SET `DamageModifier` = 0.729 WHERE `entry` = 15842; -- Might of Kalimdor Mage (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.727 WHERE `entry` = 15843; -- Might of Kalimdor Priest (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.93 WHERE `entry` = 15847; -- Might of Kalimdor Shaman (was 1)
UPDATE `creature_template` SET `DamageModifier` = 0.93 WHERE `entry` = 15849; -- Might of Kalimdor Druid (was 1)
UPDATE `creature_template` SET `DamageModifier` = 4 WHERE `entry` = 15852; -- Orgrimmar Elite Shieldguard (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 15853; -- Orgrimmar Elite Infantryman (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 8.2 WHERE `entry` = 15854; -- Orgrimmar Elite Cavalryman (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.325 WHERE `entry` = 15856; -- Tauren Primalist (was 1)
UPDATE `creature_template` SET `DamageModifier` = 8.3 WHERE `entry` = 15857; -- Stormwind Cavalryman (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 15858; -- Stormwind Infantryman (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 5.579 WHERE `entry` = 15859; -- Stormwind Archmage (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 9.37 WHERE `entry` = 15860; -- Kaldorei Marksman (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 15861; -- Ironforge Infantryman (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 8.2 WHERE `entry` = 15862; -- Ironforge Cavalryman (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1.86 WHERE `entry` = 15863; -- Darkspear Shaman (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 30 WHERE `entry` = 15866; -- was 7.5
UPDATE `creature_template` SET `DamageModifier` = 0.728 WHERE `entry` = 15867; -- Might of Kalimdor Archmage (was 1)
UPDATE `creature_template` SET `DamageModifier` = 18.6 WHERE `entry` = 15868; -- Highlord Leoric Von Zeldig (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 26.044 WHERE `entry` = 15869; -- Malagav the Tactician (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 20 WHERE `entry` = 15870; -- Duke August Foehammer (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 15903; -- Sergeant Carnes (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 7 WHERE `entry` = 15934; -- HiveZara Hornet (was 10)
UPDATE `creature_template` SET `DamageModifier` = 6.1 WHERE `entry` = 15961; -- Lunar Festival Sentinel (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 9 WHERE `entry` = 15962; -- Vekniss Hatchling (was 7.95)
UPDATE `creature_template` SET `DamageModifier` = 1.15 WHERE `entry` = 16013; -- Deliana (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.8 WHERE `entry` = 16053; -- Korv (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 16139; -- Cenarion Hold Reservist (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 1 WHERE `entry` = 16226; -- Guard Didier (was 7.5)
UPDATE `creature_template` SET `DamageModifier` = 0.1 WHERE `entry` = 16232; -- Caravan Mule (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 16241; -- Argent Recruiter (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 16255; -- Argent Scout (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 16285; -- Argent Emissary (was 1)
UPDATE `creature_template` SET `DamageModifier` = 4.12 WHERE `entry` = 16436; -- Argent Dawn Priest (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3.1 WHERE `entry` = 16786; -- Argent Quartermaster (was 1)
UPDATE `creature_template` SET `DamageModifier` = 3 WHERE `entry` = 16787; -- Argent Outfitter (was 1)
UPDATE `creature_template` SET `DamageModifier` = 1.043, `BaseAttackTime` = 1500 WHERE `entry` = 17003; -- was 1, 2000
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 17765; -- Alliance Silithyst Sentinel (was 4.6)
UPDATE `creature_template` SET `DamageModifier` = 6 WHERE `entry` = 17766; -- Horde Silithyst Sentinel (was 4.6)

-- Creature resistances (vmangos creature_template *_res).
-- Missing vanilla resistances.
DELETE FROM `creature_template_resistance` WHERE (`CreatureID`, `School`) IN (
(92, 3), -- Rock Elemental
(332, 2), (332, 3), (332, 4), (332, 5), (332, 6), -- Master Mathias Shaw
(347, 2), (347, 3), (347, 4), (347, 5), (347, 6), -- Grizzle Halfmane
(434, 5), -- Rabid Shadowhide Gnoll
(568, 5), -- Shadowhide Warrior
(746, 3), -- Elder Dragonkin
(819, 6), -- Servant of Ilgalar
(857, 2), (857, 3), (857, 4), (857, 5), (857, 6), -- Donal Osgood
(907, 2), (907, 3), (907, 4), (907, 5), (907, 6), -- Keras Wolfheart
(1049, 3), (1049, 4), (1049, 5), (1049, 6), -- Wyrmkin Firebrand
(1050, 3), (1050, 4), (1050, 5), (1050, 6), -- Scalebane Royal Guard
(1284, 2), (1284, 3), (1284, 4), (1284, 5), (1284, 6), -- Archbishop Benedictus
(1749, 2), (1749, 3), (1749, 4), (1749, 5), (1749, 6), -- Lady Katrana Prestor
(1750, 2), (1750, 3), (1750, 4), (1750, 5), (1750, 6), -- Grand Admiral Jes-Tereth
(1751, 2), (1751, 3), (1751, 4), (1751, 5), (1751, 6), -- Mithras Ironhill
(1840, 2), (1840, 3), (1840, 4), (1840, 5), (1840, 6), -- Grand Inquisitor Isillien
(1842, 2), (1842, 3), (1842, 4), (1842, 5), (1842, 6), -- Highlord Taelan Fordring
(1851, 2), (1851, 3), (1851, 4), (1851, 5), (1851, 6), -- The Husk
(1852, 2), (1852, 3), (1852, 4), (1852, 5), (1852, 6), -- Araj the Summoner
(1855, 2), (1855, 3), (1855, 4), (1855, 5), (1855, 6), -- Tirion Fordring
(1892, 5), -- Moonrage Watcher
(1893, 5), -- Moonrage Sentry
(1896, 5), -- Moonrage Elder
(2275, 3), -- Enraged Stanley
(2302, 2), (2302, 3), (2302, 4), (2302, 5), (2302, 6), -- Aethalas
(2318, 5), -- Argus Shadow Mage
(2592, 3), -- Rumbling Exile
(2647, 5), -- Vilebranch Soul Eater
(2735, 3), -- Lesser Rock Elemental
(2736, 3), -- Greater Rock Elemental
(2755, 2), (2755, 3), (2755, 4), (2755, 5), (2755, 6), -- Myzrael
(2791, 3), -- Enraged Rock Elemental
(2804, 2), (2804, 3), (2804, 4), (2804, 5), (2804, 6), -- Kurden Bloodclaw
(3230, 2), (3230, 3), (3230, 4), (3230, 5), (3230, 6), -- Nazgrel
(3417, 5), -- Living Flame
(3441, 2), (3441, 3), (3441, 4), (3441, 5), (3441, 6), -- Melor Stonehoof
(3468, 2), (3468, 3), (3468, 4), (3468, 5), (3468, 6), -- Ancient of Lore
(3469, 2), (3469, 3), (3469, 4), (3469, 5), (3469, 6), -- Ancient of War
(3529, 5), -- Moonrage Armorer
(3531, 5), -- Moonrage Tailor
(3533, 5), -- Moonrage Leatherworker
(3654, 5), -- Mutanus the Devourer
(3890, 2), (3890, 3), (3890, 4), (3890, 5), (3890, 6), -- Brakgul Deathbringer
(3899, 6), -- Balizar the Umbrage
(4035, 3), -- Furious Stone Spirit
(4046, 2), (4046, 3), (4046, 4), (4046, 5), (4046, 6), -- Magatha Grimtotem
(4047, 2), (4047, 3), (4047, 4), (4047, 5), (4047, 6), -- Zor Lonetree
(4050, 3), -- Cenarion Caretaker
(4051, 3), -- Cenarion Botanist
(4052, 3), -- Cenarion Druid
(4056, 3), -- Mirkfallon Keeper
(4088, 2), (4088, 3), (4088, 4), (4088, 5), (4088, 6), -- Elanaria
(4120, 3), -- Thundering Boulderkin
(4309, 2), (4309, 3), (4309, 4), (4309, 5), (4309, 6), -- Gorm Grimtotem
(4310, 2), (4310, 3), (4310, 4), (4310, 5), (4310, 6), -- Cor Grimtotem
(4374, 2), (4374, 3), (4374, 4), (4374, 5), (4374, 6), -- Strashaz Hydra
(4386, 2), (4386, 3), (4386, 4), (4386, 5), (4386, 6), -- Withervine Bark Ripper
(4499, 3), -- RokAlim the Pounder
(4515, 6), -- Deaths Head Acolyte
(4516, 6), -- Deaths Head Adept
(4528, 3), -- Stone Rumbler
(4679, 5), -- Nether Maiden
(4829, 5), -- Akumai
(4978, 2), (4978, 3), (4978, 5), (4978, 6), -- Akumai Servant
(5118, 2), (5118, 3), (5118, 4), (5118, 5), (5118, 6), -- Brogun Stoneshield
(5312, 2), (5312, 3), (5312, 4), (5312, 5), (5312, 6), -- Lethlas
(5314, 2), (5314, 3), (5314, 4), (5314, 5), (5314, 6), -- Phantim
(5317, 2), (5317, 3), (5317, 4), (5317, 5), (5317, 6), -- Jademir Oracle
(5320, 2), (5320, 3), (5320, 4), (5320, 5), (5320, 6), -- Jademir Boughguard
(5432, 2), -- Giant Surf Glider
(5617, 5), -- Wastewander Shadow Mage
(5718, 2), (5718, 3), (5718, 4), (5718, 5), (5718, 6), -- Rothos
(5764, 2), (5764, 3), (5764, 4), (5764, 5), (5764, 6), -- Guardian of Blizzard
(5889, 2), (5889, 3), (5889, 4), (5889, 5), (5889, 6), -- Mesa Earth Spirit
(5896, 3), (5896, 4), (5896, 5), (5896, 6), -- Fire Spirit
(6010, 2), (6010, 3), (6010, 4), (6010, 5), -- Felhound
(6073, 5), -- Searing Infernal
(6117, 4), -- Highborne Lichling
(6226, 2), -- Mechano-Flamewalker
(6227, 4), -- Mechano-Frostwalker
(6393, 2), (6393, 3), (6393, 4), (6393, 5), (6393, 6), -- Henen Ragetotem
(6395, 2), (6395, 3), (6395, 4), (6395, 5), (6395, 6), -- Sergeant Rutger
(6517, 2), -- Tar Beast
(6518, 2), -- Tar Lurker
(6519, 2), -- Tar Lord
(6527, 2), -- Tar Creeper
(6546, 2), (6546, 3), (6546, 4), (6546, 5), (6546, 6), -- Tabetha
(6646, 3), -- Monnos the Elder
(6932, 2), (6932, 3), (6932, 4), (6932, 5), (6932, 6), -- Swamp Spirit
(7410, 2), (7410, 3), (7410, 4), (7410, 5), (7410, 6), -- Thelman Slatefist
(7427, 2), (7427, 3), (7427, 4), (7427, 5), (7427, 6), -- Taim Ragetotem
(7664, 6), -- Razelikh the Defiler
(7734, 3), -- Ilifar
(7738, 5), -- Burning Servant
(7809, 2), -- Vilebranch Ambusher
(7846, 3), (7846, 4), (7846, 5), (7846, 6), -- Teremus the Devourer
(8197, 2), (8197, 3), (8197, 4), (8197, 5), (8197, 6), -- Chronalis
(8302, 2), -- Deatheye
(8336, 2), (8336, 3), (8336, 4), (8336, 5), (8336, 6), -- Hakkari Sapper
(8526, 5), -- Dark Caster
(8546, 5), -- Dark Adept
(8547, 5), -- Death Cultist
(8548, 5), -- Vile Tutor
(8550, 5), -- Shadowmage
(8551, 5), -- Dark Summoner
(8553, 5), -- Necromancer
(8680, 3), (8680, 4), (8680, 5), (8680, 6), -- Massive Infernal
(8716, 2), (8716, 3), (8716, 4), (8716, 5), -- Dreadlord
(8717, 2), (8717, 3), (8717, 4), (8717, 5), (8717, 6), -- Felguard Elite
(9178, 3), (9178, 4), (9178, 5), (9178, 6), -- Burning Spirit
(9396, 2), (9396, 4), (9396, 5), (9396, 6), -- Ground Pounder
(9522, 6), -- Blackrock Ambusher
(9601, 2), (9601, 3), (9601, 4), (9601, 5), (9601, 6), -- Treant Spirit
(9605, 6), -- Blackrock Raider
(9816, 3), (9816, 4), (9816, 5), (9816, 6), -- Pyroguard Emberseer
(9862, 2), (9862, 5), -- Jaedenar Legionnaire
(10162, 2), (10162, 3), (10162, 4), (10162, 5), (10162, 6), -- Lord Victor Nefarius
(10198, 2), (10198, 3), (10198, 4), (10198, 5), (10198, 6), -- Kashoch the Reaver
(10201, 2), (10201, 3), (10201, 4), (10201, 5), (10201, 6), -- Lady Hederine
(10264, 2), -- Solakar Flamewreath
(10304, 2), (10304, 3), (10304, 4), (10304, 5), (10304, 6), -- Aurora Skycaller
(10321, 2), (10321, 3), (10321, 4), (10321, 5), (10321, 6), -- Emberstrife
(10340, 2), (10340, 3), (10340, 4), (10340, 5), (10340, 6), -- Vaelastrasz the Red
(10360, 2), (10360, 3), (10360, 4), (10360, 5), (10360, 6), -- Kergul Bloodaxe
(10371, 3), (10371, 4), (10371, 5), (10371, 6), -- Rage Talon Captain
(10373, 6), -- Xabraxxis
(10385, 2), (10385, 3), (10385, 4), (10385, 5), (10385, 6), -- Ghostly Citizen
(10387, 2), (10387, 3), (10387, 4), (10387, 5), (10387, 6), -- Vengeful Phantom
(10393, 2), (10393, 3), (10393, 4), (10393, 5), (10393, 6), -- Skul
(10398, 5), -- Thuzadin Shadowcaster
(10429, 2), (10429, 3), (10429, 4), (10429, 5), (10429, 6), -- Warchief Rend Blackhand
(10430, 2), (10430, 3), (10430, 4), (10430, 5), (10430, 6), -- The Beast
(10438, 2), (10438, 3), (10438, 4), (10438, 5), (10438, 6), -- Maleki the Pallid
(10440, 2), (10440, 3), (10440, 4), (10440, 5), (10440, 6), -- Baron Rivendare
(10503, 2), (10503, 3), (10503, 4), (10503, 5), (10503, 6), -- Jandice Barov
(10508, 2), (10508, 3), (10508, 5), (10508, 6), -- Ras Frostwhisper
(10509, 2), (10509, 3), (10509, 4), (10509, 5), (10509, 6), -- Jed Runewatcher
(10581, 2), (10581, 3), (10581, 4), (10581, 5), (10581, 6), -- Young Arikara
(10601, 2), (10601, 3), (10601, 4), (10601, 5), (10601, 6), -- Urok Enforcer
(10618, 2), (10618, 3), (10618, 4), (10618, 5), (10618, 6), -- Rivern Frostwind
(10664, 2), (10664, 3), (10664, 4), (10664, 5), (10664, 6), -- Scryer
(10667, 2), (10667, 3), (10667, 4), (10667, 5), (10667, 6), -- Chromie
(10737, 6), -- Shy-Rotam
(10812, 2), (10812, 3), (10812, 4), (10812, 5), (10812, 6), -- Grand Crusader Dathrohan
(10813, 2), (10813, 3), (10813, 4), (10813, 5), (10813, 6), -- Balnazzar
(10838, 2), (10838, 3), (10838, 4), (10838, 5), (10838, 6), -- Commander Ashlam Valorfist
(10899, 2), (10899, 3), (10899, 4), (10899, 5), (10899, 6), -- Goraluk Anvilcrack
(10918, 2), (10918, 3), (10918, 4), (10918, 5), (10918, 6), -- Lorax
(10923, 2), (10923, 3), (10923, 4), (10923, 5), (10923, 6), -- Tenell Leafrunner
(10924, 2), (10924, 3), (10924, 4), (10924, 5), (10924, 6), -- Ivy Leafrunner
(10929, 2), (10929, 3), (10929, 4), (10929, 5), (10929, 6), -- Haleh
(10942, 2), (10942, 3), (10942, 4), (10942, 5), (10942, 6), -- Nessy
(10984, 2), (10984, 3), (10984, 4), (10984, 5), (10984, 6), -- Winterax Berserker
(11058, 2), (11058, 3), (11058, 4), (11058, 5), (11058, 6), -- Fras Siabi
(11121, 2), (11121, 3), (11121, 4), (11121, 5), (11121, 6), -- Black Guard Swordsmith
(11199, 2), (11199, 3), (11199, 4), (11199, 5), (11199, 6), -- Crimson Cannon
(11439, 2), (11439, 3), (11439, 4), (11439, 5), (11439, 6), -- Illusion of Jandice Barov
(11447, 5), -- Mushgog
(11461, 2), -- Warpwood Guardian
(11462, 2), -- Warpwood Treant
(11464, 2), -- Warpwood Tangler
(11465, 2), -- Warpwood Stomper
(11487, 2), (11487, 3), (11487, 4), (11487, 5), (11487, 6), -- Magister Kalendris
(11496, 2), (11496, 3), (11496, 4), (11496, 5), -- Immolthar
(11501, 2), (11501, 3), (11501, 4), (11501, 5), (11501, 6), -- King Gordok
(11502, 3), (11502, 4), (11502, 5), (11502, 6), -- Ragnaros
(11583, 3), (11583, 4), (11583, 5), (11583, 6), -- Nefarian
(11622, 2), (11622, 3), (11622, 4), (11622, 5), (11622, 6), -- Rattlegore
(11658, 3), (11658, 4), (11658, 5), (11658, 6), -- Molten Giant
(11659, 3), (11659, 4), (11659, 5), (11659, 6), -- Molten Destroyer
(11661, 3), (11661, 4), (11661, 5), (11661, 6), -- Flamewaker
(11662, 3), (11662, 4), (11662, 5), (11662, 6), -- Flamewaker Priest
(11663, 2), (11663, 3), (11663, 4), (11663, 5), (11663, 6), -- Flamewaker Healer
(11665, 4), (11665, 5), (11665, 6), -- Lava Annihilator
(11666, 2), (11666, 3), (11666, 5), (11666, 6), -- Firewalker
(11667, 2), (11667, 3), (11667, 5), (11667, 6), -- Flameguard
(11668, 2), (11668, 3), (11668, 5), (11668, 6), -- Firelord
(11671, 3), (11671, 4), (11671, 5), (11671, 6), -- Core Hound
(11672, 3), (11672, 4), (11672, 5), (11672, 6), -- Core Rager
(11673, 3), (11673, 4), (11673, 5), (11673, 6), -- Ancient Core Hound
(11697, 5), -- Mannoroc Lasher
(11746, 3), -- Desert Rumbler
(11747, 3), -- Desert Rager
(11777, 3), -- Shadowshard Rumbler
(11778, 3), -- Shadowshard Smasher
(11781, 3), -- Ambershard Crusher
(11782, 3), -- Ambershard Destroyer
(11878, 2), (11878, 3), (11878, 4), (11878, 5), (11878, 6), -- Nathanos Blightcaller
(11946, 2), (11946, 3), (11946, 4), (11946, 5), (11946, 6), -- DrekThar
(11947, 2), (11947, 3), (11947, 4), (11947, 5), (11947, 6), -- Captain Galvangar
(11948, 2), (11948, 3), (11948, 4), (11948, 5), (11948, 6), -- Vanndar Stormpike
(11949, 2), (11949, 3), (11949, 4), (11949, 5), (11949, 6), -- Captain Balinda Stonehearth
(11981, 3), (11981, 4), (11981, 5), (11981, 6), -- Flamegor
(11982, 2), (11982, 3), (11982, 4), (11982, 5), (11982, 6), -- Magmadar
(11983, 3), (11983, 4), (11983, 5), (11983, 6), -- Firemaw
(11988, 3), (11988, 4), (11988, 5), (11988, 6), -- Golemagg the Incinerator
(12017, 2), (12017, 3), (12017, 4), (12017, 5), (12017, 6), -- Broodlord Lashlayer
(12018, 3), (12018, 4), (12018, 5), (12018, 6), -- Majordomo Executus
(12056, 3), (12056, 4), (12056, 5), (12056, 6), -- Baron Geddon
(12057, 2), (12057, 3), (12057, 4), (12057, 5), (12057, 6), -- Garr
(12076, 4), (12076, 5), (12076, 6), -- Lava Elemental
(12098, 3), (12098, 4), (12098, 5), (12098, 6), -- Sulfuron Harbinger
(12099, 4), (12099, 5), (12099, 6), -- Firesworn
(12100, 4), (12100, 5), (12100, 6), -- Lava Reaver
(12101, 4), (12101, 5), (12101, 6), -- Lava Surger
(12118, 2), (12118, 3), (12118, 4), (12118, 5), (12118, 6), -- Lucifron
(12119, 3), (12119, 4), (12119, 5), (12119, 6), -- Flamewaker Protector
(12126, 2), (12126, 3), (12126, 4), (12126, 5), (12126, 6), -- Lord Tirion Fordring
(12143, 3), (12143, 4), (12143, 5), (12143, 6), -- Son of Flame
(12159, 2), (12159, 3), (12159, 4), (12159, 5), (12159, 6), -- Korrak the Bloodrager
(12197, 2), (12197, 3), (12197, 4), (12197, 5), (12197, 6), -- Glordrum Steelbeard
(12198, 2), (12198, 3), (12198, 4), (12198, 5), (12198, 6), -- Martin Lindsey
(12201, 3), -- Princess Theradras
(12237, 5), -- Meshlok the Harvester
(12259, 3), (12259, 4), (12259, 6), -- Gehennas
(12264, 3), (12264, 4), (12264, 5), -- Shazzrah
(12265, 3), (12265, 5), (12265, 6), -- Lava Spawn
(12339, 2), (12339, 3), (12339, 4), (12339, 5), (12339, 6), -- Demetria
(12396, 2), (12396, 3), (12396, 4), -- Doomguard Commander
(12435, 2), (12435, 3), (12435, 4), (12435, 5), (12435, 6), -- Razorgore the Untamed
(12457, 2), (12457, 3), (12457, 4), (12457, 5), (12457, 6), -- Blackwing Spellbinder
(12458, 2), (12458, 3), (12458, 4), (12458, 5), (12458, 6), -- Blackwing Taskmaster
(12459, 2), (12459, 3), (12459, 4), (12459, 5), (12459, 6), -- Blackwing Warlock
(12463, 2), (12463, 3), (12463, 4), (12463, 5), (12463, 6), -- Death Talon Flamescale
(12464, 2), (12464, 3), (12464, 4), (12464, 5), (12464, 6), -- Death Talon Seether
(12465, 2), (12465, 3), (12465, 4), (12465, 5), (12465, 6), -- Death Talon Wyrmkin
(12467, 2), (12467, 3), (12467, 4), (12467, 5), (12467, 6), -- Death Talon Captain
(12468, 2), (12468, 3), (12468, 4), (12468, 5), (12468, 6), -- Death Talon Hatcher
(12474, 2), (12474, 3), (12474, 4), (12474, 5), (12474, 6), -- Emeraldon Boughguard
(12476, 2), (12476, 3), (12476, 4), (12476, 5), (12476, 6), -- Emeraldon Oracle
(12477, 2), (12477, 3), (12477, 4), (12477, 5), (12477, 6), -- Verdantine Boughguard
(12478, 2), (12478, 3), (12478, 4), (12478, 5), (12478, 6), -- Verdantine Oracle
(12496, 2), (12496, 3), (12496, 4), (12496, 5), (12496, 6), -- Dreamtracker
(12497, 2), (12497, 3), (12497, 4), (12497, 5), (12497, 6), -- Dreamroarer
(12498, 2), (12498, 3), (12498, 4), (12498, 5), (12498, 6), -- Dreamstalker
(12580, 2), (12580, 3), (12580, 4), (12580, 5), (12580, 6), -- Reginald Windsor
(12756, 2), (12756, 3), (12756, 4), (12756, 5), (12756, 6), -- Lady Onyxia
(12786, 2), (12786, 3), (12786, 4), (12786, 5), (12786, 6), -- Guard Quine
(12787, 2), (12787, 3), (12787, 4), (12787, 5), (12787, 6), -- Guard Hammon
(12788, 2), (12788, 3), (12788, 4), (12788, 5), (12788, 6), -- Legionnaire Teena
(12789, 2), (12789, 3), (12789, 4), (12789, 5), (12789, 6), -- Blood Guard Hiniwana
(12790, 2), (12790, 3), (12790, 4), (12790, 5), (12790, 6), -- Advisor Willington
(12791, 2), (12791, 3), (12791, 4), (12791, 5), (12791, 6), -- Chieftain Earthbind
(12797, 2), (12797, 3), (12797, 4), (12797, 5), (12797, 6), -- Grunt Korf
(12798, 2), (12798, 3), (12798, 4), (12798, 5), (12798, 6), -- Grunt Bekrah
(12800, 4), -- Chimaerok
(12801, 4), -- Arcane Chimaerok
(12802, 2), (12802, 3), (12802, 4), (12802, 5), (12802, 6), -- Chimaerok Devourer
(12803, 2), (12803, 3), (12803, 4), (12803, 5), (12803, 6), -- Lord Lakmaeran
(12876, 2), (12876, 3), (12876, 5), (12876, 6), -- Baron Aquanis
(12898, 2), (12898, 3), (12898, 4), (12898, 5), (12898, 6), -- Phantim Illusion
(12899, 2), (12899, 3), (12899, 4), (12899, 5), (12899, 6), -- Axtroz
(12900, 2), (12900, 3), (12900, 4), (12900, 5), (12900, 6), -- Somnus
(12916, 1), (12916, 2), (12916, 3), (12916, 4), (12916, 5),
(12916, 6), -- Unkillable Test Dummy 60 Low Magic Resistances
(12917, 1), (12917, 2), (12917, 3), (12917, 4), (12917, 5),
(12917, 6), -- Unkillable Test Dummy 60 High Magic Resistances
(13020, 3), (13020, 4), (13020, 5), (13020, 6), -- Vaelastrasz the Corrupt
(13139, 2), (13139, 3), (13139, 4), (13139, 5), (13139, 6), -- Commander Randolph
(13152, 2), (13152, 3), (13152, 4), (13152, 5), (13152, 6), -- Commander Malgor
(13153, 2), (13153, 3), (13153, 4), (13153, 5), (13153, 6), -- Commander Mulfort
(13154, 2), (13154, 3), (13154, 4), (13154, 5), (13154, 6), -- Commander Louis Philips
(13155, 2), (13155, 3), (13155, 4), (13155, 5), (13155, 6), -- Deathstalker Agent
(13256, 2), (13256, 3), (13256, 4), (13256, 5), (13256, 6), -- Lokholar the Ice Lord
(13318, 2), (13318, 3), (13318, 4), (13318, 5), (13318, 6), -- Commander Mortimer
(13319, 2), (13319, 3), (13319, 4), (13319, 5), (13319, 6), -- Commander Duffy
(13320, 2), (13320, 3), (13320, 4), (13320, 5), (13320, 6), -- Commander Karl Philips
(13356, 2), (13356, 3), (13356, 4), (13356, 5), (13356, 6), -- Stormpike Mine Layer
(13357, 2), (13357, 3), (13357, 4), (13357, 5), (13357, 6), -- Frostwolf Mine Layer
(13397, 2), (13397, 3), (13397, 4), (13397, 5), (13397, 6), -- Irondeep Peon
(13419, 2), (13419, 3), (13419, 4), (13419, 5), (13419, 6), -- Ivus the Forest Lord
(13421, 2), (13421, 3), (13421, 4), (13421, 5), (13421, 6), -- Champion Guardian
(13422, 2), (13422, 3), (13422, 4), (13422, 5), (13422, 6), -- Champion Defender
(13446, 2), (13446, 3), (13446, 4), (13446, 5), (13446, 6), -- Field Marshal Teravaine
(13449, 2), (13449, 3), (13449, 4), (13449, 5), (13449, 6), -- Warmaster Garrick
(13527, 2), (13527, 3), (13527, 4), (13527, 5), (13527, 6), -- Champion Commando
(13531, 2), (13531, 3), (13531, 4), (13531, 5), (13531, 6), -- Champion Reaver
(13816, 2), (13816, 3), (13816, 4), (13816, 5), (13816, 6), -- Prospector Stonehewer
(13817, 2), (13817, 3), (13817, 4), (13817, 5), (13817, 6), -- Voggah Deathgrip
(13841, 2), (13841, 3), (13841, 4), (13841, 5), (13841, 6), -- Lieutenant Haggerdin
(13959, 2), (13959, 3), (13959, 4), (13959, 5), (13959, 6), -- Alterac Yeti
(14020, 2), (14020, 3), (14020, 4), (14020, 5), -- Chromaggus
(14025, 6), -- Corrupted Bronze Whelp
(14061, 5), -- Phase Lasher (Fire)
(14062, 5), -- Phase Lasher (Nature)
(14063, 5), -- Phase Lasher (Arcane)
(14162, 2), (14162, 6), -- RaidMage
(14184, 5), -- Phase Lasher (Frost)
(14263, 6), -- Bronze Drakonid
(14285, 2), (14285, 3), (14285, 4), (14285, 5), (14285, 6), -- Frostwolf Battleguard
(14308, 2), (14308, 3), (14308, 4), (14308, 5), (14308, 6), -- Ferra
(14325, 2), (14325, 3), (14325, 4), (14325, 5), (14325, 6), -- Captain Kromcrush
(14347, 2), (14347, 3), (14347, 4), (14347, 5), (14347, 6), -- Highlord Demitrian
(14348, 2), (14348, 3), (14348, 4), (14348, 5), (14348, 6), -- Earthcaller Franzahl
(14390, 2), -- Expeditionary Mountaineer
(14393, 2), -- Expeditionary Priest
(14435, 2), (14435, 4), (14435, 5), (14435, 6), -- Prince Thunderaan
(14436, 2), (14436, 3), (14436, 4), (14436, 5), (14436, 6), -- Morzul Bloodbringer
(14452, 2), (14452, 3), (14452, 4), (14452, 5), -- Enslaved Doomguard Commander
(14456, 2), (14456, 3), (14456, 4), (14456, 5), (14456, 6), -- Blackwing Guardsman
(14462, 3), -- Thundering Invader
(14471, 2), (14471, 3), (14471, 4), (14471, 5), (14471, 6), -- Setis
(14502, 6), -- Xorothian Dreadsteed
(14506, 2), (14506, 3), (14506, 4), (14506, 5), -- Lord Helnurath
(14516, 2), (14516, 3), (14516, 4), (14516, 5), (14516, 6), -- Death Knight Darkreaver
(14524, 2), (14524, 3), (14524, 4), (14524, 5), (14524, 6), -- Vartrus the Ancient
(14525, 2), (14525, 3), (14525, 4), (14525, 5), (14525, 6), -- Stoma the Ancient
(14526, 2), (14526, 3), (14526, 4), (14526, 5), (14526, 6), -- Hastat the Ancient
(14528, 2), (14528, 3), (14528, 4), (14528, 5), (14528, 6), -- Precious
(14538, 2), (14538, 3), (14538, 4), (14538, 5), (14538, 6), -- Precious the Devourer
(14601, 3), (14601, 4), (14601, 5), (14601, 6), -- Ebonroc
(14748, 2), -- Vilebranch Kidnapper
(14823, 2), (14823, 3), (14823, 4), (14823, 5), (14823, 6), -- Silas Darkmoon
(14861, 2), (14861, 3), (14861, 4), (14861, 5), (14861, 6), -- Blood Steward of Kirtonos
(14862, 2), (14862, 3), (14862, 4), (14862, 5), (14862, 6), -- Emissary Romankhan
(14884, 2), (14884, 3), (14884, 4), (14884, 5), (14884, 6), -- Parasitic Serpent
(14921, 2), (14921, 3), (14921, 4), (14921, 5), (14921, 6), -- Rinwosho the Trader
(14942, 2), (14942, 3), (14942, 4), (14942, 5), (14942, 6), -- Kartra Bloodsnarl
(14943, 2), (14943, 3), (14943, 4), (14943, 5), (14943, 6), -- Guses War Rider
(14944, 2), (14944, 3), (14944, 4), (14944, 5), (14944, 6), -- Jeztors War Rider
(14945, 2), (14945, 3), (14945, 4), (14945, 5), (14945, 6), -- Mulvericks War Rider
(14946, 2), (14946, 3), (14946, 4), (14946, 5), (14946, 6), -- Slidores Gryphon
(14947, 2), (14947, 3), (14947, 4), (14947, 5), (14947, 6), -- Ichmans Gryphon
(14948, 2), (14948, 3), (14948, 4), (14948, 5), (14948, 6), -- Vipores Gryphon
(14981, 2), (14981, 3), (14981, 4), (14981, 5), (14981, 6), -- Elfarran
(14982, 2), (14982, 3), (14982, 4), (14982, 5), (14982, 6), -- Lylandris
(14983, 2), (14983, 3), (14983, 4), (14983, 5), (14983, 6), -- Field Marshal Oslight
(14987, 2), (14987, 3), (14987, 4), (14987, 5), (14987, 6), -- Powerful Healing Ward
(15006, 2), (15006, 3), (15006, 4), (15006, 5), (15006, 6), -- Deze Snowbane
(15007, 2), (15007, 3), (15007, 4), (15007, 5), (15007, 6), -- Sir Malory Wheeler
(15008, 2), (15008, 3), (15008, 4), (15008, 5), (15008, 6), -- Lady Hoteshem
(15112, 2), (15112, 3), (15112, 4), (15112, 5), (15112, 6), -- Brain Wash Totem
(15127, 2), (15127, 3), (15127, 4), (15127, 5), (15127, 6), -- Samuel Hawke
(15162, 2), (15162, 3), (15162, 4), (15162, 5), (15162, 6), -- Scarlet Inquisitor
(15172, 2), (15172, 3), (15172, 4), (15172, 5), (15172, 6), -- Glibb
(15181, 2), (15181, 3), (15181, 4), (15181, 5), (15181, 6), -- Commander Maralith
(15182, 2), (15182, 3), (15182, 4), (15182, 5), (15182, 6), -- Vish Kozus
(15185, 2), (15185, 3), (15185, 4), (15185, 5), (15185, 6), -- Brood of Nozdormu
(15192, 2), (15192, 3), (15192, 4), (15192, 5), (15192, 6), -- Anachronos
(15202, 2), (15202, 3), (15202, 4), (15202, 5), (15202, 6), -- Vyral the Vile
(15203, 3), (15203, 4), (15203, 5), (15203, 6), -- Prince Skaldrenox
(15204, 2), (15204, 3), (15204, 4), (15204, 5), (15204, 6), -- High Marshal Whirlaxis
(15205, 2), (15205, 3), (15205, 4), (15205, 5), (15205, 6), -- Baron Kazum
(15206, 2), (15206, 3), (15206, 4), (15206, 5), (15206, 6), -- The Duke of Cynders
(15207, 2), (15207, 3), (15207, 4), (15207, 5), (15207, 6), -- The Duke of Fathoms
(15208, 2), (15208, 3), (15208, 4), (15208, 5), (15208, 6), -- The Duke of Shards
(15215, 2), (15215, 3), (15215, 4), (15215, 5), (15215, 6), -- Mistress Natalia Maralith
(15220, 2), (15220, 3), (15220, 4), (15220, 5), (15220, 6), -- The Duke of Zephyrs
(15224, 2), (15224, 3), (15224, 4), (15224, 5), (15224, 6), -- Dream Fog
(15286, 2), (15286, 3), (15286, 4), (15286, 5), (15286, 6), -- Xilxix
(15288, 2), (15288, 3), (15288, 4), (15288, 5), (15288, 6), -- Aluntir
(15290, 2), (15290, 3), (15290, 4), (15290, 5), (15290, 6), -- Arakis
(15305, 2), (15305, 3), (15305, 5), (15305, 6), -- Lord Skwol
(15378, 2), (15378, 3), (15378, 4), (15378, 5), (15378, 6), -- Merithra of the Dream
(15379, 2), (15379, 3), (15379, 4), (15379, 5), (15379, 6), -- Caelestrasz
(15380, 2), (15380, 3), (15380, 4), (15380, 5), (15380, 6), -- Arygos
(15381, 2), (15381, 3), (15381, 4), (15381, 5), (15381, 6), -- Anachronos the Ancient
(15382, 2), (15382, 3), (15382, 4), (15382, 5), (15382, 6), -- Fandral Staghelm
(15387, 2), (15387, 3), (15387, 4), (15387, 5), (15387, 6), -- Qiraji Warrior
(15424, 2), (15424, 3), (15424, 4), (15424, 5), (15424, 6), -- Anubisath Conqueror
(15481, 2), (15481, 3), (15481, 4), (15481, 5), (15481, 6), -- Spirit of Azuregos
(15491, 2), (15491, 3), (15491, 4), (15491, 5), (15491, 6), -- Eranikus, Tyrant of the Dream
(15552, 2), (15552, 3), (15552, 4), (15552, 5), (15552, 6), -- Doctor Weavil
(15554, 2), (15554, 3), (15554, 4), (15554, 5), (15554, 6), -- Number Two
(15591, 2), (15591, 3), (15591, 4), (15591, 5), (15591, 6), -- Minion of Weavil
(15614, 2), (15614, 3), (15614, 4), (15614, 5), (15614, 6), -- J.D. Shadesong
(15623, 2), (15623, 3), (15623, 4), (15623, 5), (15623, 6), -- Xandivious
(15625, 2), (15625, 3), (15625, 4), (15625, 5), (15625, 6), -- Twilight Corrupter
(15628, 2), (15628, 3), (15628, 4), (15628, 5), (15628, 6), -- Eranikus the Redeemed
(15629, 2), (15629, 3), (15629, 4), (15629, 5), (15629, 6), -- Nightmare Phantasm
(15693, 2), (15693, 3), (15693, 4), (15693, 5), (15693, 6), -- Jonathan the Revelator
(15740, 2), (15740, 3), (15740, 4), (15740, 5), (15740, 6), -- Colossus of Zora
(15741, 2), (15741, 3), (15741, 4), (15741, 5), (15741, 6), -- Colossus of Regal
(15742, 2), (15742, 3), (15742, 4), (15742, 5), (15742, 6), -- Colossus of Ashi
(15743, 2), (15743, 3), (15743, 4), (15743, 5), (15743, 6), -- Colossal Anubisath Warbringer
(15744, 2), (15744, 3), (15744, 4), (15744, 5), (15744, 6), -- Imperial Qiraji Destroyer
(15757, 2), (15757, 3), (15757, 4), (15757, 5), (15757, 6), -- Qiraji Lieutenant General
(15758, 2), (15758, 3), (15758, 4), (15758, 5), (15758, 6), -- Supreme Anubisath Warbringer
(15759, 2), (15759, 3), (15759, 4), (15759, 5), (15759, 6), -- Supreme Silithid Flayer
(15817, 2), (15817, 3), (15817, 4), (15817, 5), (15817, 6), -- Qiraji Brigadier General Pax-lish
(15818, 2), (15818, 3), (15818, 4), (15818, 5), (15818, 6), -- Lieutenant General Nokhor
(15857, 2), (15857, 3), (15857, 4), (15857, 5), (15857, 6), -- Stormwind Cavalryman
(15859, 2), (15859, 3), (15859, 4), (15859, 5), (15859, 6), -- Stormwind Archmage
(15862, 2), (15862, 3), (15862, 4), (15862, 5), (15862, 6), -- Ironforge Cavalryman
(15866, 2), (15866, 3), (15866, 4), (15866, 5), (15866, 6), -- High Commander Lynore Windstryke
(15868, 2), (15868, 3), (15868, 4), (15868, 5), (15868, 6), -- Highlord Leoric Von Zeldig
(15870, 2), (15870, 3), (15870, 4), (15870, 5), (15870, 6), -- Duke August Foehammer
(15963, 2), (15963, 3), (15963, 4), (15963, 5), (15963, 6), -- The Masters Eye
(16042, 2), (16042, 3), (16042, 4), (16042, 5), (16042, 6), -- Lord Valthalak
(16043, 3), -- Magma Lord Bokk
(16073, 2), (16073, 3), (16073, 4), (16073, 5), (16073, 6), -- Spirit of Lord Valthalak
(16387, 2), (16387, 3), (16387, 4), (16387, 5), (16387, 6), -- Atiesh
(16776, 2), (16776, 3), (16776, 4), (16776, 5), (16776, 6), -- Spirit of Blaumeux
(16777, 2), (16777, 3), (16777, 4), (16777, 5), (16777, 6), -- Spirit of Zeliek
(16778, 2), (16778, 3), (16778, 4), (16778, 5), (16778, 6)); -- Spirit of Korthazz
INSERT INTO `creature_template_resistance` (`CreatureID`, `School`, `Resistance`, `VerifiedBuild`) VALUES
(92, 3, 15, 0), -- Rock Elemental
(332, 2, 10, 0), (332, 3, 10, 0), (332, 4, 10, 0), (332, 5, 10, 0), (332, 6, 10, 0), -- Master Mathias Shaw
(347, 2, 5, 0), (347, 3, 5, 0), (347, 4, 5, 0), (347, 5, 5, 0), (347, 6, 5, 0), -- Grizzle Halfmane
(434, 5, 50, 0), -- Rabid Shadowhide Gnoll
(568, 5, 50, 0), -- Shadowhide Warrior
(746, 3, 100, 0), -- Elder Dragonkin
(819, 6, 75, 0), -- Servant of Ilgalar
(857, 2, 5, 0), (857, 3, 5, 0), (857, 4, 5, 0), (857, 5, 5, 0), (857, 6, 5, 0), -- Donal Osgood
(907, 2, 5, 0), (907, 3, 5, 0), (907, 4, 5, 0), (907, 5, 5, 0), (907, 6, 5, 0), -- Keras Wolfheart
(1049, 3, 5, 0), (1049, 4, 5, 0), (1049, 5, 5, 0), (1049, 6, 5, 0), -- Wyrmkin Firebrand
(1050, 3, 5, 0), (1050, 4, 5, 0), (1050, 5, 5, 0), (1050, 6, 5, 0), -- Scalebane Royal Guard
(1284, 2, 15, 0), (1284, 3, 15, 0), (1284, 4, 15, 0), (1284, 5, 15, 0), (1284, 6, 15, 0), -- Archbishop Benedictus
(1749, 2, 10, 0), (1749, 3, 10, 0), (1749, 4, 10, 0), (1749, 5, 10, 0), (1749, 6, 10, 0), -- Lady Katrana Prestor
(1750, 2, 10, 0), (1750, 3, 10, 0), (1750, 4, 10, 0), (1750, 5, 10, 0),
(1750, 6, 10, 0), -- Grand Admiral Jes-Tereth
(1751, 2, 10, 0), (1751, 3, 10, 0), (1751, 4, 10, 0), (1751, 5, 10, 0), (1751, 6, 10, 0), -- Mithras Ironhill
(1840, 2, 15, 0), (1840, 3, 15, 0), (1840, 4, 15, 0), (1840, 5, 15, 0),
(1840, 6, 15, 0), -- Grand Inquisitor Isillien
(1842, 2, 15, 0), (1842, 3, 15, 0), (1842, 4, 15, 0), (1842, 5, 15, 0),
(1842, 6, 15, 0), -- Highlord Taelan Fordring
(1851, 2, 10, 0), (1851, 3, 10, 0), (1851, 4, 10, 0), (1851, 5, 10, 0), (1851, 6, 10, 0), -- The Husk
(1852, 2, 5, 0), (1852, 3, 5, 0), (1852, 4, 5, 0), (1852, 5, 5, 0), (1852, 6, 5, 0), -- Araj the Summoner
(1855, 2, 300, 0), (1855, 3, 300, 0), (1855, 4, 300, 0), (1855, 5, 300, 0), (1855, 6, 300, 0), -- Tirion Fordring
(1892, 5, 5, 0), -- Moonrage Watcher
(1893, 5, 5, 0), -- Moonrage Sentry
(1896, 5, 5, 0), -- Moonrage Elder
(2275, 3, 5, 0), -- Enraged Stanley
(2302, 2, 5, 0), (2302, 3, 5, 0), (2302, 4, 5, 0), (2302, 5, 5, 0), (2302, 6, 5, 0), -- Aethalas
(2318, 5, 100, 0), -- Argus Shadow Mage
(2592, 3, 15, 0), -- Rumbling Exile
(2647, 5, 250, 0), -- Vilebranch Soul Eater
(2735, 3, 15, 0), -- Lesser Rock Elemental
(2736, 3, 15, 0), -- Greater Rock Elemental
(2755, 2, 94, 0), (2755, 3, 94, 0), (2755, 4, 94, 0), (2755, 5, 282, 0), (2755, 6, 94, 0), -- Myzrael
(2791, 3, 15, 0), -- Enraged Rock Elemental
(2804, 2, 5, 0), (2804, 3, 5, 0), (2804, 4, 5, 0), (2804, 5, 5, 0), (2804, 6, 5, 0), -- Kurden Bloodclaw
(3230, 2, 10, 0), (3230, 3, 10, 0), (3230, 4, 10, 0), (3230, 5, 10, 0), (3230, 6, 10, 0), -- Nazgrel
(3417, 5, 30, 0), -- Living Flame
(3441, 2, 10, 0), (3441, 3, 10, 0), (3441, 4, 10, 0), (3441, 5, 10, 0), (3441, 6, 10, 0), -- Melor Stonehoof
(3468, 2, 10, 0), (3468, 3, 10, 0), (3468, 4, 10, 0), (3468, 5, 10, 0), (3468, 6, 10, 0), -- Ancient of Lore
(3469, 2, 10, 0), (3469, 3, 10, 0), (3469, 4, 10, 0), (3469, 5, 10, 0), (3469, 6, 10, 0), -- Ancient of War
(3529, 5, 5, 0), -- Moonrage Armorer
(3531, 5, 5, 0), -- Moonrage Tailor
(3533, 5, 5, 0), -- Moonrage Leatherworker
(3654, 5, 400, 0), -- Mutanus the Devourer
(3890, 2, 5, 0), (3890, 3, 5, 0), (3890, 4, 5, 0), (3890, 5, 5, 0), (3890, 6, 5, 0), -- Brakgul Deathbringer
(3899, 6, 96, 0), -- Balizar the Umbrage
(4035, 3, 15, 0), -- Furious Stone Spirit
(4046, 2, 10, 0), (4046, 3, 10, 0), (4046, 4, 10, 0), (4046, 5, 10, 0), (4046, 6, 10, 0), -- Magatha Grimtotem
(4047, 2, 10, 0), (4047, 3, 10, 0), (4047, 4, 10, 0), (4047, 5, 10, 0), (4047, 6, 10, 0), -- Zor Lonetree
(4050, 3, 52, 0), -- Cenarion Caretaker
(4051, 3, 48, 0), -- Cenarion Botanist
(4052, 3, 54, 0), -- Cenarion Druid
(4056, 3, 80, 0), -- Mirkfallon Keeper
(4088, 2, 10, 0), (4088, 3, 10, 0), (4088, 4, 10, 0), (4088, 5, 10, 0), (4088, 6, 10, 0), -- Elanaria
(4120, 3, 15, 0), -- Thundering Boulderkin
(4309, 2, 10, 0), (4309, 3, 10, 0), (4309, 4, 10, 0), (4309, 5, 10, 0), (4309, 6, 10, 0), -- Gorm Grimtotem
(4310, 2, 10, 0), (4310, 3, 10, 0), (4310, 4, 10, 0), (4310, 5, 10, 0), (4310, 6, 10, 0), -- Cor Grimtotem
(4374, 2, 15, 0), (4374, 3, 15, 0), (4374, 4, 15, 0), (4374, 5, 15, 0), (4374, 6, 15, 0), -- Strashaz Hydra
(4386, 2, 37, 0), (4386, 3, 37, 0), (4386, 4, 37, 0), (4386, 5, 75, 0), (4386, 6, 37, 0), -- Withervine Bark Ripper
(4499, 3, 15, 0), -- RokAlim the Pounder
(4515, 6, 45, 0), -- Deaths Head Acolyte
(4516, 6, 45, 0), -- Deaths Head Adept
(4528, 3, 15, 0), -- Stone Rumbler
(4679, 5, 90, 0), -- Nether Maiden
(4829, 5, 40, 0), -- Akumai
(4978, 2, 130, 0), (4978, 3, 26, 0), (4978, 5, 26, 0), (4978, 6, 26, 0), -- Akumai Servant
(5118, 2, 5, 0), (5118, 3, 5, 0), (5118, 4, 5, 0), (5118, 5, 5, 0), (5118, 6, 5, 0), -- Brogun Stoneshield
(5312, 2, 10, 0), (5312, 3, 10, 0), (5312, 4, 10, 0), (5312, 5, 10, 0), (5312, 6, 10, 0), -- Lethlas
(5314, 2, 10, 0), (5314, 3, 10, 0), (5314, 4, 10, 0), (5314, 5, 10, 0), (5314, 6, 10, 0), -- Phantim
(5317, 2, 5, 0), (5317, 3, 5, 0), (5317, 4, 5, 0), (5317, 5, 5, 0), (5317, 6, 5, 0), -- Jademir Oracle
(5320, 2, 10, 0), (5320, 3, 10, 0), (5320, 4, 10, 0), (5320, 5, 10, 0), (5320, 6, 10, 0), -- Jademir Boughguard
(5432, 2, 150, 0), -- Giant Surf Glider
(5617, 5, 105, 0), -- Wastewander Shadow Mage
(5718, 2, 10, 0), (5718, 3, 10, 0), (5718, 4, 10, 0), (5718, 5, 10, 0), (5718, 6, 10, 0), -- Rothos
(5764, 2, 15, 0), (5764, 3, 15, 0), (5764, 4, 15, 0), (5764, 5, 15, 0), (5764, 6, 15, 0), -- Guardian of Blizzard
(5889, 2, 1, 0), (5889, 3, 15, 0), (5889, 4, 1, 0), (5889, 5, 1, 0), (5889, 6, 1, 0), -- Mesa Earth Spirit
(5896, 3, 10, 0), (5896, 4, 10, 0), (5896, 5, 10, 0), (5896, 6, 10, 0), -- Fire Spirit
(6010, 2, 75, 0), (6010, 3, 75, 0), (6010, 4, 75, 0), (6010, 5, 75, 0), -- Felhound
(6073, 5, 45, 0), -- Searing Infernal
(6117, 4, 80, 0), -- Highborne Lichling
(6226, 2, 15, 0), -- Mechano-Flamewalker
(6227, 4, 75, 0), -- Mechano-Frostwalker
(6393, 2, 10, 0), (6393, 3, 10, 0), (6393, 4, 10, 0), (6393, 5, 10, 0), (6393, 6, 10, 0), -- Henen Ragetotem
(6395, 2, 10, 0), (6395, 3, 10, 0), (6395, 4, 10, 0), (6395, 5, 10, 0), (6395, 6, 10, 0), -- Sergeant Rutger
(6517, 2, -51, 0), -- Tar Beast
(6518, 2, -51, 0), -- Tar Lurker
(6519, 2, -51, 0), -- Tar Lord
(6527, 2, -51, 0), -- Tar Creeper
(6546, 2, 10, 0), (6546, 3, 10, 0), (6546, 4, 10, 0), (6546, 5, 10, 0), (6546, 6, 10, 0), -- Tabetha
(6646, 3, 400, 0), -- Monnos the Elder
(6932, 2, 40, 0), (6932, 3, 40, 0), (6932, 4, 40, 0), (6932, 5, 80, 0), (6932, 6, 40, 0), -- Swamp Spirit
(7410, 2, 5, 0), (7410, 3, 5, 0), (7410, 4, 5, 0), (7410, 5, 5, 0), (7410, 6, 5, 0), -- Thelman Slatefist
(7427, 2, 5, 0), (7427, 3, 5, 0), (7427, 4, 5, 0), (7427, 5, 5, 0), (7427, 6, 5, 0), -- Taim Ragetotem
(7664, 6, 240, 0), -- Razelikh the Defiler
(7734, 3, 15, 0), -- Ilifar
(7738, 5, 30, 0), -- Burning Servant
(7809, 2, 70, 0), -- Vilebranch Ambusher
(7846, 3, 15, 0), (7846, 4, 15, 0), (7846, 5, 15, 0), (7846, 6, 15, 0), -- Teremus the Devourer
(8197, 2, 5, 0), (8197, 3, 5, 0), (8197, 4, 5, 0), (8197, 5, 5, 0), (8197, 6, 5, 0), -- Chronalis
(8302, 2, 100, 0), -- Deatheye
(8336, 2, 2, 0), (8336, 3, 2, 0), (8336, 4, 2, 0), (8336, 5, 2, 0), (8336, 6, 2, 0), -- Hakkari Sapper
(8526, 5, 100, 0), -- Dark Caster
(8546, 5, 88, 0), -- Dark Adept
(8547, 5, 81, 0), -- Death Cultist
(8548, 5, 85, 0), -- Vile Tutor
(8550, 5, 90, 0), -- Shadowmage
(8551, 5, 84, 0), -- Dark Summoner
(8553, 5, 91, 0), -- Necromancer
(8680, 3, 15, 0), (8680, 4, 15, 0), (8680, 5, 15, 0), (8680, 6, 15, 0), -- Massive Infernal
(8716, 2, 10, 0), (8716, 3, 10, 0), (8716, 4, 10, 0), (8716, 5, 10, 0), -- Dreadlord
(8717, 2, 15, 0), (8717, 3, 15, 0), (8717, 4, 15, 0), (8717, 5, 15, 0), (8717, 6, 15, 0), -- Felguard Elite
(9178, 3, 60, 0), (9178, 4, 60, 0), (9178, 5, 60, 0), (9178, 6, 60, 0), -- Burning Spirit
(9396, 2, 42, 0), (9396, 4, 42, 0), (9396, 5, 42, 0), (9396, 6, 42, 0), -- Ground Pounder
(9522, 6, 100, 0), -- Blackrock Ambusher
(9601, 2, 53, 0), (9601, 3, 53, 0), (9601, 4, 53, 0), (9601, 5, 106, 0), (9601, 6, 53, 0), -- Treant Spirit
(9605, 6, 100, 0), -- Blackrock Raider
(9816, 3, 15, 0), (9816, 4, 15, 0), (9816, 5, 15, 0), (9816, 6, 15, 0), -- Pyroguard Emberseer
(9862, 2, 50, 0), (9862, 5, 50, 0), -- Jaedenar Legionnaire
(10162, 2, 15, 0), (10162, 3, 15, 0), (10162, 4, 15, 0), (10162, 5, 15, 0),
(10162, 6, 15, 0), -- Lord Victor Nefarius
(10198, 2, 5, 0), (10198, 3, 5, 0), (10198, 4, 5, 0), (10198, 5, 5, 0), (10198, 6, 5, 0), -- Kashoch the Reaver
(10201, 2, 5, 0), (10201, 3, 5, 0), (10201, 4, 5, 0), (10201, 5, 5, 0), (10201, 6, 5, 0), -- Lady Hederine
(10264, 2, 177, 0), -- Solakar Flamewreath
(10304, 2, 10, 0), (10304, 3, 10, 0), (10304, 4, 10, 0), (10304, 5, 10, 0), (10304, 6, 10, 0), -- Aurora Skycaller
(10321, 2, 5, 0), (10321, 3, 5, 0), (10321, 4, 5, 0), (10321, 5, 5, 0), (10321, 6, 5, 0), -- Emberstrife
(10340, 2, 10, 0), (10340, 3, 10, 0), (10340, 4, 10, 0), (10340, 5, 10, 0),
(10340, 6, 10, 0), -- Vaelastrasz the Red
(10360, 2, 5, 0), (10360, 3, 5, 0), (10360, 4, 5, 0), (10360, 5, 5, 0), (10360, 6, 5, 0), -- Kergul Bloodaxe
(10371, 3, 10, 0), (10371, 4, 10, 0), (10371, 5, 10, 0), (10371, 6, 10, 0), -- Rage Talon Captain
(10373, 6, 76, 0), -- Xabraxxis
(10385, 2, 168, 0), (10385, 3, 168, 0), (10385, 4, 168, 0), (10385, 5, 168, 0),
(10385, 6, 168, 0), -- Ghostly Citizen
(10387, 2, 161, 0), (10387, 3, 161, 0), (10387, 4, 161, 0), (10387, 5, 161, 0),
(10387, 6, 161, 0), -- Vengeful Phantom
(10393, 2, 15, 0), (10393, 3, 15, 0), (10393, 4, 15, 0), (10393, 5, 15, 0), (10393, 6, 15, 0), -- Skul
(10398, 5, 80, 0), -- Thuzadin Shadowcaster
(10429, 2, 15, 0), (10429, 3, 15, 0), (10429, 4, 15, 0), (10429, 5, 15, 0),
(10429, 6, 15, 0), -- Warchief Rend Blackhand
(10430, 2, 15, 0), (10430, 3, 15, 0), (10430, 4, 15, 0), (10430, 5, 15, 0), (10430, 6, 15, 0), -- The Beast
(10438, 2, 5, 0), (10438, 3, 5, 0), (10438, 4, 5, 0), (10438, 5, 5, 0), (10438, 6, 5, 0), -- Maleki the Pallid
(10440, 2, 5, 0), (10440, 3, 5, 0), (10440, 4, 5, 0), (10440, 5, 5, 0), (10440, 6, 5, 0), -- Baron Rivendare
(10503, 2, 5, 0), (10503, 3, 5, 0), (10503, 4, 5, 0), (10503, 5, 5, 0), (10503, 6, 5, 0), -- Jandice Barov
(10508, 2, 5, 0), (10508, 3, 5, 0), (10508, 5, 5, 0), (10508, 6, 5, 0), -- Ras Frostwhisper
(10509, 2, 15, 0), (10509, 3, 15, 0), (10509, 4, 15, 0), (10509, 5, 15, 0), (10509, 6, 15, 0), -- Jed Runewatcher
(10581, 2, 2, 0), (10581, 3, 2, 0), (10581, 4, 2, 0), (10581, 5, 2, 0), (10581, 6, 2, 0), -- Young Arikara
(10601, 2, 54, 0), (10601, 3, 54, 0), (10601, 4, 54, 0), (10601, 5, 54, 0), (10601, 6, 54, 0), -- Urok Enforcer
(10618, 2, 10, 0), (10618, 3, 10, 0), (10618, 4, 10, 0), (10618, 5, 10, 0), (10618, 6, 10, 0), -- Rivern Frostwind
(10664, 2, 10, 0), (10664, 3, 10, 0), (10664, 4, 10, 0), (10664, 5, 10, 0), (10664, 6, 10, 0), -- Scryer
(10667, 2, 15, 0), (10667, 3, 15, 0), (10667, 4, 15, 0), (10667, 5, 15, 0), (10667, 6, 15, 0), -- Chromie
(10737, 6, 10, 0), -- Shy-Rotam
(10812, 2, 5, 0), (10812, 3, 5, 0), (10812, 4, 5, 0), (10812, 5, 5, 0),
(10812, 6, 5, 0), -- Grand Crusader Dathrohan
(10813, 2, 5, 0), (10813, 3, 5, 0), (10813, 4, 5, 0), (10813, 5, 5, 0), (10813, 6, 248, 0), -- Balnazzar
(10838, 2, 5, 0), (10838, 3, 5, 0), (10838, 4, 5, 0), (10838, 5, 5, 0),
(10838, 6, 5, 0), -- Commander Ashlam Valorfist
(10899, 2, 5, 0), (10899, 3, 5, 0), (10899, 4, 5, 0), (10899, 5, 5, 0), (10899, 6, 5, 0), -- Goraluk Anvilcrack
(10918, 2, 5, 0), (10918, 3, 5, 0), (10918, 4, 5, 0), (10918, 5, 5, 0), (10918, 6, 5, 0), -- Lorax
(10923, 2, 10, 0), (10923, 3, 10, 0), (10923, 4, 10, 0), (10923, 5, 10, 0), (10923, 6, 10, 0), -- Tenell Leafrunner
(10924, 2, 15, 0), (10924, 3, 15, 0), (10924, 4, 15, 0), (10924, 5, 15, 0), (10924, 6, 15, 0), -- Ivy Leafrunner
(10929, 2, 10, 0), (10929, 3, 10, 0), (10929, 4, 10, 0), (10929, 5, 10, 0), (10929, 6, 10, 0), -- Haleh
(10942, 2, 10, 0), (10942, 3, 10, 0), (10942, 4, 10, 0), (10942, 5, 10, 0), (10942, 6, 10, 0), -- Nessy
(10984, 2, 5, 0), (10984, 3, 5, 0), (10984, 4, 5, 0), (10984, 5, 5, 0), (10984, 6, 5, 0), -- Winterax Berserker
(11058, 2, 5, 0), (11058, 3, 5, 0), (11058, 4, 5, 0), (11058, 5, 5, 0), (11058, 6, 5, 0), -- Fras Siabi
(11121, 2, 5, 0), (11121, 3, 5, 0), (11121, 4, 5, 0), (11121, 5, 5, 0), (11121, 6, 5, 0), -- Black Guard Swordsmith
(11199, 2, 5, 0), (11199, 3, 5, 0), (11199, 4, 5, 0), (11199, 5, 5, 0), (11199, 6, 5, 0), -- Crimson Cannon
(11439, 2, 5, 0), (11439, 3, 5, 0), (11439, 4, 5, 0), (11439, 5, 5, 0),
(11439, 6, 5, 0), -- Illusion of Jandice Barov
(11447, 5, 30, 0), -- Mushgog
(11461, 2, -58, 0), -- Warpwood Guardian
(11462, 2, -55, 0), -- Warpwood Treant
(11464, 2, -56, 0), -- Warpwood Tangler
(11465, 2, -58, 0), -- Warpwood Stomper
(11487, 2, 5, 0), (11487, 3, 5, 0), (11487, 4, 5, 0), (11487, 5, 5, 0), (11487, 6, 5, 0), -- Magister Kalendris
(11496, 2, 10, 0), (11496, 3, 10, 0), (11496, 4, 10, 0), (11496, 5, 10, 0), -- Immolthar
(11501, 2, 5, 0), (11501, 3, 5, 0), (11501, 4, 5, 0), (11501, 5, 5, 0), (11501, 6, 5, 0), -- King Gordok
(11502, 3, 15, 0), (11502, 4, 15, 0), (11502, 5, 15, 0), (11502, 6, 15, 0), -- Ragnaros
(11583, 3, 15, 0), (11583, 4, 15, 0), (11583, 5, 15, 0), (11583, 6, 15, 0), -- Nefarian
(11622, 2, 5, 0), (11622, 3, 5, 0), (11622, 4, 5, 0), (11622, 5, 5, 0), (11622, 6, 5, 0), -- Rattlegore
(11658, 3, 15, 0), (11658, 4, 15, 0), (11658, 5, 15, 0), (11658, 6, 15, 0), -- Molten Giant
(11659, 3, 15, 0), (11659, 4, 15, 0), (11659, 5, 15, 0), (11659, 6, 15, 0), -- Molten Destroyer
(11661, 3, 15, 0), (11661, 4, 15, 0), (11661, 5, 15, 0), (11661, 6, 15, 0), -- Flamewaker
(11662, 3, 15, 0), (11662, 4, 15, 0), (11662, 5, 15, 0), (11662, 6, 15, 0), -- Flamewaker Priest
(11663, 2, 15, 0), (11663, 3, 15, 0), (11663, 4, 15, 0), (11663, 5, 15, 0), (11663, 6, 15, 0), -- Flamewaker Healer
(11665, 4, 15, 0), (11665, 5, 15, 0), (11665, 6, 15, 0), -- Lava Annihilator
(11666, 2, 15, 0), (11666, 3, 15, 0), (11666, 5, 15, 0), (11666, 6, 15, 0), -- Firewalker
(11667, 2, 15, 0), (11667, 3, 15, 0), (11667, 5, 15, 0), (11667, 6, 15, 0), -- Flameguard
(11668, 2, 15, 0), (11668, 3, 15, 0), (11668, 5, 15, 0), (11668, 6, 15, 0), -- Firelord
(11671, 3, 15, 0), (11671, 4, 15, 0), (11671, 5, 15, 0), (11671, 6, 15, 0), -- Core Hound
(11672, 3, 15, 0), (11672, 4, 15, 0), (11672, 5, 15, 0), (11672, 6, 15, 0), -- Core Rager
(11673, 3, 15, 0), (11673, 4, 15, 0), (11673, 5, 15, 0), (11673, 6, 15, 0), -- Ancient Core Hound
(11697, 5, 45, 0), -- Mannoroc Lasher
(11746, 3, 15, 0), -- Desert Rumbler
(11747, 3, 15, 0), -- Desert Rager
(11777, 3, 15, 0), -- Shadowshard Rumbler
(11778, 3, 15, 0), -- Shadowshard Smasher
(11781, 3, 15, 0), -- Ambershard Crusher
(11782, 3, 15, 0), -- Ambershard Destroyer
(11878, 2, 10, 0), (11878, 3, 10, 0), (11878, 4, 10, 0), (11878, 5, 10, 0),
(11878, 6, 10, 0), -- Nathanos Blightcaller
(11946, 2, 10, 0), (11946, 3, 10, 0), (11946, 4, 10, 0), (11946, 5, 10, 0), (11946, 6, 10, 0), -- DrekThar
(11947, 2, 5, 0), (11947, 3, 5, 0), (11947, 4, 5, 0), (11947, 5, 5, 0), (11947, 6, 5, 0), -- Captain Galvangar
(11948, 2, 10, 0), (11948, 3, 10, 0), (11948, 4, 10, 0), (11948, 5, 10, 0), (11948, 6, 10, 0), -- Vanndar Stormpike
(11949, 2, 5, 0), (11949, 3, 5, 0), (11949, 4, 5, 0), (11949, 5, 5, 0),
(11949, 6, 5, 0), -- Captain Balinda Stonehearth
(11981, 3, 15, 0), (11981, 4, 15, 0), (11981, 5, 15, 0), (11981, 6, 15, 0), -- Flamegor
(11982, 2, 200, 0), (11982, 3, 15, 0), (11982, 4, 15, 0), (11982, 5, 15, 0), (11982, 6, 15, 0), -- Magmadar
(11983, 3, 15, 0), (11983, 4, 15, 0), (11983, 5, 15, 0), (11983, 6, 15, 0), -- Firemaw
(11988, 3, 15, 0), (11988, 4, 15, 0), (11988, 5, 15, 0), (11988, 6, 15, 0), -- Golemagg the Incinerator
(12017, 2, 15, 0), (12017, 3, 15, 0), (12017, 4, 15, 0), (12017, 5, 15, 0),
(12017, 6, 15, 0), -- Broodlord Lashlayer
(12018, 3, 15, 0), (12018, 4, 15, 0), (12018, 5, 15, 0), (12018, 6, 40, 0), -- Majordomo Executus
(12056, 3, 15, 0), (12056, 4, 15, 0), (12056, 5, 15, 0), (12056, 6, 15, 0), -- Baron Geddon
(12057, 2, 200, 0), (12057, 3, 15, 0), (12057, 4, 15, 0), (12057, 5, 15, 0), (12057, 6, 15, 0), -- Garr
(12076, 4, 15, 0), (12076, 5, 15, 0), (12076, 6, 15, 0), -- Lava Elemental
(12098, 3, 15, 0), (12098, 4, 15, 0), (12098, 5, 15, 0), (12098, 6, 40, 0), -- Sulfuron Harbinger
(12099, 4, 15, 0), (12099, 5, 15, 0), (12099, 6, 15, 0), -- Firesworn
(12100, 4, 15, 0), (12100, 5, 15, 0), (12100, 6, 15, 0), -- Lava Reaver
(12101, 4, 15, 0), (12101, 5, 15, 0), (12101, 6, 15, 0), -- Lava Surger
(12118, 2, 93, 0), (12118, 3, 15, 0), (12118, 4, 15, 0), (12118, 5, 186, 0), (12118, 6, 15, 0), -- Lucifron
(12119, 3, 10, 0), (12119, 4, 10, 0), (12119, 5, 10, 0), (12119, 6, 10, 0), -- Flamewaker Protector
(12126, 2, 15, 0), (12126, 3, 15, 0), (12126, 4, 15, 0), (12126, 5, 15, 0),
(12126, 6, 15, 0), -- Lord Tirion Fordring
(12143, 3, 15, 0), (12143, 4, -93, 0), (12143, 5, 15, 0), (12143, 6, 15, 0), -- Son of Flame
(12159, 2, 10, 0), (12159, 3, 10, 0), (12159, 4, 10, 0), (12159, 5, 10, 0),
(12159, 6, 10, 0), -- Korrak the Bloodrager
(12197, 2, 5, 0), (12197, 3, 5, 0), (12197, 4, 5, 0), (12197, 5, 5, 0), (12197, 6, 5, 0), -- Glordrum Steelbeard
(12198, 2, 5, 0), (12198, 3, 5, 0), (12198, 4, 5, 0), (12198, 5, 5, 0), (12198, 6, 5, 0), -- Martin Lindsey
(12201, 3, 15, 0), -- Princess Theradras
(12237, 5, 30, 0), -- Meshlok the Harvester
(12259, 3, 15, 0), (12259, 4, 15, 0), (12259, 6, 15, 0), -- Gehennas
(12264, 3, 15, 0), (12264, 4, 15, 0), (12264, 5, 15, 0), -- Shazzrah
(12265, 3, 15, 0), (12265, 5, 15, 0), (12265, 6, 15, 0), -- Lava Spawn
(12339, 2, 5, 0), (12339, 3, 5, 0), (12339, 4, 5, 0), (12339, 5, 5, 0), (12339, 6, 5, 0), -- Demetria
(12396, 2, 5, 0), (12396, 3, 5, 0), (12396, 4, 5, 0), -- Doomguard Commander
(12435, 2, 15, 0), (12435, 3, 15, 0), (12435, 4, 15, 0), (12435, 5, 15, 0),
(12435, 6, 15, 0), -- Razorgore the Untamed
(12457, 2, 10, 0), (12457, 3, 10, 0), (12457, 4, 10, 0), (12457, 5, 10, 0),
(12457, 6, 10, 0), -- Blackwing Spellbinder
(12458, 2, 10, 0), (12458, 3, 10, 0), (12458, 4, 10, 0), (12458, 5, 10, 0),
(12458, 6, 10, 0), -- Blackwing Taskmaster
(12459, 2, 5, 0), (12459, 3, 5, 0), (12459, 4, 5, 0), (12459, 5, 5, 0), (12459, 6, 5, 0), -- Blackwing Warlock
(12463, 2, 10, 0), (12463, 3, 10, 0), (12463, 4, 10, 0), (12463, 5, 10, 0),
(12463, 6, 10, 0), -- Death Talon Flamescale
(12464, 2, 10, 0), (12464, 3, 10, 0), (12464, 4, 10, 0), (12464, 5, 10, 0),
(12464, 6, 10, 0), -- Death Talon Seether
(12465, 2, 5, 0), (12465, 3, 5, 0), (12465, 4, 5, 0), (12465, 5, 5, 0), (12465, 6, 5, 0), -- Death Talon Wyrmkin
(12467, 2, 10, 0), (12467, 3, 10, 0), (12467, 4, 10, 0), (12467, 5, 10, 0),
(12467, 6, 10, 0), -- Death Talon Captain
(12468, 2, 5, 0), (12468, 3, 5, 0), (12468, 4, 5, 0), (12468, 5, 5, 0), (12468, 6, 5, 0), -- Death Talon Hatcher
(12474, 2, 10, 0), (12474, 3, 10, 0), (12474, 4, 10, 0), (12474, 5, 10, 0),
(12474, 6, 10, 0), -- Emeraldon Boughguard
(12476, 2, 5, 0), (12476, 3, 5, 0), (12476, 4, 5, 0), (12476, 5, 5, 0), (12476, 6, 5, 0), -- Emeraldon Oracle
(12477, 2, 10, 0), (12477, 3, 10, 0), (12477, 4, 10, 0), (12477, 5, 10, 0),
(12477, 6, 10, 0), -- Verdantine Boughguard
(12478, 2, 5, 0), (12478, 3, 5, 0), (12478, 4, 5, 0), (12478, 5, 5, 0), (12478, 6, 5, 0), -- Verdantine Oracle
(12496, 2, 10, 0), (12496, 3, 10, 0), (12496, 4, 10, 0), (12496, 5, 10, 0), (12496, 6, 10, 0), -- Dreamtracker
(12497, 2, 10, 0), (12497, 3, 10, 0), (12497, 4, 10, 0), (12497, 5, 10, 0), (12497, 6, 10, 0), -- Dreamroarer
(12498, 2, 10, 0), (12498, 3, 10, 0), (12498, 4, 10, 0), (12498, 5, 10, 0), (12498, 6, 10, 0), -- Dreamstalker
(12580, 2, 15, 0), (12580, 3, 15, 0), (12580, 4, 15, 0), (12580, 5, 15, 0), (12580, 6, 15, 0), -- Reginald Windsor
(12756, 2, 15, 0), (12756, 3, 15, 0), (12756, 4, 15, 0), (12756, 5, 15, 0), (12756, 6, 15, 0), -- Lady Onyxia
(12786, 2, 10, 0), (12786, 3, 10, 0), (12786, 4, 10, 0), (12786, 5, 10, 0), (12786, 6, 10, 0), -- Guard Quine
(12787, 2, 10, 0), (12787, 3, 10, 0), (12787, 4, 10, 0), (12787, 5, 10, 0), (12787, 6, 10, 0), -- Guard Hammon
(12788, 2, 10, 0), (12788, 3, 10, 0), (12788, 4, 10, 0), (12788, 5, 10, 0), (12788, 6, 10, 0), -- Legionnaire Teena
(12789, 2, 10, 0), (12789, 3, 10, 0), (12789, 4, 10, 0), (12789, 5, 10, 0),
(12789, 6, 10, 0), -- Blood Guard Hiniwana
(12790, 2, 10, 0), (12790, 3, 10, 0), (12790, 4, 10, 0), (12790, 5, 10, 0), (12790, 6, 10, 0), -- Advisor Willington
(12791, 2, 10, 0), (12791, 3, 10, 0), (12791, 4, 10, 0), (12791, 5, 10, 0),
(12791, 6, 10, 0), -- Chieftain Earthbind
(12797, 2, 10, 0), (12797, 3, 10, 0), (12797, 4, 10, 0), (12797, 5, 10, 0), (12797, 6, 10, 0), -- Grunt Korf
(12798, 2, 10, 0), (12798, 3, 10, 0), (12798, 4, 10, 0), (12798, 5, 10, 0), (12798, 6, 10, 0), -- Grunt Bekrah
(12800, 4, 300, 0), -- Chimaerok
(12801, 4, 300, 0), -- Arcane Chimaerok
(12802, 2, 5, 0), (12802, 3, 5, 0), (12802, 4, 300, 0), (12802, 5, 5, 0), (12802, 6, 5, 0), -- Chimaerok Devourer
(12803, 2, 10, 0), (12803, 3, 10, 0), (12803, 4, 300, 0), (12803, 5, 10, 0), (12803, 6, 10, 0), -- Lord Lakmaeran
(12876, 2, 28, 0), (12876, 3, 56, 0), (12876, 5, 28, 0), (12876, 6, 140, 0), -- Baron Aquanis
(12898, 2, 10, 0), (12898, 3, 10, 0), (12898, 4, 10, 0), (12898, 5, 10, 0), (12898, 6, 10, 0), -- Phantim Illusion
(12899, 2, 10, 0), (12899, 3, 10, 0), (12899, 4, 10, 0), (12899, 5, 10, 0), (12899, 6, 10, 0), -- Axtroz
(12900, 2, 10, 0), (12900, 3, 10, 0), (12900, 4, 10, 0), (12900, 5, 10, 0), (12900, 6, 10, 0), -- Somnus
(12916, 1, 60, 0), (12916, 2, 60, 0), (12916, 3, 60, 0),
(12916, 4, 60, 0), (12916, 5, 60, 0), (12916, 6, 60, 0), -- Unkillable Test Dummy 60 Low Magic Resistances
(12917, 1, 225, 0), (12917, 2, 225, 0), (12917, 3, 225, 0),
(12917, 4, 225, 0), (12917, 5, 225, 0), (12917, 6, 225, 0), -- Unkillable Test Dummy 60 High Magic Resistances
(13020, 3, 15, 0), (13020, 4, 15, 0), (13020, 5, 15, 0), (13020, 6, 15, 0), -- Vaelastrasz the Corrupt
(13139, 2, 5, 0), (13139, 3, 5, 0), (13139, 4, 5, 0), (13139, 5, 5, 0), (13139, 6, 5, 0), -- Commander Randolph
(13152, 2, 5, 0), (13152, 3, 5, 0), (13152, 4, 5, 0), (13152, 5, 5, 0), (13152, 6, 5, 0), -- Commander Malgor
(13153, 2, 5, 0), (13153, 3, 5, 0), (13153, 4, 5, 0), (13153, 5, 5, 0), (13153, 6, 5, 0), -- Commander Mulfort
(13154, 2, 5, 0), (13154, 3, 5, 0), (13154, 4, 5, 0), (13154, 5, 5, 0), (13154, 6, 5, 0), -- Commander Louis Philips
(13155, 2, 5, 0), (13155, 3, 5, 0), (13155, 4, 5, 0), (13155, 5, 5, 0), (13155, 6, 5, 0), -- Deathstalker Agent
(13256, 2, 15, 0), (13256, 3, 15, 0), (13256, 4, 15, 0), (13256, 5, 15, 0),
(13256, 6, 15, 0), -- Lokholar the Ice Lord
(13318, 2, 5, 0), (13318, 3, 5, 0), (13318, 4, 5, 0), (13318, 5, 5, 0), (13318, 6, 5, 0), -- Commander Mortimer
(13319, 2, 5, 0), (13319, 3, 5, 0), (13319, 4, 5, 0), (13319, 5, 5, 0), (13319, 6, 5, 0), -- Commander Duffy
(13320, 2, 5, 0), (13320, 3, 5, 0), (13320, 4, 5, 0), (13320, 5, 5, 0), (13320, 6, 5, 0), -- Commander Karl Philips
(13356, 2, 15, 0), (13356, 3, 15, 0), (13356, 4, 15, 0), (13356, 5, 15, 0),
(13356, 6, 15, 0), -- Stormpike Mine Layer
(13357, 2, 15, 0), (13357, 3, 15, 0), (13357, 4, 15, 0), (13357, 5, 15, 0),
(13357, 6, 15, 0), -- Frostwolf Mine Layer
(13397, 2, 15, 0), (13397, 3, 15, 0), (13397, 4, 15, 0), (13397, 5, 15, 0), (13397, 6, 15, 0), -- Irondeep Peon
(13419, 2, 15, 0), (13419, 3, 15, 0), (13419, 4, 15, 0), (13419, 5, 15, 0),
(13419, 6, 15, 0), -- Ivus the Forest Lord
(13421, 2, 10, 0), (13421, 3, 10, 0), (13421, 4, 10, 0), (13421, 5, 10, 0), (13421, 6, 10, 0), -- Champion Guardian
(13422, 2, 10, 0), (13422, 3, 10, 0), (13422, 4, 10, 0), (13422, 5, 10, 0), (13422, 6, 10, 0), -- Champion Defender
(13446, 2, 5, 0), (13446, 3, 5, 0), (13446, 4, 5, 0), (13446, 5, 5, 0), (13446, 6, 5, 0), -- Field Marshal Teravaine
(13449, 2, 5, 0), (13449, 3, 5, 0), (13449, 4, 5, 0), (13449, 5, 5, 0), (13449, 6, 5, 0), -- Warmaster Garrick
(13527, 2, 5, 0), (13527, 3, 5, 0), (13527, 4, 5, 0), (13527, 5, 5, 0), (13527, 6, 5, 0), -- Champion Commando
(13531, 2, 5, 0), (13531, 3, 5, 0), (13531, 4, 5, 0), (13531, 5, 5, 0), (13531, 6, 5, 0), -- Champion Reaver
(13816, 2, 5, 0), (13816, 3, 5, 0), (13816, 4, 5, 0), (13816, 5, 5, 0), (13816, 6, 5, 0), -- Prospector Stonehewer
(13817, 2, 5, 0), (13817, 3, 5, 0), (13817, 4, 5, 0), (13817, 5, 5, 0), (13817, 6, 5, 0), -- Voggah Deathgrip
(13841, 2, 5, 0), (13841, 3, 5, 0), (13841, 4, 5, 0), (13841, 5, 5, 0), (13841, 6, 5, 0), -- Lieutenant Haggerdin
(13959, 2, 5, 0), (13959, 3, 5, 0), (13959, 4, 5, 0), (13959, 5, 5, 0), (13959, 6, 5, 0), -- Alterac Yeti
(14020, 2, 15, 0), (14020, 3, 15, 0), (14020, 4, 15, 0), (14020, 5, 15, 0), -- Chromaggus
(14025, 6, 300, 0), -- Corrupted Bronze Whelp
(14061, 5, 275, 0), -- Phase Lasher (Fire)
(14062, 5, 275, 0), -- Phase Lasher (Nature)
(14063, 5, 275, 0), -- Phase Lasher (Arcane)
(14162, 2, 100, 0), (14162, 6, 100, 0), -- RaidMage
(14184, 5, 275, 0), -- Phase Lasher (Frost)
(14263, 6, 400, 0), -- Bronze Drakonid
(14285, 2, 5, 0), (14285, 3, 5, 0), (14285, 4, 5, 0), (14285, 5, 5, 0), (14285, 6, 5, 0), -- Frostwolf Battleguard
(14308, 2, 5, 0), (14308, 3, 5, 0), (14308, 4, 5, 0), (14308, 5, 5, 0), (14308, 6, 5, 0), -- Ferra
(14325, 2, 5, 0), (14325, 3, 5, 0), (14325, 4, 5, 0), (14325, 5, 5, 0), (14325, 6, 5, 0), -- Captain Kromcrush
(14347, 2, 10, 0), (14347, 3, 10, 0), (14347, 4, 10, 0), (14347, 5, 10, 0), (14347, 6, 10, 0), -- Highlord Demitrian
(14348, 2, 10, 0), (14348, 3, 10, 0), (14348, 4, 10, 0), (14348, 5, 10, 0),
(14348, 6, 10, 0), -- Earthcaller Franzahl
(14390, 2, 290, 0), -- Expeditionary Mountaineer
(14393, 2, 290, 0), -- Expeditionary Priest
(14435, 2, 15, 0), (14435, 4, 15, 0), (14435, 5, 15, 0), (14435, 6, 15, 0), -- Prince Thunderaan
(14436, 2, 5, 0), (14436, 3, 5, 0), (14436, 4, 5, 0), (14436, 5, 5, 0), (14436, 6, 5, 0), -- Morzul Bloodbringer
(14452, 2, 5, 0), (14452, 3, 5, 0), (14452, 4, 5, 0), (14452, 5, 5, 0), -- Enslaved Doomguard Commander
(14456, 2, 5, 0), (14456, 3, 5, 0), (14456, 4, 5, 0), (14456, 5, 5, 0), (14456, 6, 5, 0), -- Blackwing Guardsman
(14462, 3, 15, 0), -- Thundering Invader
(14471, 2, 10, 0), (14471, 3, 10, 0), (14471, 4, 10, 0), (14471, 5, 10, 0), (14471, 6, 10, 0), -- Setis
(14502, 6, 10, 0), -- Xorothian Dreadsteed
(14506, 2, 10, 0), (14506, 3, 10, 0), (14506, 4, 10, 0), (14506, 5, 10, 0), -- Lord Helnurath
(14516, 2, 10, 0), (14516, 3, 10, 0), (14516, 4, 10, 0), (14516, 5, 10, 0),
(14516, 6, 10, 0), -- Death Knight Darkreaver
(14524, 2, 15, 0), (14524, 3, 15, 0), (14524, 4, 15, 0), (14524, 5, 15, 0),
(14524, 6, 15, 0), -- Vartrus the Ancient
(14525, 2, 15, 0), (14525, 3, 15, 0), (14525, 4, 15, 0), (14525, 5, 15, 0), (14525, 6, 15, 0), -- Stoma the Ancient
(14526, 2, 15, 0), (14526, 3, 15, 0), (14526, 4, 15, 0), (14526, 5, 15, 0), (14526, 6, 15, 0), -- Hastat the Ancient
(14528, 2, 5, 0), (14528, 3, 5, 0), (14528, 4, 5, 0), (14528, 5, 5, 0), (14528, 6, 5, 0), -- Precious
(14538, 2, 5, 0), (14538, 3, 5, 0), (14538, 4, 5, 0), (14538, 5, 5, 0), (14538, 6, 5, 0), -- Precious the Devourer
(14601, 3, 15, 0), (14601, 4, 15, 0), (14601, 5, 15, 0), (14601, 6, 15, 0), -- Ebonroc
(14748, 2, 70, 0), -- Vilebranch Kidnapper
(14823, 2, 5, 0), (14823, 3, 5, 0), (14823, 4, 5, 0), (14823, 5, 5, 0), (14823, 6, 5, 0), -- Silas Darkmoon
(14861, 2, 5, 0), (14861, 3, 5, 0), (14861, 4, 5, 0), (14861, 5, 5, 0),
(14861, 6, 5, 0), -- Blood Steward of Kirtonos
(14862, 2, 15, 0), (14862, 3, 15, 0), (14862, 4, 15, 0), (14862, 5, 15, 0), (14862, 6, 15, 0), -- Emissary Romankhan
(14884, 2, 15, 0), (14884, 3, 15, 0), (14884, 4, 15, 0), (14884, 5, 15, 0), (14884, 6, 15, 0), -- Parasitic Serpent
(14921, 2, 15, 0), (14921, 3, 15, 0), (14921, 4, 15, 0), (14921, 5, 15, 0),
(14921, 6, 15, 0), -- Rinwosho the Trader
(14942, 2, 5, 0), (14942, 3, 5, 0), (14942, 4, 5, 0), (14942, 5, 5, 0), (14942, 6, 5, 0), -- Kartra Bloodsnarl
(14943, 2, 20, 0), (14943, 3, 20, 0), (14943, 4, 20, 0), (14943, 5, 20, 0), (14943, 6, 20, 0), -- Guses War Rider
(14944, 2, 20, 0), (14944, 3, 20, 0), (14944, 4, 20, 0), (14944, 5, 20, 0), (14944, 6, 20, 0), -- Jeztors War Rider
(14945, 2, 20, 0), (14945, 3, 20, 0), (14945, 4, 20, 0), (14945, 5, 20, 0),
(14945, 6, 20, 0), -- Mulvericks War Rider
(14946, 2, 20, 0), (14946, 3, 20, 0), (14946, 4, 20, 0), (14946, 5, 20, 0), (14946, 6, 20, 0), -- Slidores Gryphon
(14947, 2, 20, 0), (14947, 3, 20, 0), (14947, 4, 20, 0), (14947, 5, 20, 0), (14947, 6, 20, 0), -- Ichmans Gryphon
(14948, 2, 20, 0), (14948, 3, 20, 0), (14948, 4, 20, 0), (14948, 5, 20, 0), (14948, 6, 20, 0), -- Vipores Gryphon
(14981, 2, 5, 0), (14981, 3, 5, 0), (14981, 4, 5, 0), (14981, 5, 5, 0), (14981, 6, 5, 0), -- Elfarran
(14982, 2, 5, 0), (14982, 3, 5, 0), (14982, 4, 5, 0), (14982, 5, 5, 0), (14982, 6, 5, 0), -- Lylandris
(14983, 2, 10, 0), (14983, 3, 10, 0), (14983, 4, 10, 0), (14983, 5, 10, 0),
(14983, 6, 10, 0), -- Field Marshal Oslight
(14987, 2, 10, 0), (14987, 3, 10, 0), (14987, 4, 10, 0), (14987, 5, 10, 0),
(14987, 6, 10, 0), -- Powerful Healing Ward
(15006, 2, 5, 0), (15006, 3, 5, 0), (15006, 4, 5, 0), (15006, 5, 5, 0), (15006, 6, 5, 0), -- Deze Snowbane
(15007, 2, 5, 0), (15007, 3, 5, 0), (15007, 4, 5, 0), (15007, 5, 5, 0), (15007, 6, 5, 0), -- Sir Malory Wheeler
(15008, 2, 5, 0), (15008, 3, 5, 0), (15008, 4, 5, 0), (15008, 5, 5, 0), (15008, 6, 5, 0), -- Lady Hoteshem
(15112, 2, 5, 0), (15112, 3, 5, 0), (15112, 4, 5, 0), (15112, 5, 5, 0), (15112, 6, 5, 0), -- Brain Wash Totem
(15127, 2, 15, 0), (15127, 3, 15, 0), (15127, 4, 15, 0), (15127, 5, 15, 0), (15127, 6, 15, 0), -- Samuel Hawke
(15162, 2, 5, 0), (15162, 3, 5, 0), (15162, 4, 5, 0), (15162, 5, 5, 0), (15162, 6, 5, 0), -- Scarlet Inquisitor
(15172, 2, 10, 0), (15172, 3, 10, 0), (15172, 4, 10, 0), (15172, 5, 10, 0), (15172, 6, 10, 0), -- Glibb
(15181, 2, 10, 0), (15181, 3, 10, 0), (15181, 4, 10, 0), (15181, 5, 10, 0), (15181, 6, 10, 0), -- Commander Maralith
(15182, 2, 5, 0), (15182, 3, 5, 0), (15182, 4, 5, 0), (15182, 5, 5, 0), (15182, 6, 5, 0), -- Vish Kozus
(15185, 2, 10, 0), (15185, 3, 10, 0), (15185, 4, 10, 0), (15185, 5, 10, 0), (15185, 6, 10, 0), -- Brood of Nozdormu
(15192, 2, 5, 0), (15192, 3, 5, 0), (15192, 4, 5, 0), (15192, 5, 5, 0), (15192, 6, 5, 0), -- Anachronos
(15202, 2, 5, 0), (15202, 3, 5, 0), (15202, 4, 5, 0), (15202, 5, 5, 0), (15202, 6, 5, 0), -- Vyral the Vile
(15203, 3, 15, 0), (15203, 4, 15, 0), (15203, 5, 15, 0), (15203, 6, 15, 0), -- Prince Skaldrenox
(15204, 2, 15, 0), (15204, 3, 15, 0), (15204, 4, 15, 0), (15204, 5, 15, 0),
(15204, 6, 15, 0), -- High Marshal Whirlaxis
(15205, 2, 15, 0), (15205, 3, 15, 0), (15205, 4, 15, 0), (15205, 5, 15, 0), (15205, 6, 15, 0), -- Baron Kazum
(15206, 2, 10, 0), (15206, 3, 10, 0), (15206, 4, 10, 0), (15206, 5, 10, 0),
(15206, 6, 10, 0), -- The Duke of Cynders
(15207, 2, 10, 0), (15207, 3, 10, 0), (15207, 4, 10, 0), (15207, 5, 10, 0),
(15207, 6, 10, 0), -- The Duke of Fathoms
(15208, 2, 10, 0), (15208, 3, 10, 0), (15208, 4, 10, 0), (15208, 5, 10, 0), (15208, 6, 10, 0), -- The Duke of Shards
(15215, 2, 5, 0), (15215, 3, 5, 0), (15215, 4, 5, 0), (15215, 5, 5, 0),
(15215, 6, 5, 0), -- Mistress Natalia Maralith
(15220, 2, 10, 0), (15220, 3, 10, 0), (15220, 4, 10, 0), (15220, 5, 10, 0),
(15220, 6, 10, 0), -- The Duke of Zephyrs
(15224, 2, 15, 0), (15224, 3, 15, 0), (15224, 4, 15, 0), (15224, 5, 15, 0), (15224, 6, 15, 0), -- Dream Fog
(15286, 2, 10, 0), (15286, 3, 10, 0), (15286, 4, 10, 0), (15286, 5, 10, 0), (15286, 6, 10, 0), -- Xilxix
(15288, 2, 10, 0), (15288, 3, 10, 0), (15288, 4, 10, 0), (15288, 5, 10, 0), (15288, 6, 10, 0), -- Aluntir
(15290, 2, 5, 0), (15290, 3, 5, 0), (15290, 4, 5, 0), (15290, 5, 5, 0), (15290, 6, 5, 0), -- Arakis
(15305, 2, 15, 0), (15305, 3, 15, 0), (15305, 5, 15, 0), (15305, 6, 15, 0), -- Lord Skwol
(15378, 2, 15, 0), (15378, 3, 15, 0), (15378, 4, 15, 0), (15378, 5, 15, 0),
(15378, 6, 15, 0), -- Merithra of the Dream
(15379, 2, 15, 0), (15379, 3, 15, 0), (15379, 4, 15, 0), (15379, 5, 15, 0), (15379, 6, 15, 0), -- Caelestrasz
(15380, 2, 15, 0), (15380, 3, 15, 0), (15380, 4, 15, 0), (15380, 5, 15, 0), (15380, 6, 15, 0), -- Arygos
(15381, 2, 15, 0), (15381, 3, 15, 0), (15381, 4, 15, 0), (15381, 5, 15, 0),
(15381, 6, 15, 0), -- Anachronos the Ancient
(15382, 2, 15, 0), (15382, 3, 15, 0), (15382, 4, 15, 0), (15382, 5, 15, 0), (15382, 6, 15, 0), -- Fandral Staghelm
(15387, 2, 115, 0), (15387, 3, 115, 0), (15387, 4, 115, 0), (15387, 5, 115, 0),
(15387, 6, 115, 0), -- Qiraji Warrior
(15424, 2, 5, 0), (15424, 3, 5, 0), (15424, 4, 5, 0), (15424, 5, 5, 0), (15424, 6, 5, 0), -- Anubisath Conqueror
(15481, 2, 15, 0), (15481, 3, 15, 0), (15481, 4, 15, 0), (15481, 5, 15, 0), (15481, 6, 15, 0), -- Spirit of Azuregos
(15491, 2, 15, 0), (15491, 3, 15, 0), (15491, 4, 15, 0), (15491, 5, 15, 0),
(15491, 6, 15, 0), -- Eranikus, Tyrant of the Dream
(15552, 2, 250, 0), (15552, 3, 250, 0), (15552, 4, 250, 0), (15552, 5, 250, 0), (15552, 6, 250, 0), -- Doctor Weavil
(15554, 2, 150, 0), (15554, 3, 150, 0), (15554, 4, 150, 0), (15554, 5, 150, 0), (15554, 6, 150, 0), -- Number Two
(15591, 2, 15, 0), (15591, 3, 15, 0), (15591, 4, 15, 0), (15591, 5, 15, 0), (15591, 6, 15, 0), -- Minion of Weavil
(15614, 2, 5, 0), (15614, 3, 5, 0), (15614, 4, 5, 0), (15614, 5, 5, 0), (15614, 6, 5, 0), -- J.D. Shadesong
(15623, 2, 10, 0), (15623, 3, 10, 0), (15623, 4, 10, 0), (15623, 5, 10, 0), (15623, 6, 10, 0), -- Xandivious
(15625, 2, 250, 0), (15625, 3, 250, 0), (15625, 4, 250, 0), (15625, 5, 300, 0),
(15625, 6, 250, 0), -- Twilight Corrupter
(15628, 2, 15, 0), (15628, 3, 15, 0), (15628, 4, 15, 0), (15628, 5, 15, 0),
(15628, 6, 15, 0), -- Eranikus the Redeemed
(15629, 2, 10, 0), (15629, 3, 10, 0), (15629, 4, 10, 0), (15629, 5, 10, 0), (15629, 6, 10, 0), -- Nightmare Phantasm
(15693, 2, 5, 0), (15693, 3, 5, 0), (15693, 4, 5, 0), (15693, 5, 5, 0), (15693, 6, 5, 0), -- Jonathan the Revelator
(15740, 2, 250, 0), (15740, 3, 250, 0), (15740, 4, 250, 0), (15740, 5, 250, 0),
(15740, 6, 250, 0), -- Colossus of Zora
(15741, 2, 250, 0), (15741, 3, 250, 0), (15741, 4, 250, 0), (15741, 5, 250, 0),
(15741, 6, 250, 0), -- Colossus of Regal
(15742, 2, 250, 0), (15742, 3, 250, 0), (15742, 4, 250, 0), (15742, 5, 250, 0),
(15742, 6, 250, 0), -- Colossus of Ashi
(15743, 2, 175, 0), (15743, 3, 175, 0), (15743, 4, 175, 0), (15743, 5, 175, 0),
(15743, 6, 175, 0), -- Colossal Anubisath Warbringer
(15744, 2, 175, 0), (15744, 3, 175, 0), (15744, 4, 175, 0), (15744, 5, 175, 0),
(15744, 6, 175, 0), -- Imperial Qiraji Destroyer
(15757, 2, 100, 0), (15757, 3, 100, 0), (15757, 4, 100, 0), (15757, 5, 100, 0),
(15757, 6, 100, 0), -- Qiraji Lieutenant General
(15758, 2, 100, 0), (15758, 3, 100, 0), (15758, 4, 100, 0), (15758, 5, 100, 0),
(15758, 6, 100, 0), -- Supreme Anubisath Warbringer
(15759, 2, 100, 0), (15759, 3, 100, 0), (15759, 4, 100, 0), (15759, 5, 100, 0),
(15759, 6, 100, 0), -- Supreme Silithid Flayer
(15817, 2, 100, 0), (15817, 3, 100, 0), (15817, 4, 100, 0), (15817, 5, 100, 0),
(15817, 6, 100, 0), -- Qiraji Brigadier General Pax-lish
(15818, 2, 250, 0), (15818, 3, 250, 0), (15818, 4, 250, 0), (15818, 5, 250, 0),
(15818, 6, 250, 0), -- Lieutenant General Nokhor
(15857, 2, 5, 0), (15857, 3, 5, 0), (15857, 4, 5, 0), (15857, 5, 5, 0), (15857, 6, 5, 0), -- Stormwind Cavalryman
(15859, 2, 10, 0), (15859, 3, 10, 0), (15859, 4, 10, 0), (15859, 5, 10, 0), (15859, 6, 10, 0), -- Stormwind Archmage
(15862, 2, 5, 0), (15862, 3, 5, 0), (15862, 4, 5, 0), (15862, 5, 5, 0), (15862, 6, 5, 0), -- Ironforge Cavalryman
(15866, 2, 15, 0), (15866, 3, 15, 0), (15866, 4, 15, 0), (15866, 5, 15, 0),
(15866, 6, 15, 0), -- High Commander Lynore Windstryke
(15868, 2, 15, 0), (15868, 3, 15, 0), (15868, 4, 15, 0), (15868, 5, 15, 0),
(15868, 6, 15, 0), -- Highlord Leoric Von Zeldig
(15870, 2, 15, 0), (15870, 3, 15, 0), (15870, 4, 15, 0), (15870, 5, 15, 0),
(15870, 6, 15, 0), -- Duke August Foehammer
(15963, 2, 5, 0), (15963, 3, 5, 0), (15963, 4, 5, 0), (15963, 5, 5, 0), (15963, 6, 5, 0), -- The Masters Eye
(16042, 2, 15, 0), (16042, 3, 15, 0), (16042, 4, 15, 0), (16042, 5, 15, 0), (16042, 6, 15, 0), -- Lord Valthalak
(16043, 3, 15, 0), -- Magma Lord Bokk
(16073, 2, 15, 0), (16073, 3, 15, 0), (16073, 4, 15, 0), (16073, 5, 15, 0),
(16073, 6, 15, 0), -- Spirit of Lord Valthalak
(16387, 2, 5, 0), (16387, 3, 5, 0), (16387, 4, 5, 0), (16387, 5, 5, 0), (16387, 6, 5, 0), -- Atiesh
(16776, 2, 15, 0), (16776, 3, 15, 0), (16776, 4, 15, 0), (16776, 5, 15, 0), (16776, 6, 15, 0), -- Spirit of Blaumeux
(16777, 2, 15, 0), (16777, 3, 15, 0), (16777, 4, 15, 0), (16777, 5, 15, 0), (16777, 6, 15, 0), -- Spirit of Zeliek
(16778, 2, 15, 0), (16778, 3, 15, 0), (16778, 4, 15, 0), (16778, 5, 15, 0), (16778, 6, 15, 0); -- Spirit of Korthazz

-- Resistances that differ from vanilla.
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 329 AND `School` = 3; -- was 260
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 2887 AND `School` = 3; -- was 41
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 5890 AND `School` = 3; -- was 1
UPDATE `creature_template_resistance` SET `Resistance` = 54 WHERE `CreatureID` = 6498 AND `School` = 2; -- was 200
UPDATE `creature_template_resistance` SET `Resistance` = 19 WHERE `CreatureID` = 6748 AND `School` = 2; -- was 60
UPDATE `creature_template_resistance` SET `Resistance` = 38 WHERE `CreatureID` = 6748 AND `School` = 3; -- was 50
UPDATE `creature_template_resistance` SET `Resistance` = 38 WHERE `CreatureID` = 6748 AND `School` = 5; -- was 10
UPDATE `creature_template_resistance` SET `Resistance` = 19 WHERE `CreatureID` = 6748 AND `School` = 6; -- was 10
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 7031 AND `School` = 3; -- was 190
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 7032 AND `School` = 3; -- was 112
UPDATE `creature_template_resistance` SET `Resistance` = -140 WHERE `CreatureID` = 8908 AND `School` = 4; -- was 140
UPDATE `creature_template_resistance` SET `Resistance` = 30 WHERE `CreatureID` = 8923 AND `School` = 5; -- was 153
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 9025 AND `School` = 2; -- was 510
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 9025 AND `School` = 3; -- was 510
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 9025 AND `School` = 4; -- was 510
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 9025 AND `School` = 5; -- was 510
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 9025 AND `School` = 6; -- was 510
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 9396 AND `School` = 3; -- was 125
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 11669 AND `School` = 3; -- was 122
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 11669 AND `School` = 4; -- was 122
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 11669 AND `School` = 5; -- was 122
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 11669 AND `School` = 6; -- was 122
UPDATE `creature_template_resistance` SET `Resistance` = 200 WHERE `CreatureID` = 12018 AND `School` = 2; -- was 95
UPDATE `creature_template_resistance` SET `Resistance` = 200 WHERE `CreatureID` = 12098 AND `School` = 2; -- was 93
UPDATE `creature_template_resistance` SET `Resistance` = 45 WHERE `CreatureID` = 13456 AND `School` = 3; -- was 144
UPDATE `creature_template_resistance` SET `Resistance` = 92 WHERE `CreatureID` = 13696 AND `School` = 3; -- was 144
UPDATE `creature_template_resistance` SET `Resistance` = 46 WHERE `CreatureID` = 13736 AND `School` = 3; -- was 144
UPDATE `creature_template_resistance` SET `Resistance` = 300 WHERE `CreatureID` = 14022 AND `School` = 2; -- was 180
UPDATE `creature_template_resistance` SET `Resistance` = 400 WHERE `CreatureID` = 14261 AND `School` = 4; -- was 200
UPDATE `creature_template_resistance` SET `Resistance` = 100 WHERE `CreatureID` = 14261 AND `School` = 6; -- was 200
UPDATE `creature_template_resistance` SET `Resistance` = 400 WHERE `CreatureID` = 14262 AND `School` = 3; -- was 500
UPDATE `creature_template_resistance` SET `Resistance` = 400 WHERE `CreatureID` = 14264 AND `School` = 2; -- was 500
UPDATE `creature_template_resistance` SET `Resistance` = 400 WHERE `CreatureID` = 14265 AND `School` = 2; -- was 200
UPDATE `creature_template_resistance` SET `Resistance` = 400 WHERE `CreatureID` = 14265 AND `School` = 5; -- was 200
UPDATE `creature_template_resistance` SET `Resistance` = 250 WHERE `CreatureID` = 14302 AND `School` = 2; -- was 200
UPDATE `creature_template_resistance` SET `Resistance` = 250 WHERE `CreatureID` = 14302 AND `School` = 3; -- was 200
UPDATE `creature_template_resistance` SET `Resistance` = 250 WHERE `CreatureID` = 14302 AND `School` = 4; -- was 200
UPDATE `creature_template_resistance` SET `Resistance` = 250 WHERE `CreatureID` = 14302 AND `School` = 5; -- was 200
UPDATE `creature_template_resistance` SET `Resistance` = 250 WHERE `CreatureID` = 14302 AND `School` = 6; -- was 200
UPDATE `creature_template_resistance` SET `Resistance` = 15 WHERE `CreatureID` = 14464 AND `School` = 3; -- was 58
UPDATE `creature_template_resistance` SET `Resistance` = 10 WHERE `CreatureID` = 14502 AND `School` = 2; -- was 75
UPDATE `creature_template_resistance` SET `Resistance` = 10 WHERE `CreatureID` = 14502 AND `School` = 3; -- was 75
UPDATE `creature_template_resistance` SET `Resistance` = 10 WHERE `CreatureID` = 14502 AND `School` = 4; -- was 75
UPDATE `creature_template_resistance` SET `Resistance` = 10 WHERE `CreatureID` = 14502 AND `School` = 5; -- was 75
UPDATE `creature_template_resistance` SET `Resistance` = 115 WHERE `CreatureID` = 15391 AND `School` = 6; -- was 155

-- Resistances the vanilla creature does not have (vmangos and Turtle WoW both 0, no school immunity).
DELETE FROM `creature_template_resistance` WHERE (`CreatureID`, `School`) IN (
(157, 5), (157, 6), -- Goretusk: shadow 40 arcane 10
(1800, 4), -- Cold Wraith: frost 165
(3272, 2), (3272, 5), -- Kolkar Wrangler: fire 70 shadow 30
(3568, 2), (3568, 3), (3568, 4), (3568, 5), (3568, 6), -- Mist: fire 150 nature 150 frost 150 shadow 150 arcane 150
(5288, 3), -- Rabid Longtooth: nature 1
(5400, 5), -- Zekkis: shadow 120
(6492, 6), -- Rift Spawn: arcane 17
(6498, 3), (6498, 4), (6498, 5), (6498, 6), -- Devilsaur: nature 200 frost 200 shadow 200 arcane 200
-- Ironhide Devilsaur: fire 200 nature 200 frost 200 shadow 200 arcane 200
(6499, 2), (6499, 3), (6499, 4), (6499, 5), (6499, 6),
-- Tyrant Devilsaur: fire 200 nature 200 frost 200 shadow 200 arcane 200
(6500, 2), (6500, 3), (6500, 4), (6500, 5), (6500, 6),
(7132, 4), -- Toxic Horror: frost 54
(7664, 2), (7664, 5), -- Razelikh the Defiler: fire 50 shadow 50
(8438, 4), -- Hakkari Bloodkeeper: frost 125
(8440, 4), -- Shade of Hakkar: frost 125
(8668, 2), (8668, 3), (8668, 4), (8668, 5), -- Felhound Tracker: fire 75 nature 75 frost 75 shadow 75
(8923, 2), (8923, 3), (8923, 4), (8923, 6), -- Panzor the Invincible: fire 153 nature 153 frost 153 arcane 153
(9031, 5), -- Anubshiah: shadow 162
(10699, 5), -- Carrion Scarab: shadow 84
(10876, 5), -- Undead Scarab: shadow 84
-- Postmaster Malown: fire 180 nature 180 frost 180 shadow 180 arcane 180
(11143, 2), (11143, 3), (11143, 4), (11143, 5), (11143, 6),
(11480, 2), (11480, 3), (11480, 4), (11480, 5), -- Arcane Aberration: fire 60 nature 120 frost 120 shadow 60
(11483, 2), (11483, 3), (11483, 4), (11483, 5), -- Mana Remnant: fire 290 nature 290 frost 290 shadow 290
(12976, 2), (12976, 5), -- Kolkar Waylayer: fire 70 shadow 30
(12977, 2), (12977, 5), -- Kolkar Ambusher: fire 70 shadow 30
(13696, 4), -- Noxxious Scion: frost 144
(14399, 3), -- Arcane Torrent: nature 120
(14400, 3), -- Arcane Feedback: nature 60
(14535, 6)); -- Artorius the Doombringer: arcane 240

-- Warrior and druid threat of the 1.12 spell ranks (vmangos spell_threat, same columns).
UPDATE `spell_threat` SET `flatMod` = 20, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 78; -- Heroic Strike Rank 1
UPDATE `spell_threat` SET `flatMod` = 39, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 284; -- Heroic Strike Rank 2
UPDATE `spell_threat` SET `flatMod` = 59, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 285; -- Heroic Strike Rank 3
UPDATE `spell_threat` SET `flatMod` = 0, `pctMod` = 1.75, `apPctMod` = 0 WHERE `entry` = 779; -- Swipe (Bear) Rank 1
UPDATE `spell_threat` SET `flatMod` = 10, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 845; -- Cleave Rank 1
UPDATE `spell_threat` SET `flatMod` = 78, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 1608; -- Heroic Strike Rank 4
UPDATE `spell_threat` SET `flatMod` = 42, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 5211; -- Bash Rank 1
UPDATE `spell_threat` SET `flatMod` = 0, `pctMod` = 2.5, `apPctMod` = 0 WHERE `entry` = 6343; -- Thunder Clap Rank 1
UPDATE `spell_threat` SET `flatMod` = 63, `pctMod` = 2.25, `apPctMod` = 0 WHERE `entry` = 6572; -- Revenge Rank 1
UPDATE `spell_threat` SET `flatMod` = 108, `pctMod` = 2.25, `apPctMod` = 0 WHERE `entry` = 6574; -- Revenge Rank 2
UPDATE `spell_threat` SET `flatMod` = 90, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 6798; -- Bash Rank 2
UPDATE `spell_threat` SET `flatMod` = 0, `pctMod` = 1.75, `apPctMod` = 0 WHERE `entry` = 6807; -- Maul Rank 1
UPDATE `spell_threat` SET `flatMod` = 0, `pctMod` = 1.75, `apPctMod` = 0 WHERE `entry` = 6808; -- Maul Rank 2
UPDATE `spell_threat` SET `flatMod` = 0, `pctMod` = 1.75, `apPctMod` = 0 WHERE `entry` = 6809; -- Maul Rank 3
UPDATE `spell_threat` SET `flatMod` = 40, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 7369; -- Cleave Rank 2
UPDATE `spell_threat` SET `flatMod` = 153, `pctMod` = 2.25, `apPctMod` = 0 WHERE `entry` = 7379; -- Revenge Rank 3
UPDATE `spell_threat` SET `flatMod` = 0, `pctMod` = 1.75, `apPctMod` = 0 WHERE `entry` = 8972; -- Maul Rank 4
UPDATE `spell_threat` SET `flatMod` = 138, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 8983; -- Bash Rank 3
UPDATE `spell_threat` SET `flatMod` = 0, `pctMod` = 1.75, `apPctMod` = 0 WHERE `entry` = 9745; -- Maul Rank 5
UPDATE `spell_threat` SET `flatMod` = 0, `pctMod` = 1.75, `apPctMod` = 0 WHERE `entry` = 9880; -- Maul Rank 6
UPDATE `spell_threat` SET `flatMod` = 0, `pctMod` = 1.75, `apPctMod` = 0 WHERE `entry` = 9881; -- Maul Rank 7
UPDATE `spell_threat` SET `flatMod` = 98, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 11564; -- Heroic Strike Rank 5
UPDATE `spell_threat` SET `flatMod` = 118, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 11565; -- Heroic Strike Rank 6
UPDATE `spell_threat` SET `flatMod` = 137, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 11566; -- Heroic Strike Rank 7
UPDATE `spell_threat` SET `flatMod` = 145, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 11567; -- Heroic Strike Rank 8
UPDATE `spell_threat` SET `flatMod` = 198, `pctMod` = 2.25, `apPctMod` = 0 WHERE `entry` = 11600; -- Revenge Rank 4
UPDATE `spell_threat` SET `flatMod` = 243, `pctMod` = 2.25, `apPctMod` = 0 WHERE `entry` = 11601; -- Revenge Rank 5
UPDATE `spell_threat` SET `flatMod` = 60, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 11608; -- Cleave Rank 3
UPDATE `spell_threat` SET `flatMod` = 70, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 11609; -- Cleave Rank 4
UPDATE `spell_threat` SET `flatMod` = 40, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 19675; -- Feral Charge Effect
UPDATE `spell_threat` SET `flatMod` = 100, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 20569; -- Cleave Rank 5
UPDATE `spell_threat` SET `flatMod` = 178, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 23922; -- Shield Slam Rank 1
UPDATE `spell_threat` SET `flatMod` = 203, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 23923; -- Shield Slam Rank 2
UPDATE `spell_threat` SET `flatMod` = 229, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 23924; -- Shield Slam Rank 3
UPDATE `spell_threat` SET `flatMod` = 254, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 23925; -- Shield Slam Rank 4
UPDATE `spell_threat` SET `flatMod` = 175, `pctMod` = 1, `apPctMod` = 0 WHERE `entry` = 25286; -- Heroic Strike Rank 9
UPDATE `spell_threat` SET `flatMod` = 270, `pctMod` = 2.25, `apPctMod` = 0 WHERE `entry` = 25288; -- Revenge Rank 6

-- Higher ranks that vmangos gives their rank-1 multiplier. The TBC/WotLK ranks keep the stock rank-1
-- multiplier through explicit rows, because a rank without a row inherits the (now vanilla) rank-1 row.
DELETE FROM `spell_threat` WHERE `entry` IN (769, 780, 8198, 8204, 8205, 9754, 9908, 11580, 11581, 25264, 26997,
47501, 47502, 48561, 48562);
INSERT INTO `spell_threat` (`entry`, `flatMod`, `pctMod`, `apPctMod`) VALUES
(769, 0, 1.75, 0), -- Swipe (Bear) Rank 3
(780, 0, 1.75, 0), -- Swipe (Bear) Rank 2
(8198, 0, 2.5, 0), -- Thunder Clap Rank 2
(8204, 0, 2.5, 0), -- Thunder Clap Rank 3
(8205, 0, 2.5, 0), -- Thunder Clap Rank 4
(9754, 0, 1.75, 0), -- Swipe (Bear) Rank 4
(9908, 0, 1.75, 0), -- Swipe (Bear) Rank 5
(11580, 0, 2.5, 0), -- Thunder Clap Rank 5
(11581, 0, 2.5, 0), -- Thunder Clap Rank 6
(25264, 0, 1.85, 0), -- Thunder Clap Rank 7
(26997, 0, 1.5, 0), -- Swipe (Bear) Rank 6
(47501, 0, 1.85, 0), -- Thunder Clap Rank 8
(47502, 0, 1.85, 0), -- Thunder Clap Rank 9
(48561, 0, 1.5, 0), -- Swipe (Bear) Rank 7
(48562, 0, 1.5, 0); -- Swipe (Bear) Rank 8
