-- ----------------------------------------------------------------------------
-- Worldforged pickups: Silverpine Forest, the objects its drop pin names
-- ----------------------------------------------------------------------------
-- The Silverpine Forest page carries one drop listing of its own - 'Worldforge Drops (4
-- items)' over Fenris Isle at 1003.5 706.1 - and its description names both sides of it: the
-- items looted in that area (Ravenous Eye, Gnoll Subjugator, Thule's Curse Parchment, Rot Hide
-- Mantle) and the lootable world objects it saw there:
--
--     Possible lootable world object names are:
--     Gnoll Subdue Wand, Rot Hide Stash, Thule's Curse Parchment, Cursed Fang Remains
--
-- All four objects are this module's already: each stands in gameobject_template with the
-- display its own record gives it and the loot row for the item its own pin names - 90312
-- hands out Gnoll Subjugator, 90313 Rot Hide Mantle, 90314 Ravenous Eye and 90320 Thule's
-- Curse Parchment, which is the whole list of items the listing names.
--
-- What the realm's own records add is where they stood, and for three of the four this world
-- never stood them in this zone at all.  Each has the realm's own client-cache capture of it
-- with its zone recorded as Silverpine and the world position it stood at, and the community
-- dumps carry the same spot for each:
--
--   Gnoll Subdue Wand  (90312)  1007.410  689.796  77.775    16.8 yd from the pin
--   Rot Hide Stash     (90313)   991.098  695.872  63.341    16.1 yd from the pin
--   Cursed Fang Remains(90314)  1020.430  732.173  59.395    31.1 yd from the pin
--
-- so the three are stood there.  The fourth, Thule's Curse Parchment, already has its own
-- marker on the page, and its pickup (guid 6941239) stands exactly on it - 2.4 yd from the
-- realm's own recorded spot for that object, which is the same place within the module's
-- three-yard tolerance - so nothing moves it and no second row is added.
--
-- Two of the three the map plots elsewhere as well, and those placements stand untouched:
-- Gnoll Subdue Wand and Cursed Fang Remains are the very objects the Loch Modan page's own
-- 'Worldforge Drops (2 items)' listing names, and each already stands there, on the realm's
-- own recorded spot for that listing (guids 6940556 and 6940934, at -4919.4 -3786.4 and
-- -4922.5 -3795.5).  Nothing is carried across; each zone keeps its own listing's object.
--
-- The Fenris Isle keep's own terrain cannot be read by the server's map reader (the tile is
-- unreadable at all three spots), so the height of each row is the one the realm's own client
-- saw the object at, and nothing else is invented.
--
-- Idempotent: every statement is a REPLACE keyed on the guid.  Apply to acore_world.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Gnoll Subdue Wand (90312): the object the map's Silverpine drop listing names
--   placed at the realm's own recorded position for it, 16.8 yd from the pin
--   its own template and its loot row (Gnoll Subjugator, 450529) already stand
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942549, 90312, 0, 0, 0, 1, 1, 1007.4100, 689.7960, 77.7749, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Gnoll Subdue Wand | the realm''s own object, named by the map''s Silverpine drop pin');

-- Rot Hide Stash (90313): the object the map's Silverpine drop listing names
--   placed at the realm's own recorded position for it, 16.1 yd from the pin
--   its own template and its loot row (Rot Hide Mantle, 450530) already stand; this is the
--   object's only row in the world, its record naming no other zone
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942550, 90313, 0, 0, 0, 1, 1, 991.0980, 695.8720, 63.3409, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Rot Hide Stash | the realm''s own object, named by the map''s Silverpine drop pin');

-- Cursed Fang Remains (90314): the object the map's Silverpine drop listing names
--   placed at the realm's own recorded position for it, 31.1 yd from the pin
--   its own template and its loot row (Ravenous Eye, 450531) already stand
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942551, 90314, 0, 0, 0, 1, 1, 1020.4300, 732.1730, 59.3945, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Cursed Fang Remains | the realm''s own object, named by the map''s Silverpine drop pin');

COMMIT;
