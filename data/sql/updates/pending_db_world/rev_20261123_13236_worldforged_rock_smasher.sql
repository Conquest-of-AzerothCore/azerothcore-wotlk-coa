-- #13236: Worldforged Rock Smasher (6941427) stood on the mountain surface 71 yd above the Clawed Mountains cave the item belongs in; restore its first-pass realm row from 2026_09_16_00 inside the cave (ground gap 0.05).
UPDATE `gameobject` SET `position_x` = 1419.13, `position_y` = 1262.91, `position_z` = 188.594
WHERE `guid` = 6941427 AND `id` = 95655;
