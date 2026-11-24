-- Charlga Razorflank (4421), #12656: her Heroic and Mythic leash reaches out of the room's north-west exit into the cave, where groups tank her at the
-- vines: the area takes in about 15 yards past the exit (2172.0 1913.8).
DELETE FROM `coa_boss_leash_point` WHERE `entry` = 4421;
INSERT INTO `coa_boss_leash_point` (`entry`, `point`, `x`, `y`, `z`) VALUES
(4421, 0, 2167.79, 1911.97, 70.751),
(4421, 1, 2169.84, 1880.78, 73.537),
(4421, 2, 2185.55, 1858.43, 80.549),
(4421, 3, 2200.1, 1855.19, 78.226),
(4421, 4, 2214.51, 1873.47, 74.883),
(4421, 5, 2220.86, 1892.36, 73.89),
(4421, 6, 2209.43, 1912.1, 72.389),
(4421, 7, 2170.6, 1918.67, 69.558),
(4421, 8, 2168.19, 1929.88, 69.6),
(4421, 9, 2157.27, 1921.2, 69.6);
