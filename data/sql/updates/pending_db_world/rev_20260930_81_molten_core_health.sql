-- Molten Core creature health on all four difficulties.
-- Normal: the absolute health CoA gave each creature (db.exil.es export, exiles-db-export-2026-09-13),
-- expressed as a HealthModifier over this core's base health curve at the same level and class,
-- so the product lands on the recorded value. Heroic, Mythic and Ascended: CoA's client creature
-- caches carry HealthModifier x1.44, x1.88 and x2.32 of Normal for every Molten Core variant
-- recorded (Baron Geddon on all three, Golemagg, Majordomo, Shazzrah and two Flamewakers on
-- Ascended); Ragnaros (3) is the one exception, recorded at x3.835. Bosses with a coa_boss_flex
-- row still take their fight health from it on the pull.
UPDATE `creature_template` SET `HealthModifier` = 547.556 WHERE `entry` = 11502; -- Ragnaros: 1,823,910 health
UPDATE `creature_template` SET `HealthModifier` = 65.9994 WHERE `entry` = 11658; -- Molten Giant: 213,640 health
UPDATE `creature_template` SET `HealthModifier` = 74.6668 WHERE `entry` = 11659; -- Molten Destroyer: 248,715 health
UPDATE `creature_template` SET `HealthModifier` = 49.5058 WHERE `entry` = 11661; -- Flamewaker: 128,220 health
UPDATE `creature_template` SET `HealthModifier` = 49.5013 WHERE `entry` = 11662; -- Flamewaker Priest: 112,170 health
UPDATE `creature_template` SET `HealthModifier` = 65.258 WHERE `entry` = 11663; -- Flamewaker Healer: 159,360 health
UPDATE `creature_template` SET `HealthModifier` = 66.0077 WHERE `entry` = 11664; -- Flamewaker Elite: 170,960 health
UPDATE `creature_template` SET `HealthModifier` = 49.4995 WHERE `entry` = 11665; -- Lava Annihilator: 160,230 health
UPDATE `creature_template` SET `HealthModifier` = 41.2496 WHERE `entry` = 11666; -- Firewalker: 133,525 health
UPDATE `creature_template` SET `HealthModifier` = 41.2496 WHERE `entry` = 11667; -- Flameguard: 133,525 health
UPDATE `creature_template` SET `HealthModifier` = 49.4995 WHERE `entry` = 11668; -- Firelord: 160,230 health
UPDATE `creature_template` SET `HealthModifier` = 4.95 WHERE `entry` = 11669; -- Flame Imp: 16,023 health
UPDATE `creature_template` SET `HealthModifier` = 24.6088 WHERE `entry` = 11671; -- Core Hound: 77,370 health
UPDATE `creature_template` SET `HealthModifier` = 41.2496 WHERE `entry` = 11672; -- Core Rager: 133,525 health
UPDATE `creature_template` SET `HealthModifier` = 57.7495 WHERE `entry` = 11673; -- Ancient Core Hound: 186,935 health
UPDATE `creature_template` SET `HealthModifier` = 411.497 WHERE `entry` = 11982; -- Magmadar: 1,370,696 health
UPDATE `creature_template` SET `HealthModifier` = 411.497 WHERE `entry` = 11988; -- Golemagg the Incinerator: 1,370,696 health
UPDATE `creature_template` SET `HealthModifier` = 331.852 WHERE `entry` = 12018; -- Majordomo Executus: 1,105,400 health
UPDATE `creature_template` SET `HealthModifier` = 292.03 WHERE `entry` = 12056; -- Baron Geddon: 972,752 health
UPDATE `creature_template` SET `HealthModifier` = 328.534 WHERE `entry` = 12057; -- Garr: 1,094,346 health
UPDATE `creature_template` SET `HealthModifier` = 41.2496 WHERE `entry` = 12076; -- Lava Elemental: 133,525 health
UPDATE `creature_template` SET `HealthModifier` = 219.023 WHERE `entry` = 12098; -- Sulfuron Harbinger: 729,564 health
UPDATE `creature_template` SET `HealthModifier` = 32.6278 WHERE `entry` = 12099; -- Firesworn: 99,580 health
UPDATE `creature_template` SET `HealthModifier` = 41.4815 WHERE `entry` = 12100; -- Lava Reaver: 138,175 health
UPDATE `creature_template` SET `HealthModifier` = 49.4995 WHERE `entry` = 12101; -- Lava Surger: 160,230 health
UPDATE `creature_template` SET `HealthModifier` = 219.026 WHERE `entry` = 12118; -- Lucifron: 583,704 health
UPDATE `creature_template` SET `HealthModifier` = 57.7568 WHERE `entry` = 12119; -- Flamewaker Protector: 149,590 health
UPDATE `creature_template` SET `HealthModifier` = 8.1569 WHERE `entry` = 12143; -- Son of Flame: 24,895 health
UPDATE `creature_template` SET `HealthModifier` = 219.026 WHERE `entry` = 12259; -- Gehennas: 583,704 health
UPDATE `creature_template` SET `HealthModifier` = 219.026 WHERE `entry` = 12264; -- Shazzrah: 583,704 health
UPDATE `creature_template` SET `HealthModifier` = 1.6314 WHERE `entry` = 13148; -- Flame of Ragnaros: 4,979 health
UPDATE `creature_template` SET `HealthModifier` = 788.481 WHERE `entry` = 111502; -- Ragnaros (1): 2,626,431 health
UPDATE `creature_template` SET `HealthModifier` = 95.0391 WHERE `entry` = 111658; -- Molten Giant (1): 307,642 health
UPDATE `creature_template` SET `HealthModifier` = 107.52 WHERE `entry` = 111659; -- Molten Destroyer (1): 358,149 health
UPDATE `creature_template` SET `HealthModifier` = 71.2883 WHERE `entry` = 111661; -- Flamewaker (1): 184,637 health
UPDATE `creature_template` SET `HealthModifier` = 71.2819 WHERE `entry` = 111662; -- Flamewaker Priest (1): 161,525 health
UPDATE `creature_template` SET `HealthModifier` = 93.9715 WHERE `entry` = 111663; -- Flamewaker Healer (1): 229,478 health
UPDATE `creature_template` SET `HealthModifier` = 95.0511 WHERE `entry` = 111664; -- Flamewaker Elite (1): 246,182 health
UPDATE `creature_template` SET `HealthModifier` = 71.2793 WHERE `entry` = 111665; -- Lava Annihilator (1): 230,731 health
UPDATE `creature_template` SET `HealthModifier` = 59.3994 WHERE `entry` = 111666; -- Firewalker (1): 192,276 health
UPDATE `creature_template` SET `HealthModifier` = 59.3994 WHERE `entry` = 111667; -- Flameguard (1): 192,276 health
UPDATE `creature_template` SET `HealthModifier` = 71.2793 WHERE `entry` = 111668; -- Firelord (1): 230,731 health
UPDATE `creature_template` SET `HealthModifier` = 7.1279 WHERE `entry` = 111669; -- Flame Imp (1): 23,073 health
UPDATE `creature_template` SET `HealthModifier` = 35.4366 WHERE `entry` = 111671; -- Core Hound (1): 111,413 health
UPDATE `creature_template` SET `HealthModifier` = 59.3994 WHERE `entry` = 111672; -- Core Rager (1): 192,276 health
UPDATE `creature_template` SET `HealthModifier` = 83.1592 WHERE `entry` = 111673; -- Ancient Core Hound (1): 269,186 health
UPDATE `creature_template` SET `HealthModifier` = 592.556 WHERE `entry` = 111982; -- Magmadar (1): 1,973,802 health
UPDATE `creature_template` SET `HealthModifier` = 592.556 WHERE `entry` = 111988; -- Golemagg the Incinerator (1): 1,973,802 health
UPDATE `creature_template` SET `HealthModifier` = 477.867 WHERE `entry` = 112018; -- Majordomo Executus (1): 1,591,776 health
UPDATE `creature_template` SET `HealthModifier` = 420.523 WHERE `entry` = 112056; -- Baron Geddon (1): 1,400,763 health
UPDATE `creature_template` SET `HealthModifier` = 473.089 WHERE `entry` = 112057; -- Garr (1): 1,575,858 health
UPDATE `creature_template` SET `HealthModifier` = 59.3994 WHERE `entry` = 112076; -- Lava Elemental (1): 192,276 health
UPDATE `creature_template` SET `HealthModifier` = 315.392 WHERE `entry` = 112098; -- Sulfuron Harbinger (1): 1,050,572 health
UPDATE `creature_template` SET `HealthModifier` = 46.984 WHERE `entry` = 112099; -- Firesworn (1): 143,395 health
UPDATE `creature_template` SET `HealthModifier` = 59.7334 WHERE `entry` = 112100; -- Lava Reaver (1): 198,972 health
UPDATE `creature_template` SET `HealthModifier` = 71.2793 WHERE `entry` = 112101; -- Lava Surger (1): 230,731 health
UPDATE `creature_template` SET `HealthModifier` = 315.397 WHERE `entry` = 112118; -- Lucifron (1): 840,534 health
UPDATE `creature_template` SET `HealthModifier` = 83.1697 WHERE `entry` = 112119; -- Flamewaker Protector (1): 215,410 health
UPDATE `creature_template` SET `HealthModifier` = 11.746 WHERE `entry` = 112143; -- Son of Flame (1): 35,849 health
UPDATE `creature_template` SET `HealthModifier` = 315.397 WHERE `entry` = 112259; -- Gehennas (1): 840,534 health
UPDATE `creature_template` SET `HealthModifier` = 315.397 WHERE `entry` = 112264; -- Shazzrah (1): 840,534 health
UPDATE `creature_template` SET `HealthModifier` = 1029.41 WHERE `entry` = 211502; -- Ragnaros (2): 3,428,951 health
UPDATE `creature_template` SET `HealthModifier` = 124.079 WHERE `entry` = 211658; -- Molten Giant (2): 401,643 health
UPDATE `creature_template` SET `HealthModifier` = 140.374 WHERE `entry` = 211659; -- Molten Destroyer (2): 467,584 health
UPDATE `creature_template` SET `HealthModifier` = 93.0709 WHERE `entry` = 211661; -- Flamewaker (2): 241,054 health
UPDATE `creature_template` SET `HealthModifier` = 93.0625 WHERE `entry` = 211662; -- Flamewaker Priest (2): 210,880 health
UPDATE `creature_template` SET `HealthModifier` = 122.685 WHERE `entry` = 211663; -- Flamewaker Healer (2): 299,597 health
UPDATE `creature_template` SET `HealthModifier` = 124.094 WHERE `entry` = 211664; -- Flamewaker Elite (2): 321,405 health
UPDATE `creature_template` SET `HealthModifier` = 93.0591 WHERE `entry` = 211665; -- Lava Annihilator (2): 301,232 health
UPDATE `creature_template` SET `HealthModifier` = 77.5493 WHERE `entry` = 211666; -- Firewalker (2): 251,027 health
UPDATE `creature_template` SET `HealthModifier` = 77.5493 WHERE `entry` = 211667; -- Flameguard (2): 251,027 health
UPDATE `creature_template` SET `HealthModifier` = 93.0591 WHERE `entry` = 211668; -- Firelord (2): 301,232 health
UPDATE `creature_template` SET `HealthModifier` = 9.3059 WHERE `entry` = 211669; -- Flame Imp (2): 30,123 health
UPDATE `creature_template` SET `HealthModifier` = 46.2645 WHERE `entry` = 211671; -- Core Hound (2): 145,456 health
UPDATE `creature_template` SET `HealthModifier` = 77.5493 WHERE `entry` = 211672; -- Core Rager (2): 251,027 health
UPDATE `creature_template` SET `HealthModifier` = 108.569 WHERE `entry` = 211673; -- Ancient Core Hound (2): 351,438 health
UPDATE `creature_template` SET `HealthModifier` = 773.614 WHERE `entry` = 211982; -- Magmadar (2): 2,576,909 health
UPDATE `creature_template` SET `HealthModifier` = 773.614 WHERE `entry` = 211988; -- Golemagg the Incinerator (2): 2,576,909 health
UPDATE `creature_template` SET `HealthModifier` = 623.882 WHERE `entry` = 212018; -- Majordomo Executus (2): 2,078,152 health
UPDATE `creature_template` SET `HealthModifier` = 549.016 WHERE `entry` = 212056; -- Baron Geddon (2): 1,828,774 health
UPDATE `creature_template` SET `HealthModifier` = 617.644 WHERE `entry` = 212057; -- Garr (2): 2,057,370 health
UPDATE `creature_template` SET `HealthModifier` = 77.5493 WHERE `entry` = 212076; -- Lava Elemental (2): 251,027 health
UPDATE `creature_template` SET `HealthModifier` = 411.762 WHERE `entry` = 212098; -- Sulfuron Harbinger (2): 1,371,580 health
UPDATE `creature_template` SET `HealthModifier` = 61.3402 WHERE `entry` = 212099; -- Firesworn (2): 187,210 health
UPDATE `creature_template` SET `HealthModifier` = 77.9853 WHERE `entry` = 212100; -- Lava Reaver (2): 259,769 health
UPDATE `creature_template` SET `HealthModifier` = 93.0591 WHERE `entry` = 212101; -- Lava Surger (2): 301,232 health
UPDATE `creature_template` SET `HealthModifier` = 411.769 WHERE `entry` = 212118; -- Lucifron (2): 1,097,364 health
UPDATE `creature_template` SET `HealthModifier` = 108.583 WHERE `entry` = 212119; -- Flamewaker Protector (2): 281,229 health
UPDATE `creature_template` SET `HealthModifier` = 15.3351 WHERE `entry` = 212143; -- Son of Flame (2): 46,803 health
UPDATE `creature_template` SET `HealthModifier` = 411.769 WHERE `entry` = 212259; -- Gehennas (2): 1,097,364 health
UPDATE `creature_template` SET `HealthModifier` = 411.769 WHERE `entry` = 212264; -- Shazzrah (2): 1,097,364 health
UPDATE `creature_template` SET `HealthModifier` = 2099.99 WHERE `entry` = 311502; -- Ragnaros (3): 6,995,053 health
UPDATE `creature_template` SET `HealthModifier` = 153.119 WHERE `entry` = 311658; -- Molten Giant (3): 495,645 health
UPDATE `creature_template` SET `HealthModifier` = 173.227 WHERE `entry` = 311659; -- Molten Destroyer (3): 577,019 health
UPDATE `creature_template` SET `HealthModifier` = 114.853 WHERE `entry` = 311661; -- Flamewaker (3): 297,470 health
UPDATE `creature_template` SET `HealthModifier` = 114.843 WHERE `entry` = 311662; -- Flamewaker Priest (3): 260,234 health
UPDATE `creature_template` SET `HealthModifier` = 151.399 WHERE `entry` = 311663; -- Flamewaker Healer (3): 369,715 health
UPDATE `creature_template` SET `HealthModifier` = 153.138 WHERE `entry` = 311664; -- Flamewaker Elite (3): 396,627 health
UPDATE `creature_template` SET `HealthModifier` = 114.839 WHERE `entry` = 311665; -- Lava Annihilator (3): 371,734 health
UPDATE `creature_template` SET `HealthModifier` = 95.6991 WHERE `entry` = 311666; -- Firewalker (3): 309,778 health
UPDATE `creature_template` SET `HealthModifier` = 95.6991 WHERE `entry` = 311667; -- Flameguard (3): 309,778 health
UPDATE `creature_template` SET `HealthModifier` = 114.839 WHERE `entry` = 311668; -- Firelord (3): 371,734 health
UPDATE `creature_template` SET `HealthModifier` = 11.4839 WHERE `entry` = 311669; -- Flame Imp (3): 37,173 health
UPDATE `creature_template` SET `HealthModifier` = 57.0924 WHERE `entry` = 311671; -- Core Hound (3): 179,499 health
UPDATE `creature_template` SET `HealthModifier` = 95.6991 WHERE `entry` = 311672; -- Core Rager (3): 309,778 health
UPDATE `creature_template` SET `HealthModifier` = 133.979 WHERE `entry` = 311673; -- Ancient Core Hound (3): 433,689 health
UPDATE `creature_template` SET `HealthModifier` = 954.673 WHERE `entry` = 311982; -- Magmadar (3): 3,180,015 health
UPDATE `creature_template` SET `HealthModifier` = 954.673 WHERE `entry` = 311988; -- Golemagg the Incinerator (3): 3,180,015 health
UPDATE `creature_template` SET `HealthModifier` = 769.897 WHERE `entry` = 312018; -- Majordomo Executus (3): 2,564,528 health
UPDATE `creature_template` SET `HealthModifier` = 677.51 WHERE `entry` = 312056; -- Baron Geddon (3): 2,256,784 health
UPDATE `creature_template` SET `HealthModifier` = 762.198 WHERE `entry` = 312057; -- Garr (3): 2,538,883 health
UPDATE `creature_template` SET `HealthModifier` = 95.6991 WHERE `entry` = 312076; -- Lava Elemental (3): 309,778 health
UPDATE `creature_template` SET `HealthModifier` = 508.132 WHERE `entry` = 312098; -- Sulfuron Harbinger (3): 1,692,588 health
UPDATE `creature_template` SET `HealthModifier` = 75.6965 WHERE `entry` = 312099; -- Firesworn (3): 231,026 health
UPDATE `creature_template` SET `HealthModifier` = 96.2372 WHERE `entry` = 312100; -- Lava Reaver (3): 320,566 health
UPDATE `creature_template` SET `HealthModifier` = 114.839 WHERE `entry` = 312101; -- Lava Surger (3): 371,734 health
UPDATE `creature_template` SET `HealthModifier` = 508.14 WHERE `entry` = 312118; -- Lucifron (3): 1,354,193 health
UPDATE `creature_template` SET `HealthModifier` = 133.996 WHERE `entry` = 312119; -- Flamewaker Protector (3): 347,049 health
UPDATE `creature_template` SET `HealthModifier` = 18.9241 WHERE `entry` = 312143; -- Son of Flame (3): 57,756 health
UPDATE `creature_template` SET `HealthModifier` = 508.14 WHERE `entry` = 312259; -- Gehennas (3): 1,354,193 health
UPDATE `creature_template` SET `HealthModifier` = 508.14 WHERE `entry` = 312264; -- Shazzrah (3): 1,354,193 health
DELETE FROM `coa_boss_flex` WHERE `entry` IN (11982, 12018);
INSERT INTO `coa_boss_flex` (`entry`, `hp_d0`, `hp_d1`, `hp_d2`, `hp_d3`, `comment`) VALUES
(11982, 809645, 1079527, 1624782, 2369044, 'Magmadar: no log; CoA gives Magmadar and Golemagg the same health, so Golemagg''s row'),
(12018, 652940, 870586, 1310308, 1910519, 'Majordomo Executus: no log; Golemagg''s row x0.8065, the ratio of their recorded health');
