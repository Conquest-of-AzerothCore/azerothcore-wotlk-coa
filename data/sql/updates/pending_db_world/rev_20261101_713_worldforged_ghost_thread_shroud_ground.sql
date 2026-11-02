-- Worldforged Ghost-thread Shroud (#10535): the Darrowshire pickup (gameobject guid 6940531, entry 90534) sits
-- 1.156 yd under the terrain (map height 102.527 at its position); 2026_09_23_05_worldforged_map.sql moved it 8 yd
-- and kept the height stored for its earlier spot. Stand it on the ground, 0.30 yd above like the client's own
-- recording of the object at its earlier spot (terrain 101.067, stored z 101.371).
UPDATE `gameobject` SET `position_z` = 102.83
WHERE `guid` = 6940531 AND `id` = 90534 AND `map` = 0 AND `position_z` BETWEEN 101.361 AND 101.381;
