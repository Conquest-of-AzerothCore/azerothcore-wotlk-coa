-- Worldforged Silky Spaulders (#10504): rev_20261014_95_worldforged_lootcollector_alignment put the pickup
-- (gameobject guid 6941083, entry 95823) at the terrain height of the hill above the Duskwood mushroom cave, 29 yd
-- over the cave floor. Restore the spot the realm authored in game on 2026-09-25
-- (2026_09_25_48_worldforged_duskwood_pass_authored.sql), as rev_20261026_00 did for 13 other cave pickups.
UPDATE `gameobject` SET `position_x` = -10569.523438, `position_y` = -1504.900391, `position_z` = 95.118439
WHERE `guid` = 6941083 AND `id` = 95823 AND `map` = 0 AND `position_z` BETWEEN 124.013 AND 124.033;
