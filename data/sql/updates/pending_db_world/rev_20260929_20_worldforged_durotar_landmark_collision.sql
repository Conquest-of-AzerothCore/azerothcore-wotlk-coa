-- ----------------------------------------------------------------------------
-- Worldforged pickups: one Valley of Trials landmark, two catalog entries
-- ----------------------------------------------------------------------------
-- The realm map pass (2026_09_23_05_worldforged_map.sql) plotted two different catalog
-- entries onto what is the same physical landmark in the Valley of Trials:
--
--   * Stuck Sword (95646, "Skull Sword" loot) at guid 6942258, -362.800 -4288.700;
--   * Stuck Sword (254520, "Slayer's Claymore" loot) at guid 6942199, -363.200 -4288.900.
--
-- The two spawns sit 0.4-0.6 yd apart on an identical rotation quaternion
-- (5.793960 / 0.242181 / -0.970231) - not two props, one prop plotted twice under two
-- names. Entry 254520 has no other placement anywhere in the realm map, so it is the one
-- this landmark belongs to (issue #5366 names "Slayer's Claymore" as the sword that
-- belongs here). Entry 95646 keeps its other two, differently themed homes - Searing
-- Gorge (guid 6941092) and Skull Rock (guid 6942196) - so removing its Durotar copy
-- loses no unique content; the item stays obtainable at both of those spots.
--
-- Idempotent: one DELETE keyed on the guid.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Stuck Sword (95646, Skull Sword loot), duplicate of Slayer's Claymore (254520, guid 6942199)
DELETE FROM `gameobject` WHERE `guid` = 6942258;

COMMIT;
