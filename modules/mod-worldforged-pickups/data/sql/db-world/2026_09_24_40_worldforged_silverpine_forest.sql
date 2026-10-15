-- ----------------------------------------------------------------------------
-- Worldforged pickups: Silverpine Forest, judged against the realm map marker by marker
-- ----------------------------------------------------------------------------
-- Each marker is given the object it means (the object of that name, the object whose loot
-- row carries that name as its item, or the object the archive's loot pin at that spot
-- names). A pickup of that object within 3 yd means the marker stands; farther out the
-- nearest pickup is moved onto the marker, unless it already honours a marker of its own
-- object 6 yd or more away, in which case the realm had a second placing and one is added.
-- Where the realm's own record for an object agrees with the pickup but not with this
-- marker, the two are one placement the map recorded twice and nothing moves.  A pickup
-- standing hundreds of yards from its marker is only moved when the realm's own records
-- put that object here; a name the map plots on two pages is never carried across.
--
-- Idempotent.  Apply to acore_world.
-- ----------------------------------------------------------------------------

--
-- What this pass found, and what the two files beside it then did:
--
--   * the page lists 50 markers, every one a worldforge item, and the map's own area data
--     puts 47 of them in this zone's twenty-six areas.  One name is plotted twice - Stolen
--     Rot Hide Circlet, on this page at 798.0 173.2 and on the Alterac Mountains page at
--     798.4 167.2, both inside The Dawning Isles - and the realm's own record for the object
--     agrees with the Alterac listing to 0.6 yd, so it is one placement the map drew twice.
--   * thirty-three placements stand within 3 yd of a pickup of their object and nothing is
--     moved.  Three stand farther out and are second placings of objects whose pickups
--     already honour a marker of their own in another zone - Drowned Adventurer (7,226 yd
--     away, in the neighbouring Loch Modan), Forgotten Book of Healing (6,405 yd) and Light
--     and Shadow Vol: 1 (7,669 yd) - and the realm's own dump saw each of the three in this
--     zone, within two yards of the marker that names it, so a second placing is added for
--     each at the height the realm's own client saw it at.
--   * one placement is kept where it stands: Small Claw of the Meat Wagon's pickup is 6.0 yd
--     from this page's marker, and the realm's own record for the object agrees with the
--     pickup and not with the mark, so the two plots are one placement the map recorded
--     twice.
--   * five markers name an object this world never carried, and the realm's own client-cache
--     record holds each of them standing within two yards of its marker: Ancient Priest Tome
--     (101912, display 255), Codex of Divine Mending (99018, display 184777), Cold Crystal
--     (101914, display 2770), Shadow Portal (111017, display 1048997) and Sorcerer's Cache
--     (835958, display 336).  Each is restored field for field in this file.
--   * three markers are left to the files beside this one.  The Law of Light's own record
--     here is a second book of that name (111004, display 184795), the realm's own sighting
--     of it 1.7 yd from the marker, and Maddening Aura (101913, display 515662) stands 1.7 yd
--     from its own; both are restored in 2026_09_24_41_worldforged_silverpine_forest_records
--     .sql.  Arcane Crystal is left out, and the marker's own description says why - 'Item
--     that gives Arcane Cascade mystic enchant' is Mystic Scroll: Arcane Cascade, and that
--     family is outside this module's scope; the realm's own records agree, both entries of
--     that name drawing the invisible placeholder.
--   * the page's own drop listing, 'Worldforge Drops (4 items)' over Fenris Isle, names four
--     world objects; three of them are stood on the realm's own recorded spots by
--     2026_09_24_42_worldforged_silverpine_forest_drop_pins.sql.
--   * one row is removed: Meat Wagon Small Claw 6930016, at 1246.2 1938.0 in The Skittering
--     Dark, 97 yd from any marker of its own name and with no record of the realm's near it.
--   * two pickups stand well above or below the surface the terrain reader sees, and both are
--     right where they are: Grimson Cloak (guid 6940579, 43 yd under the terrain at Deep Elem
--     Mine) stands on the mine's own floor, at the level of the Copper and Tin veins beside it
--     (107.5 and 108.4 to its 107.8), and Victim's Empty jar (guid 6940904, 163 yd under
--     Lordamere Lake) at the height the realm's own record gives it, 12.5.

