-- CoA worldforged: remove the misplaced Idol of Shifting Sands copy standing in the Valley of Trials
--
-- Item 410065 (Draconian Relic Sediment / Idol of Shifting Sands, pickup template 518457) belongs in
-- Silithus (guid 6941857, kept). The realm-map migration (2026_09_23_05_worldforged_map.sql:1910) also
-- placed a copy, guid 6941858, in the Valley of Trials -- the same wrong-zone pattern rev_20261024_90
-- already removed for the other worldforged gear pickups (#6485).
DELETE FROM `gameobject` WHERE `guid` = 6941858 AND `id` = 518457 AND `map` = 1 AND `position_x` BETWEEN -200.9 AND -199.9 AND `position_y` BETWEEN -4360.0 AND -4359.0;
