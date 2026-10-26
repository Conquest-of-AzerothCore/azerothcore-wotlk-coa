-- Apprentice Staff pickup (#7892): back to the live realm's own spot in Brambleblade Ravine
-- (live gameobject dump dump_Mulgore.txt, restated in 2026_09_22_00_worldforged_pickup_spawns.sql);
-- the LootCollector alignment had moved it to a rounded find pin in the hut wall.
UPDATE `gameobject` SET `position_x` = -2943.06, `position_y` = -1000.69, `position_z` = 55.331
WHERE `guid` = 6941409 AND `id` = 95670;
