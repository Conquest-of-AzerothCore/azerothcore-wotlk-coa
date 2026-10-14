-- The Snow Piles the user placed around Snowveil Cemetery are the ones "The Dignity of the Dead" has players clear (6 Snow
-- Piles and 6 Weeds): they were set with the stock Dun Morogh pile and then made scenery. They become the quest's own
-- Snow Pile, and the quest's second version (the other giver's) gets its own pile on the same spots.
UPDATE `gameobject` SET `id` = 2300711 WHERE `guid` IN (9963072, 9963073, 9963074, 9963075, 9963076, 9963077, 9963079, 9963080, 9963081, 9963082, 9963083, 9963084, 9963086) AND `id` = 2300800;
DELETE FROM `gameobject` WHERE `guid` BETWEEN 9963400 AND 9963412;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9963400, 2300713, 0, 0, 0, 1, 1, -6360.22, -465.081, 649.969, 3.81752, 0, 0, 0.943432, -0.331566, 300, 0, 1, 'Snow Pile for the second Dignity of the Dead (on 9963072)'),
(9963401, 2300713, 0, 0, 0, 1, 1, -6358.95, -460.529, 649.939, 1.66945, 0, 0, 0.741113, 0.67138, 300, 0, 1, 'Snow Pile for the second Dignity of the Dead (on 9963073)'),
(9963402, 2300713, 0, 0, 0, 1, 1, -6363.03, -462.831, 650.05, 4.74036, 0, 0, 0.697149, -0.716926, 300, 0, 1, 'Snow Pile for the second Dignity of the Dead (on 9963074)'),
(9963403, 2300713, 0, 0, 0, 1, 1, -6356.47, -454.822, 650.093, 6.16664, 0, 0, 0.05824, -0.998303, 300, 0, 1, 'Snow Pile for the second Dignity of the Dead (on 9963075)'),
(9963404, 2300713, 0, 0, 0, 1, 1, -6361.22, -451.022, 650.234, 6.19727, 0, 0, 0.0429452, -0.999077, 300, 0, 1, 'Snow Pile for the second Dignity of the Dead (on 9963076)'),
(9963405, 2300713, 0, 0, 0, 1, 1, -6352.74, -440.704, 649.758, 3.20883, 0, 0, 0.999435, -0.0336116, 300, 0, 1, 'Snow Pile for the second Dignity of the Dead (on 9963077)'),
(9963406, 2300713, 0, 0, 0, 1, 1, -6340.54, -440.805, 649.821, 4.40971, 0, 0, 0.805631, -0.592417, 300, 0, 1, 'Snow Pile for the second Dignity of the Dead (on 9963079)'),
(9963407, 2300713, 0, 0, 0, 1, 1, -6340.87, -452.324, 649.699, 4.29897, 0, 0, 0.837181, -0.546926, 300, 0, 1, 'Snow Pile for the second Dignity of the Dead (on 9963080)'),
(9963408, 2300713, 0, 0, 0, 1, 1, -6338.25, -446.347, 649.912, 4.29897, 0, 0, 0.837181, -0.546926, 300, 0, 1, 'Snow Pile for the second Dignity of the Dead (on 9963081)'),
(9963409, 2300713, 0, 0, 0, 1, 1, -6338.97, -454.879, 649.789, 3.42482, 0, 0, 0.98999, -0.141139, 300, 0, 1, 'Snow Pile for the second Dignity of the Dead (on 9963082)'),
(9963410, 2300713, 0, 0, 0, 1, 1, -6339.34, -461.551, 649.709, 4.65867, 0, 0, 0.725842, -0.687862, 300, 0, 1, 'Snow Pile for the second Dignity of the Dead (on 9963083)'),
(9963411, 2300713, 0, 0, 0, 1, 1, -6332.9, -464.256, 649.673, 5.90981, 0, 0, 0.185605, -0.982624, 300, 0, 1, 'Snow Pile for the second Dignity of the Dead (on 9963084)'),
(9963412, 2300713, 0, 0, 0, 1, 1, -6333.86, -440.723, 649.584, 5.45035, 0, 0, 0.404486, -0.914544, 300, 0, 1, 'Snow Pile for the second Dignity of the Dead (on 9963086)');
