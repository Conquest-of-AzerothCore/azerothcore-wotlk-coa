-- ----------------------------------------------------------------------------
-- Worldforged pickups: Searing Gorge, judged against the realm map marker by marker
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
-- What this pass found:
--
--   * four chests the zone's map lists twice - once by the item the pickup hands out, once by
--     the object it is.  Incendiosaur Bone String, Dark Iron Legplates and Dark Iron Wristbands
--     are the item's listing on this zone's page, with Pile of Bones, Dwarf Corpse and Broken
--     Chain the object's listing on the Dun Morogh page, three to five yards away; Taskmaster's
--     Blade is the object's listing on this page, and the item it hands out, Searsteel Claymore,
--     is the Blackrock Mountain page's, 4.1 yd away.  In all four the realm's own record for
--     the object agrees with the object's listing (0.3 to 1.5 yd) and stands 3.9 to 4.5 yd from
--     the item's, so the pickup stands on the object's listing and the item's is the map's
--     redrawing of it - the reading the Westfall pass took for its two such markers.  Three
--     pickups therefore move, having stood on an item's listing, and Dark Iron Wristbands'
--     already stands on the object's listing and does not move.
--   * four objects this world never carried are restored field for field - entry, type, display,
--     size and data - each on the spot the realm's own client saw it.  Two the pass reached
--     through the client-cache corpus it reads (Incendiary Ammo Cache 1344096, Ripped Diary
--     Page 90449); the other two that corpus does not carry at all, and their records come from
--     the realm's own archive for the entry instead (Mysterious Orb 90044, fetched for the
--     entry; Volatile Lava 518367, the capture kept for it).  Nothing is guessed: every field
--     is a value one of those records states.  Ripped Diary Page is the name of the item it
--     hands out and takes that loot row; the other three name no item in any source in hand,
--     so their loot ids stay the entries their own records name and no row is written for
--     them.
--   * Volatile Lava's own display is the realm's invisible placeholder (980926, the client's
--     invisible_cube): what stands there is a hidden interactive chest, as in the realm, and
--     nothing visible stands within twenty-five yards of it in the realm's own sightings (the
--     nearest is the Stone Anvil twenty-two yards off, which this world already carries), so no
--     visible prop is restored beside it.
--
-- Of the 59 placements the map plots inside the zone - 52 of them on the zone's own page, the
-- rest a neighbour's listing of a chest this page also lists, or a marker a neighbour's page
-- files here - 55 are honoured by a pickup of their object standing within three yards: 47
-- already did, three are moved, one is kept at the realm's own record, and four are the
-- restorations above.  The four that are not are the item's listings of the chests listed
-- twice, standing 3.4 to 4.7 yd off on the redrawing.  No pickup in the zone stands on no
-- marker of any page, so no row is dropped.  Two more markers of the zone's page, Blackbreach
-- Handaxe and Defias Special Bucket, project into the neighbouring areas their own positions
-- fall in (Blackrock Stronghold and Burning Steppes); the world's own pickups stand exactly on
-- the page's plots for them (6940122, 6940346) and those areas' passes kept them.
-- ----------------------------------------------------------------------------


START TRANSACTION;

-- Pile of Bones (68428): was -6382.5 -1326.4, 3.4 yd off the marker
--   height from its own height, unchanged (moved 3.4 yd)
--   one chest the map lists twice: this object's listing here, and the item it hands out
--   (Incendiosaur Bone String) plotted 3.4 yd away on this zone's own page.  The realm's own
--   record for Pile of Bones is -6383.3 -1330.4, 1.5 yd from this listing and 4.1 yd from the
--   item's, so the object's listing is the placement and the item's is the redrawing.
UPDATE `gameobject` SET `position_x` = -6381.9000, `position_y` = -1329.7000, `position_z` = 129.7270 WHERE `guid` = 6940648;

