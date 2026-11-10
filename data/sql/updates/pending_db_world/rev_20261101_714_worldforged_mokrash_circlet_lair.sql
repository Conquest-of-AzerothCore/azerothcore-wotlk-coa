-- Worldforged Mok'rash's Circlet (#10536): 2026_09_23_05_worldforged_map.sql put the pickup (gameobject guid
-- 6940758, entry 254352) at a realm map marker on the Stranglethorn sea floor north of Booty Bay (z -20.916, the
-- terrain height there), 48 yd from Mok'rash. Restore the position the catalog recorded for it
-- (row 6900136 of 2026_09_16_00_worldforged_pickups.sql: -14223.100, 718.328, 10.483, z observed), which stands 0.13 yd
-- above the terrain on the ridge at Mok'rash's lair. Orientation and rotation already match.
UPDATE `gameobject` SET `position_x` = -14223.1, `position_y` = 718.328, `position_z` = 10.483
WHERE `guid` = 6940758 AND `id` = 254352 AND `map` = 0 AND `position_z` BETWEEN -20.926 AND -20.906;
