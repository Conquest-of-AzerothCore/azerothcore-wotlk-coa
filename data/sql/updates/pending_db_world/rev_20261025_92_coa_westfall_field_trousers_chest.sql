-- Field Trousers pickup (#7797): back to the live realm's own spot in Saldean's farmhouse
-- (live gameobject dump curated/dump_Westfall.csv, restated in 2026_09_25_55_worldforged_westfall_missing.sql);
-- the LootCollector alignment had moved it to a rounded find pin against the farmhouse wall.
UPDATE `gameobject` SET `position_x` = -10114.0996, `position_y` = 1046.77, `position_z` = 43.7252
WHERE `guid` = 6960040 AND `id` = 95809;