-- Dwarf Corpse (68430): was -6559.2 -1271.5, 3.4 yd off the marker
--   height from its own height, unchanged (moved 3.4 yd)
--   one chest the map lists twice: this object's listing here, and the item it hands out
--   (Dark Iron Legplates) plotted 3.4 yd away on this zone's own page.  The realm's own record
--   for Dwarf Corpse is -6562.5 -1269.8, 0.8 yd from this listing and 3.9 yd from the item's.
UPDATE `gameobject` SET `position_x` = -6562.5000, `position_y` = -1270.6000, `position_z` = 136.2120 WHERE `guid` = 6940302;

-- Taskmaster's Blade (254660): was -7190.6 -892.6, 4.3 yd off the marker
--   height from its own height, unchanged (moved 4.3 yd)
--   one chest the map lists twice: this object's listing here, and the item it hands out
--   (Searsteel Claymore) plotted 4.1 yd away on the Blackrock Mountain page.  The realm's own
--   record for Taskmaster's Blade is -7188.7 -888.6, 0.3 yd from this listing and 4.5 yd from
--   the item's.
UPDATE `gameobject` SET `position_x` = -7188.5000, `position_y` = -888.9000, `position_z` = 165.8030 WHERE `guid` = 6941042;

-- Mysterious Orb (90044): the realm's own object, restored
--   every field from the realm's own archive record for the entry, which the client-cache
--   corpus this pass reads does not carry (type Chest, display 515667 - the orb the client
--   draws - lock 1689, its own loot id, size 0.9, cast bar 'Consuming'); placement from the
--   realm's own sighting of it 0.8 yd from this marker
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(90044, 3, 515667, 'Mysterious Orb', '', 'Consuming', '', 0.90, 1689, 90044, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

--   one spawn, where the realm's own client saw it
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942488, 90044, 0, 0, 0, 1, 1, -7316.4000, -1156.8000, 312.1950, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Mysterious Orb');

-- Volatile Lava (518367): the realm's own object, restored
--   every field from the realm's own archive record for the entry (type Chest, display 980926
--   - the client's invisible_cube, the placeholder the realm used for hidden interactive
--   chests - lock 1689, its own loot id, size 1.0, cast bar 'Looting'); the client-cache
--   corpus this pass reads does not carry the entry.  Placement from the realm's own sighting
--   of it 0.4 yd from this marker, at the height the realm's own client saw it (325.118, which
--   the realm's own props there stand within a yard of - the campfire 324.0, the Stone Anvil
--   324.1, a Solid Chest 324.3 - and the map reader reads at 323.6)
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(518367, 3, 980926, 'Volatile Lava', '', 'Looting', '', 1.00, 1689, 518367, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

--   one spawn, where the realm's own client saw it
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942489, 518367, 0, 0, 0, 1, 1, -6489.6000, -873.3000, 325.1180, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Volatile Lava');

-- Incendiary Ammo Cache (1344096): the realm's own object, restored
--   every field from the realm's client-cache record; placement from the realm's own
--   sighting of it 0.6 yd from this marker, at the height the client saw it (196.0, the floor
--   the realm's own props in that cave share - the ore veins at 196.6 and the Dented
--   Footlocker at 194.7, under terrain the map reader puts 46 yd above them)
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(1344096, 3, 300027, 'Incendiary Ammo Cache', '', '', '', 1.00, 1689, 1344096, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

--   one spawn, where the realm's own client saw it
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942486, 1344096, 0, 0, 0, 1, 1, -6757.3000, -1393.4000, 196.0000, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Incendiary Ammo Cache');

-- Ripped Diary Page (90449): the realm's own object, restored
--   every field from the realm's client-cache record; placement from the realm's own
--   sighting of it 0.5 yd from this marker, at the height the client saw it (313.373, on the
--   ground the map reader reads there)
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(90449, 3, 1015781, 'Ripped Diary Page', '', 'Looting', '', 0.80, 1689, 90449, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

-- Ripped Diary Page (90449): the item this marker is named after
REPLACE INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(90449, 1029571, 0, 100.0000, 0, 1, 0, 1, 1, 'AscensionWorldforged Ripped Diary Page: the marker is named for this item (the realm''s own chest 90449 stands here)');

--   one spawn, where the realm's own client saw it
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942487, 90449, 0, 0, 0, 1, 1, -7219.7000, -1969.2000, 313.3730, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Ripped Diary Page');

COMMIT;
