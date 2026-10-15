-- Starter-zone beasts are skinnable on Ascension CoA (all eight starting valleys)
UPDATE `creature_template` SET `skinloot` = 100001 WHERE `entry` IN
(69, 299, 704, 705, 708, 1504, 1505, 1508, 1509, 1512, 1688, 1984, 1985, 1986, 1994,
2031, 2032, 2955, 2961, 2966, 3124, 15274, 15366, 15372, 16520);
