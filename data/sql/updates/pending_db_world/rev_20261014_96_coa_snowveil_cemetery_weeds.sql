-- Weeds for "The Dignity of the Dead" (clear 6 Snow Piles and 6 Weeds at Snowveil Cemetery): 12 spots in a band
-- 1-10 yards outside the area the cemetery's snow piles cover, at the height of the ground they sit on; each spot
-- has the weed of both versions of the quest, as the snow piles do.
DELETE FROM `gameobject` WHERE `guid` BETWEEN 9963413 AND 9963436;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9963413, 2300710, 0, 0, 0, 1, 1, -6357.248, -467.655, 649.991, 4.8267, 0, 0, 0.665559, -0.746345, 300, 0, 1, 'Weed at Snowveil Cemetery (first Dignity of the Dead)'),
(9963414, 2300710, 0, 0, 0, 1, 1, -6347.728, -471.4, 649.858, 2.0781, 0, 0, 0.861923, 0.507039, 300, 0, 1, 'Weed at Snowveil Cemetery (first Dignity of the Dead)'),
(9963415, 2300710, 0, 0, 0, 1, 1, -6341.093, -470.817, 649.767, 5.0058, 0, 0, 0.596146, -0.802876, 300, 0, 1, 'Weed at Snowveil Cemetery (first Dignity of the Dead)'),
(9963416, 2300710, 0, 0, 0, 1, 1, -6327.975, -461.049, 649.591, 1.9511, 0, 0, 0.82801, 0.560713, 300, 0, 1, 'Weed at Snowveil Cemetery (first Dignity of the Dead)'),
(9963417, 2300710, 0, 0, 0, 1, 1, -6329.467, -454.642, 649.615, 0.3766, 0, 0, 0.187189, 0.982324, 300, 0, 1, 'Weed at Snowveil Cemetery (first Dignity of the Dead)'),
(9963418, 2300710, 0, 0, 0, 1, 1, -6325.554, -443.39, 649.567, 6.1274, 0, 0, 0.077814, -0.996968, 300, 0, 1, 'Weed at Snowveil Cemetery (first Dignity of the Dead)'),
(9963419, 2300710, 0, 0, 0, 1, 1, -6337.46, -434.078, 649.736, 3.9362, 0, 0, 0.922108, -0.386933, 300, 0, 1, 'Weed at Snowveil Cemetery (first Dignity of the Dead)'),
(9963420, 2300710, 0, 0, 0, 1, 1, -6345.516, -437.332, 649.845, 2.6514, 0, 0, 0.970114, 0.24265, 300, 0, 1, 'Weed at Snowveil Cemetery (first Dignity of the Dead)'),
(9963421, 2300710, 0, 0, 0, 1, 1, -6353.98, -439.034, 649.961, 2.1089, 0, 0, 0.869629, 0.493706, 300, 0, 1, 'Weed at Snowveil Cemetery (first Dignity of the Dead)'),
(9963422, 2300710, 0, 0, 0, 1, 1, -6362.575, -438.824, 650.08, 5.3631, 0, 0, 0.443986, -0.896034, 300, 0, 1, 'Weed at Snowveil Cemetery (first Dignity of the Dead)'),
(9963423, 2300710, 0, 0, 0, 1, 1, -6366.523, -448.991, 650.129, 5.8376, 0, 0, 0.220954, -0.975284, 300, 0, 1, 'Weed at Snowveil Cemetery (first Dignity of the Dead)'),
(9963424, 2300710, 0, 0, 0, 1, 1, -6372.766, -462.704, 650.207, 0.5648, 0, 0, 0.278661, 0.960389, 300, 0, 1, 'Weed at Snowveil Cemetery (first Dignity of the Dead)'),
(9963425, 2300712, 0, 0, 0, 1, 1, -6357.248, -467.655, 649.991, 4.8267, 0, 0, 0.665559, -0.746345, 300, 0, 1, 'Weed at Snowveil Cemetery (second Dignity of the Dead)'),
(9963426, 2300712, 0, 0, 0, 1, 1, -6347.728, -471.4, 649.858, 2.0781, 0, 0, 0.861923, 0.507039, 300, 0, 1, 'Weed at Snowveil Cemetery (second Dignity of the Dead)'),
(9963427, 2300712, 0, 0, 0, 1, 1, -6341.093, -470.817, 649.767, 5.0058, 0, 0, 0.596146, -0.802876, 300, 0, 1, 'Weed at Snowveil Cemetery (second Dignity of the Dead)'),
(9963428, 2300712, 0, 0, 0, 1, 1, -6327.975, -461.049, 649.591, 1.9511, 0, 0, 0.82801, 0.560713, 300, 0, 1, 'Weed at Snowveil Cemetery (second Dignity of the Dead)'),
(9963429, 2300712, 0, 0, 0, 1, 1, -6329.467, -454.642, 649.615, 0.3766, 0, 0, 0.187189, 0.982324, 300, 0, 1, 'Weed at Snowveil Cemetery (second Dignity of the Dead)'),
(9963430, 2300712, 0, 0, 0, 1, 1, -6325.554, -443.39, 649.567, 6.1274, 0, 0, 0.077814, -0.996968, 300, 0, 1, 'Weed at Snowveil Cemetery (second Dignity of the Dead)'),
(9963431, 2300712, 0, 0, 0, 1, 1, -6337.46, -434.078, 649.736, 3.9362, 0, 0, 0.922108, -0.386933, 300, 0, 1, 'Weed at Snowveil Cemetery (second Dignity of the Dead)'),
(9963432, 2300712, 0, 0, 0, 1, 1, -6345.516, -437.332, 649.845, 2.6514, 0, 0, 0.970114, 0.24265, 300, 0, 1, 'Weed at Snowveil Cemetery (second Dignity of the Dead)'),
(9963433, 2300712, 0, 0, 0, 1, 1, -6353.98, -439.034, 649.961, 2.1089, 0, 0, 0.869629, 0.493706, 300, 0, 1, 'Weed at Snowveil Cemetery (second Dignity of the Dead)'),
(9963434, 2300712, 0, 0, 0, 1, 1, -6362.575, -438.824, 650.08, 5.3631, 0, 0, 0.443986, -0.896034, 300, 0, 1, 'Weed at Snowveil Cemetery (second Dignity of the Dead)'),
(9963435, 2300712, 0, 0, 0, 1, 1, -6366.523, -448.991, 650.129, 5.8376, 0, 0, 0.220954, -0.975284, 300, 0, 1, 'Weed at Snowveil Cemetery (second Dignity of the Dead)'),
(9963436, 2300712, 0, 0, 0, 1, 1, -6372.766, -462.704, 650.207, 0.5648, 0, 0, 0.278661, 0.960389, 300, 0, 1, 'Weed at Snowveil Cemetery (second Dignity of the Dead)');
