-- ----------------------------------------------------------------------------
-- Worldforged pickups: Dun Morogh and Coldridge Valley, judged against the realm map marker by marker
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
-- What this pass found, and how it differs from the passes before it:
--
--   * the map's own sub-zone pages (the Grizzled Den, Coldridge Pass, Chill Breeze Valley,
--     Gol'Bolar Quarry, Northshire Valley and thirty-five more) carry 380 markers of their
--     own, and the set the earlier passes read had no world rectangle for any of those
--     pages, so those markers were invisible to them.  Twenty-one of them stand in Dun
--     Morogh: the Grizzled Den's own chests, at the back of the zone by the Chill Breeze
--     Valley and the pass.  The complete set is used here, and every zone already written
--     is being re-read against it.
--   * nine placements the map lists twice (once on the zone page, once on a sub-zone or
--     neighbouring page a few yards away) are judged as one placement each: the realm's own
--     recording of the object decides which of the two plots is the real one.
--   * four pickups stood a few yards off their marker and are put on it; nothing in the
--     zone stands on no marker, so no row is dropped.
--   * three markers name objects this world never carried, and the realm's own dump holds
--     each of them standing within three yards of its marker.  They are restored field for
--     field from those records: Adlin's Cherry Pie (90639, the chest is the realm's own
--     invisible one, so the visible Cherry Pie prop 90635 the realm stood beside it is
--     restored with it), Brynja's Water Pouch (90640, display 1033132) and the Black Powder
--     Barrel (93002, display 30).  Each chest keeps its own lock and its own loot-table id;
--     the two whose item the map names are given the loot row for that item, and the barrel's
--     item is recorded in no source in hand and is left to the loot table its own record
--     names.

START TRANSACTION;

-- Miner's Pickaxe (95509): was -5694.6 -1662.9, 3.9 yd off the marker
--   height from its own height, unchanged (moved 3.9 yd)
UPDATE `gameobject` SET `position_x` = -5692.5000, `position_y` = -1659.6000, `position_z` = 361.8240 WHERE `guid` = 6940247;

-- Frostwalker's Boots (95500): was -6227.8 693.3, 4.1 yd off the marker
--   height from its own height, unchanged (moved 4.1 yd)
UPDATE `gameobject` SET `position_x` = -6227.6000, `position_y` = 689.2000, `position_z` = 384.9370 WHERE `guid` = 6940513;

-- Radiant Helmet (520704): was -5884.6 477.9, 4.9 yd off the marker
--   height from its own height, unchanged (moved 4.9 yd)
UPDATE `gameobject` SET `position_x` = -5889.5000, `position_y` = 477.4000, `position_z` = 535.9810 WHERE `guid` = 6940923;

-- Forgotten Sack (90636): was -6048.6 40.4, 4.9 yd off the marker
--   height from its own height, unchanged (moved 4.9 yd)
UPDATE `gameobject` SET `position_x` = -6043.8000, `position_y` = 39.2000, `position_z` = 408.3750 WHERE `guid` = 6940016;

-- Adlin's Cherry Pie (90639): the realm's own object, restored
--   every field from the realm's client-cache record; placement from the realm's own
--   sighting of it 0.5 yd from this marker
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(90639, 3, 980926, 'Adlin''s Cherry Pie', '', 'Looting', '', 1.00, 1689, 90639, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

-- Adlin's Cherry Pie (90639): the item this marker is named after
REPLACE INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(90639, 694541, 0, 100.0000, 0, 1, 0, 1, 1, 'AscensionWorldforged Adlin''s Cherry Pie: the marker is named for this item (the realm''s own chest 90639 stands here)');

--   one spawn, where the realm's own client saw it
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942482, 90639, 0, 0, 0, 1, 1, -6224.3000, 319.9000, 383.8420, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Adlin''s Cherry Pie');

-- Black Powder Barrel (93002): the realm's own object, restored
--   every field from the realm's client-cache record; placement from the realm's own
--   sighting of it 2.7 yd from this marker
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(93002, 3, 30, 'Black Powder Barrel', '', 'Inspecting', '', 1.00, 1689, 93002, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

--   one spawn, where the realm's own client saw it
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942483, 93002, 0, 0, 0, 1, 1, -5777.9000, -1246.0000, 379.4950, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Black Powder Barrel');

-- Brynja's Water Pouch (90640): the realm's own object, restored
--   every field from the realm's client-cache record; placement from the realm's own
--   sighting of it 1.2 yd from this marker
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(90640, 3, 1033132, 'Brynja''s Water Pouch', '', 'Looting', '', 1.00, 1689, 90640, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

-- Brynja's Water Pouch (90640): the item this marker is named after
REPLACE INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(90640, 969160, 0, 100.0000, 0, 1, 0, 1, 1, 'AscensionWorldforged Brynja''s Water Pouch: the marker is named for this item (the realm''s own chest 90640 stands here)');

--   one spawn, where the realm's own client saw it
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942484, 90640, 0, 0, 0, 1, 1, -6162.0000, 359.3000, 401.1480, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Brynja''s Water Pouch');

-- Cherry Pie prop (90635): the realm's own object, restored
--   every field from the realm's client-cache record; placement from the realm's own
--   sighting of it
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(90635, 5, 5493, 'Cherry Pie prop', '', 'Looting', '', 3.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');

--   one spawn, beside the realm's own chest
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942485, 90635, 0, 0, 0, 1, 1, -6223.9199, 319.5270, 383.6790, 0.00000, 0, 0, 0, 1, 0, 0, 1, '', 'AscensionWorldforged Cherry Pie prop');

COMMIT;
