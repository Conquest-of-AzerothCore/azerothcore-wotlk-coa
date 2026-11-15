-- Worldforged Fisherman's Last Wish (Westfall, guid 6940479) was authored in game at
-- (-9790.015625, 2104.459961, 13.301194) (2026_09_25_54_worldforged_westfall_revision.sql), then
-- rev_20261014_95_worldforged_lootcollector_alignment.sql moved it 34 yd away. Restore the authored spot (#10684).
UPDATE `gameobject` SET `position_x` = -9790.015625, `position_y` = 2104.459961, `position_z` = 13.301194
WHERE `guid` = 6940479 AND `id` = 90243 AND `map` = 0
  AND `position_x` BETWEEN -9775.06 AND -9774.06 AND `position_y` BETWEEN 2133.31 AND 2134.31
  AND ABS(`position_z` - 12.954) < 0.01;
