-- Archmage Arugal (4275) resets when his target leaves his lair polygon. Its south, west and east edges ran along the
-- walkable ledge, which reaches up to 1.25 yards past them, so players fighting him at his Shadow Port spot on the
-- ledge reset him. Those three edges move 3.25 yards outward (the measured overhang and the 2-yard room padding of
-- the leash code); the north edges keep their lines.
DELETE FROM `coa_boss_leash_point` WHERE `entry` = 4275;
INSERT INTO `coa_boss_leash_point` (`entry`, `point`, `x`, `y`, `z`) VALUES
(4275, 0, -130.791, 2129.167, 155.677),
(4275, 1, -81.981, 2109.946, 155.677),
(4275, 2, -65.913, 2151.718, 155.68),
(4275, 3, -69.13, 2157.94, 155.68),
(4275, 4, -112.697, 2175.101, 155.265);
