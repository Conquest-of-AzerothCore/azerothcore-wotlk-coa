-- ----------------------------------------------------------------------------
-- Worldforged pickups: Silverpine Forest, the objects the realm's own records restore
-- ----------------------------------------------------------------------------
-- The zone pass beside this file judges the zone marker by marker.  Three of its markers
-- name an object this world does not carry, and the realm's own records decide what each
-- one is:
--
--   * The Law of Light (111004) - the archive's own client-cache record, at the very spot:
--     the realm's own sighting of that entry in Silverpine stands 1.7 yd from the marker.
--     It is a second object of that name (display 184795, a book, where the entry this
--     world already carries - 111000, display 184790 - is the one the map plots in Loch
--     Modan, Darkshore and Westfall).  The marker names item 9200812, which this world has;
--     the same-named object's Loch Modan placing already hands it out, and this module's
--     shape is one pickup one item, so the row is written here too and the book is not empty.
--
--   * Maddening Aura (101913) - the archive's own client-cache record, on the realm's own
--     sighting 1.7 yd from the marker, in Pyrewood Village: display 515662 (the shadow-leech
--     orb the realm uses for it), cast bar 'Inspecting', size 1.  No item named Maddening Aura
--     exists in any source in hand, so no loot row is written, as everywhere else.  The same
--     object is plotted on the Redridge Mountains page as well and the realm saw it there too
--     (-9407.3 -3090.8, entry 101913, 1.2 yd from that marker); that page's own pass left it
--     among the markers whose object could not be tied to an item, and it is restored here
--     for the Silverpine listing the realm's own record stands on.  The Redridge listing is
--     left as that pass left it.
--
--   * Arcane Crystal - left alone, and the reason is the marker's own description: "Item that
--     gives Arcane Cascade mystic enchant."  That is Mystic Scroll: Arcane Cascade (item
--     201595), and the Mystic Scroll family is deliberately outside this module's scope, as
--     the Redridge, Wetlands, Arathi, Hillsbrad and Hinterlands sections say.  The realm's own
--     records agree with the description rather than contradict it: the two entries of that
--     name it holds (99503 and 680016) both draw display 980926, the invisible placeholder,
--     so what stood in the world was the scroll's own sparkle, not a world object.  This is
--     also why the eighth and ninth passes (Westfall, Duskwood) left that marker alone.
--
-- Nothing is guessed: every field of both restored rows is the value the realm's own capture
-- states, and the height is the one the realm's own client saw each object at.
--
-- Idempotent: every statement is a REPLACE on an entry or a guid.  Apply to acore_world.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- The Law of Light (111004): the archive's own record
--   placed on the realm's own sighting of it, 1.7 yd from this marker
--   the marker names item 9200812, which this world has
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(111004, 3, 184795, 'The Law of Light', '', 'Inspecting', '', 1.00, 1689, 111004, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

--   one spawn, where the realm's own client saw it
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942547, 111004, 0, 0, 0, 1, 1, -376.5290, 1116.3500, 84.1510, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged The Law of Light | Silverpine, the realm''s own record');

--   the item the marker names
REPLACE INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(111004, 9200812, 0, 100.0000, 0, 1, 0, 1, 1, 'AscensionWorldforged The Law of Light: the item the marker names (its same-named placing in Loch Modan hands out the same item)');

-- Maddening Aura (101913): the archive's own record
--   placed on the realm's own sighting of it, 1.7 yd from this marker
--   height 12.179 is the realm's own; the terrain reader sees the village surface, 17.445,
--   over the object's own spot
--   no item of this name is recorded in any source held, so no loot row is written
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(101913, 3, 515662, 'Maddening Aura', '', 'Inspecting', '', 1.00, 1689, 101913, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

--   one spawn, where the realm's own client saw it
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942548, 101913, 0, 0, 0, 1, 1, -379.3070, 1659.1300, 12.1786, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Maddening Aura | Silverpine, the realm''s own record');

COMMIT;
