-- Worldforged Chipped Sentinel Blade (#8501): the realm-map pass
-- (2026_09_23_05_worldforged_map.sql) kept the pickup's own catalog Z (1278.806, its stored height
-- inside Md_Jungleden cave) but moved its XY 20+ yd away to a map marker on the cliff above the
-- cave roof, stranding it at Z 1309.030 and unreachable. Move it back to the catalog spot
-- (2026_09_16_00_worldforged_pickups.sql guid 6900989, wiped by the realm-map pass), inside the
-- cave, where the reporter found it stuck to the wall.

UPDATE `gameobject`
SET `position_x` = 10089.2, `position_y` = 1456.59, `position_z` = 1278.806
WHERE `guid` = 6941560 AND `id` = 90562 AND `position_z` BETWEEN 1308 AND 1310;
