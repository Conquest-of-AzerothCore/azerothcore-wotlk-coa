-- The Coldhewn quest trees (Dun Morogh Tree 2300580, guids 7914150-7914179) were deleted by the GatherMate import
-- (rev_20261027_60, "existing nodes of the same profession ... are replaced") and never put back, so quest 500005
-- Timber for the Coldhewn had no Frostpine Log source (#11053). Restore the 30 spawns as rev_20260925_12 placed them;
-- none sits within 4 yd of a GatherMate node.
DELETE FROM `gameobject` WHERE `guid` BETWEEN 7914150 AND 7914179;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(7914150, 2300580, 0, 0, 0, 1, 1, -5734.5, -1188.5, 379.316, 0.3, 0, 0, 0.149438, 0.988771, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north logging site, beside the small snow pines of the Questie sighting'),
(7914151, 2300580, 0, 0, 0, 1, 1, -5725.5, -1186, 380.563, 2, 0, 0, 0.841471, 0.540302, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north logging site, beside the axe-cut stump'),
(7914152, 2300580, 0, 0, 0, 1, 1, -5721, -1196.5, 382.071, 4.1, 0, 0, 0.887362, -0.461073, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north logging site, south of the stump and the old snow tree'),
(7914153, 2300580, 0, 0, 0, 1, 1, -5736, -1201, 382.593, 5.5, 0, 0, 0.381661, -0.924302, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north logging site, on the slope below the big snow pine'),
(7914154, 2300580, 0, 0, 0, 1, 1, -5681, -1206, 387.234, 1.2, 0, 0, 0.564642, 0.825336, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north-east grove of the cut stumps, its edge inside the circle'),
(7914155, 2300580, 0, 0, 0, 1, 1, -5700.5, -1246, 389.695, 3.3, 0, 0, 0.996865, -0.079121, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; east grove, beside the small snow pines of the Questie sighting'),
(7914156, 2300580, 0, 0, 0, 1, 1, -5700, -1264, 389.949, 0.8, 0, 0, 0.389418, 0.921061, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; east grove, south of the old broadleaf'),
(7914157, 2300580, 0, 0, 0, 1, 1, -5689, -1248, 389.211, 2.7, 0, 0, 0.975723, 0.219007, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; east grove, among its tall snow trees'),
(7914158, 2300580, 0, 0, 0, 1, 1, -5705, -1256, 390.25, 4.6, 0, 0, 0.745705, -0.666276, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; west edge of the east grove'),
(7914159, 2300580, 0, 0, 0, 1, 1, -5671, -1252, 389.657, 1.9, 0, 0, 0.813416, 0.581683, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south-east grove, beside the mid snow tree'),
(7914160, 2300580, 0, 0, 0, 1, 1, -5674, -1268, 389.984, 5.1, 0, 0, 0.557684, -0.830054, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south-east grove, by the snow pine'),
(7914161, 2300580, 0, 0, 0, 1, 1, -5677, -1258, 389.609, 0.5, 0, 0, 0.247404, 0.968912, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south-east grove, between its snow trees'),
(7914162, 2300580, 0, 0, 0, 1, 1, -5752, -1212, 388.42, 3.7, 0, 0, 0.961275, -0.27559, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; the rise north of the camp, above the copper vein'),
(7914163, 2300580, 0, 0, 0, 1, 1, -5737, -1227, 383.141, 2.2, 0, 0, 0.891207, 0.453596, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north of the camp, beside the big mid snow tree'),
(7914164, 2300580, 0, 0, 0, 1, 1, -5765, -1230, 378.86, 6, 0, 0, 0.14112, -0.989992, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north of the camp, by the small snow pines'),
(7914165, 2300580, 0, 0, 0, 1, 1, -5795, -1193, 377.073, 1, 0, 0, 0.479426, 0.877583, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north-west grove, by the small snow pines of the Questie sighting'),
(7914166, 2300580, 0, 0, 0, 1, 1, -5786.5, -1198.5, 375.915, 3.9, 0, 0, 0.92896, -0.370181, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north-west grove, between its tall snow trees'),
(7914167, 2300580, 0, 0, 0, 1, 1, -5779.5, -1188, 378.227, 2.5, 0, 0, 0.948985, 0.315322, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north-west grove, east edge'),
(7914168, 2300580, 0, 0, 0, 1, 1, -5796, -1212.5, 376.729, 4.9, 0, 0, 0.637765, -0.770231, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north-west grove, south edge by the snow pine'),
(7914169, 2300580, 0, 0, 0, 1, 1, -5757, -1178.5, 376.563, 0.6, 0, 0, 0.29552, 0.955336, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north grove, by the old broadleaf'),
(7914170, 2300580, 0, 0, 0, 1, 1, -5767, -1190, 380.102, 3.1, 0, 0, 0.999784, 0.020795, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north grove, on the slope between its trees'),
(7914171, 2300580, 0, 0, 0, 1, 1, -5748, -1187, 380.44, 5.8, 0, 0, 0.239249, -0.970958, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; north grove, by the snow pine'),
(7914172, 2300580, 0, 0, 0, 1, 1, -5745, -1294, 387.64, 1.6, 0, 0, 0.717356, 0.696707, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south of the camp, by the small snow pine of the Questie sighting'),
(7914173, 2300580, 0, 0, 0, 1, 1, -5755, -1300, 388.499, 4.3, 0, 0, 0.836899, -0.547358, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south of the camp, beyond the snow pines'),
(7914174, 2300580, 0, 0, 0, 1, 1, -5745, -1321, 391.261, 2.8, 0, 0, 0.98545, 0.169967, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south grove, beside the small snow pines of the Questie sighting'),
(7914175, 2300580, 0, 0, 0, 1, 1, -5758, -1318, 389.826, 0.1, 0, 0, 0.049979, 0.99875, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south grove, between the snow pine and the broadleaf'),
(7914176, 2300580, 0, 0, 0, 1, 1, -5767, -1314, 388.54, 5.3, 0, 0, 0.472031, -0.881582, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; south grove, west edge toward the two-storey house'),
(7914177, 2300580, 0, 0, 0, 1, 1, -5716, -1226, 387.893, 3.5, 0, 0, 0.983986, -0.178246, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; a lone young tree on the open slope between the camp and the east grove'),
(7914178, 2300580, 0, 0, 0, 1, 1, -5712, -1276, 390.218, 1.3, 0, 0, 0.605186, 0.796084, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; a lone young tree on the open slope south-east of the camp'),
(7914179, 2300580, 0, 0, 0, 1, 1, -5728, -1312, 392.011, 4, 0, 0, 0.909297, -0.416147, 120, 100, 1, '', 'CoA Coldhewn woods: Dun Morogh Tree; a young tree on the slope east of the south grove');
