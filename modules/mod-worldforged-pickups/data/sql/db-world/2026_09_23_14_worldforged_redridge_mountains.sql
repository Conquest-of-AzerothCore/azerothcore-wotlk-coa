-- ----------------------------------------------------------------------------
-- Worldforged pickups: Redridge Mountains, judged against the realm map marker by marker
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
-- Nothing in this zone was out of place: all thirty-one of the page's markers that this
-- world has an object for stand 0.0-2 yd on it, and no pickup of the zone stands on no
-- marker of any page, so no row is moved and none is dropped.  The page's other eight
-- markers are objects the realm had and this world does not carry.  Every one of them is
-- in the realm's own client-cache dump and in the archive's world-object index:
--
--   * five are named by a Conquest of Azeroth loot pin within four yards as Mystic Scroll
--     chests, and are left alone with the rest of that family:
--
--       Codex of Divine Mending (99018, display 184777)   Mystic Scroll: Promise of Renewal  1.9 yd, 3 records
--       Drowned Adventurer (101911, display 980926)       Mystic Scroll: Divine Reprieve     3.1 yd, 1 record
--       Cultivated Blazethorn (735923, display 1010579)   Mystic Scroll: Sudden Aftermath    3.1 yd, 4 records
--       Pilfered Shield (90210, display 1011608)          Mystic Scroll: Revengeful Block    3.7 yd, 3 records
--       Redfang's Cache (835953, display 336)             Mystic Scroll: Stalker's Mark      3.5 yd, 1 record
--
--   * three have no item record in any source inside sixty yards, so nothing is invented
--     for them.  Each is a chest the realm's own dump sees standing on its marker:
--     Flourishing Flowers (1190585, display 1060657) 0.5 yd, Shadowbound Doll (95024,
--     display 1046185) 0.6 yd and Maddening Aura (101913, display 515662) 1.2 yd - the
--     nearest pin to either of the last two, 37 and 43 yd away, belongs to the treasure
--     those yards away and not to them.
--
-- Redfang's Cache is the one the realm's own records can restore, and is restored here.
-- The map plots the marker at -9793.4 -2219.1; the realm's own dump sees its chest
-- (entry 835953) 0.5 yd from that spot, and a Conquest of Azeroth loot pin five and a half
-- yards from it names Melika's Ring (item 500813).  The object is written as the realm's
-- own client cache holds it - its entry, its name, its display 336, its cast bar, the
-- chest lock 1689 and its own loot-table id - and the loot row hands out that one item,
-- which is the shape this module uses: one pickup, one item.  The chest's own loot table
-- is a server-side table this world has never carried, so it cannot be read; the realm's
-- loot pin is what ties the item to the spot.  Its other pin, a Mystic Scroll, is out of
-- scope with the rest of that family.

START TRANSACTION;

-- Redfang's Cache (835953): the marker's own object, as the realm's client cache holds it
--   name, display 336, cast bar 'Looting', lock 1689, loot-table id 835953
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(835953, 3, 336, 'Redfang''s Cache', '', 'Looting', '', 1.00, 1689, 835953, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

-- Redfang's Cache (835953): the one item the realm's own records name at this spot
REPLACE INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(835953, 500813, 0, 100.0000, 0, 1, 0, 1, 1, 'AscensionWorldforged Redfang''s Cache: the realm''s own CoA loot pin 5.5 yd from this marker names Melika''s Ring');

-- Redfang's Cache (835953): one spawn, on the marker the map plots
--   height from the terrain the worldserver reads (the realm's own record for this chest,
--   0.5 yd away, gives 58.61 - they agree to 2 cm)
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942481, 835953, 0, 0, 0, 1, 1, -9793.4000, -2219.1000, 58.6270, 0.00000, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Redfang''s Cache | marker worldforge-redridge-mountains-redfang-s-cache | restored from the realm''s own chest 0.5 yd from the marker');

COMMIT;
