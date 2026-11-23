-- Roderic Dolvarn (164186, spawn 9920770) cut diagonally across the pews of the Graysky Chapel of Light to a spot
-- behind the altar and back past Alina Mouren. He now climbs the steps straight through the door, walks up the centre
-- aisle, stops 4 yd short of Chaplain Conther facing the altar, and leaves the same way. Every leg keeps 2.25 yd from
-- pews, furniture, walls and NPCs. Smooth transitions send the points as one spline, so pathfinding cannot route him
-- over the pews between them.
DELETE FROM `waypoint_data` WHERE `id` = 9921004;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`,
    `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(9921004, 1, -7216.78, 1152.79, 309.167, NULL, 0, 0, 1, 0, 0, 100, 0),
(9921004, 2, -7217.49, 1178.02, 309.287, NULL, 0, 0, 1, 0, 0, 100, 0),
(9921004, 3, -7195.5, 1190.2, 309.358, NULL, 0, 0, 1, 0, 0, 100, 0),
(9921004, 4, -7186.69, 1193.4, 311.094, NULL, 0, 0, 1, 0, 0, 100, 0),
(9921004, 5, -7177, 1197.6, 311.084, NULL, 0, 0, 1, 0, 0, 100, 0),
(9921004, 6, -7154.9, 1205.15, 311.084, 0.33, 0, 10000, 1, 0, 0, 100, 0),
(9921004, 7, -7177, 1197.6, 311.084, NULL, 0, 0, 1, 0, 0, 100, 0),
(9921004, 8, -7186.69, 1193.4, 311.094, NULL, 0, 0, 1, 0, 0, 100, 0),
(9921004, 9, -7195.5, 1190.2, 309.358, NULL, 0, 0, 1, 0, 0, 100, 0),
(9921004, 10, -7227.17, 1178.22, 309.286, NULL, 0, 0, 1, 0, 0, 100, 0);