START TRANSACTION;

-- Drowned Adventurer (101911): a second placing: its pickup already stands on another marker 7226 yd away
--   height from the realm's own recorded height (1.8 yd from here)
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942539, 101911, 0, 0, 0, 1, 1, 705.9000, 988.8000, 27.0055, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Drowned Adventurer | marker worldforge-silverpine-forest-drowned-adventurer');

-- Forgotten Book of Healing (99010): a second placing: its pickup already stands on another marker 6405 yd away
--   height from the realm's own recorded height (1.5 yd from here)
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942540, 99010, 0, 0, 0, 1, 1, -727.1000, 1534.8000, 17.6959, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Forgotten Book of Healing | marker worldforge-silverpine-forest-forgotten-book-of-healing');

-- Light and Shadow Vol: 1 (100011): a second placing: its pickup already stands on another marker 7669 yd away
--   height from the realm's own recorded height (0.9 yd from here)
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942541, 100011, 0, 0, 0, 1, 1, -21.8000, 1354.2000, 60.8937, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Light and Shadow Vol: 1 | marker worldforge-silverpine-forest-light-and-shadow-vol-1');

-- Ancient Priest Tome (101912): the realm's own object, restored
--   every field from the realm's client-cache record; placement from the realm's own
--   sighting of it 1.1 yd from this marker
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(101912, 3, 255, 'Ancient Priest Tome', '', 'Inspecting', '', 1.00, 1689, 101912, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

--   one spawn, where the realm's own client saw it
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942542, 101912, 0, 0, 0, 1, 1, -195.3000, 921.6000, 71.6105, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Ancient Priest Tome');

-- Codex of Divine Mending (99018): the realm's own object, restored
--   every field from the realm's client-cache record; placement from the realm's own
--   sighting of it 1.3 yd from this marker
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(99018, 3, 184777, 'Codex of Divine Mending', '', 'Inspecting', '', 1.00, 1689, 99018, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

--   one spawn, where the realm's own client saw it
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942543, 99018, 0, 0, 0, 1, 1, 770.3000, 1350.0000, 71.5328, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Codex of Divine Mending');

-- Cold Crystal (101914): the realm's own object, restored
--   every field from the realm's client-cache record; placement from the realm's own
--   sighting of it 0.6 yd from this marker
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(101914, 3, 2770, 'Cold Crystal', '', 'Inspecting', '', 1.00, 1689, 101914, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

--   one spawn, where the realm's own client saw it
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942544, 101914, 0, 0, 0, 1, 1, -164.5000, 778.8000, 70.2517, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Cold Crystal');

-- Shadow Portal (111017): the realm's own object, restored
--   every field from the realm's client-cache record; placement from the realm's own
--   sighting of it 1.5 yd from this marker
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(111017, 3, 1048997, 'Shadow Portal', '', 'Inspecting', '', 1.00, 1689, 111017, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

--   one spawn, where the realm's own client saw it
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942545, 111017, 0, 0, 0, 1, 1, -167.3000, 770.4000, 65.8123, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Shadow Portal');

-- Sorcerer's Cache (835958): the realm's own object, restored
--   every field from the realm's client-cache record; placement from the realm's own
--   sighting of it 1.1 yd from this marker
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(835958, 3, 336, 'Sorcerer''s Cache', '', 'Looting', '', 1.00, 1689, 835958, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

--   one spawn, where the realm's own client saw it
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942546, 835958, 0, 0, 0, 1, 1, -94.6000, 955.2000, 68.8878, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Sorcerer''s Cache');

-- Meat Wagon Small Claw (90349): no marker of any page plots it at 1246.2 1938.0
DELETE FROM `gameobject` WHERE `guid` = 6930016;

COMMIT;
