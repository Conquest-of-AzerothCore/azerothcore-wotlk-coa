-- Worldforged Lava Hardened Rock (#10497): the pickup in Searing Gorge (gameobject guid 6941030, entry 68371) sits
-- 0.847 yd under the terrain (spawn_ground_gap against the live map/vmap data), so its 0.6 yd rock model is
-- buried while the chest stays lootable. Raise it onto the measured ground.
UPDATE `gameobject` SET `position_z` = 244.96
WHERE `guid` = 6941030 AND `id` = 68371 AND `map` = 0 AND `position_z` BETWEEN 244.099 AND 244.119;
