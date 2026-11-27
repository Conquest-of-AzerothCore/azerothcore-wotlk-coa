-- Archmage Arugal (4275) resets when his target leaves his lair polygon. Its north and north-east edges still ran
-- along the walkable north ledge and the floor below it, which reach up to 0.45 yards past them, so players running
-- along the north wall to reach him after a Shadow Port reset him. Those two edges move 3.25 yards outward, like the
-- south, west and east edges did; the west edge along the door wall keeps its line.
DELETE FROM `coa_boss_leash_point` WHERE `entry` = 4275;
INSERT INTO `coa_boss_leash_point` (`entry`, `point`, `x`, `y`, `z`) VALUES
(4275, 0, -130.791, 2129.167, 155.677),
(4275, 1, -81.981, 2109.946, 155.677),
(4275, 2, -64.352, 2155.776, 155.68),
(4275, 3, -66.804, 2160.517, 155.68),
(4275, 4, -111.506, 2178.125, 155.265);
