-- Worldforged Blaze Runners (#10545): the Un'Goro pickup (gameobject guid 6941449, entry 95932) floats 8.57 yd
-- above the terrain. 2026_09_23_06_worldforged_recorded_heights.sql gave it the height of the client's sighting
-- (-157.050) without that sighting's position, 6.7 yd from where the map pass put it. Restore the sighting
-- (row 6901330 of 2026_09_16_00_worldforged_pickups.sql: -7074.720, -1306.400, -157.050), where the terrain is
-- -157.051.
UPDATE `gameobject` SET `position_x` = -7074.72, `position_y` = -1306.4, `position_z` = -157.05
WHERE `guid` = 6941449 AND `id` = 95932 AND `map` = 1 AND `position_z` BETWEEN -157.06 AND -157.04;
