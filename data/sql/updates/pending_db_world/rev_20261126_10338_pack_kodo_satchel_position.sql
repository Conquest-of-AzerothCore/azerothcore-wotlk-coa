-- Worldforged Pack Kodo Satchel (entry 515519, guid 6942018, Thousand Needles): 2026_09_23_05_worldforged_map moved
-- it 10.33 yd north-west into rock spire Thousandrock15.m2 and 2026_09_23_06_worldforged_recorded_heights set
-- z = -51.947 (5.81 yd below the -46.1354 terrain at that XY), burying it underground (#10338). Restore first-pass
-- realm-dump row 6900470 (-4926.170, -1363.490, -51.947) on open ground (terrain -52.2181, gap +0.271 yd).
UPDATE `gameobject`
SET `position_x` = -4926.170, `position_y` = -1363.490, `position_z` = -51.947,
    `orientation` = 3.08028, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.999530, `rotation3` = 0.030651
WHERE `guid` = 6942018 AND `id` = 515519 AND `map` = 1;
