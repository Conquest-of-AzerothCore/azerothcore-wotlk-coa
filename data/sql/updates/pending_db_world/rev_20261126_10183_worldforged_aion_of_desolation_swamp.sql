-- Remove stray Swamp of Sorrows spawn (guid 6940027) of Coalescence of Agony (entry 254503,
-- drops Aion of Desolation 354459, ItemLevel 60, RequiredLevel 55) from the multi-realm pin import
-- (2026_09_22_00_worldforged_pickup_spawns.sql:903). Both the CoA realm dump (6900238) and CoA
-- sidekick data place it solely in Deadwind Pass (guid 6940026). (#10183)
DELETE FROM `gameobject` WHERE `guid` = 6940027 AND `id` = 254503 AND `map` = 0;
