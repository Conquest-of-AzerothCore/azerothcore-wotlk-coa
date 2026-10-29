-- Worldforged Premium Banana (#8601): rev_20261006_65_worldforged_openworld_float_heights pushed the
-- Baby Gorilla Bait (gameobject guid 6940909) to the open terrain height, 1.85 yd under the Spirit
-- Den floor (confirmed with the gameplay harness's own vmap-aware ground probe). Move it to the
-- object's own recorded sighting, which sits 0.24 yd above the den floor there.

UPDATE `gameobject`
SET `position_x` = -13760.049, `position_y` = -9.869, `position_z` = 45.435
WHERE `guid` = 6940909 AND `id` = 95715 AND `position_z` BETWEEN 43.2 AND 43.3;
