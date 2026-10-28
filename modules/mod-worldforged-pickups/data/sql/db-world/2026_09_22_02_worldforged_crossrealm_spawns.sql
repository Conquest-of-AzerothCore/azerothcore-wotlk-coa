-- ----------------------------------------------------------------------------
-- Worldforged pickups: the pickups recorded on the other realms
-- ----------------------------------------------------------------------------
-- Two gaps the earlier passes left, both from the same cause: an evidence filter that
-- kept only pins recorded on Conquest of Azeroth.
--
-- 1. A recorded position the realm has no pickup at. The same pickups were pinned on
--    the other Ascension realms as well - Area 52 (free-pick), Darkmoon and Dawnrise
--    (season 10), Bronzebeard (warcraft-reborn) - and those pins carry the same world
--    coordinates the CoA pins do, in the same zones, for the same item ids. Dropping
--    them left 74 recorded positions unplaced, on 67 pickups.
--
-- 2. A pickup the client's own gameobject cache holds and no object was made for.
--    254156 'Ancient Furbolg Totem' and 254193 'Broken Highborne Lamp' are real
--    templates, captured from the free-pick realm's cache, and they are the source
--    db.exil.es names for item 354068 'Totem of the Vale' and item 354096 'Light of
--    the Highborne'. Both items are worldforged on the realm and neither had a pickup.
--
-- WHERE EVERY VALUE COMES FROM
--   position   the pin's own world X and Y, on the pin's own map, as the archive
--              records it - nothing is inferred
--   height     the height of the nearest object the realm already has on that map
--   zone       the pin's own zone; kept in the comment, as the earlier passes do
--   item       the item the pickup's own loot row already names; for the two new
--              objects, the item db.exil.es names that object as the source of
--   template   the client cache's captured row, field for field, for the two new
--              objects; the existing objects keep the row they already have
--
-- No pickup is placed twice: a row is written only where no spawn of the same object
-- already stands on that map within 30 yards, and both ranges below are cleared by
-- their own bounds first, so re-applying this migration changes nothing.
--
-- Mystic Scrolls stay out, as before.
-- Apply to acore_world.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Clear this migration's own bounds.
DELETE FROM `gameobject` WHERE `guid` BETWEEN 6920001 AND 6929999;
DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (254156, 254193);
DELETE FROM `gameobject_template` WHERE `entry` IN (254156, 254193);

-- The two pickups the client cache holds, row for row as the cache captured them.
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(254156, 3, 254036, 'Ancient Furbolg Totem', '', 'Looting', '', 2, 1689, 254156, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup'),
(254193, 3, 980926, 'Broken Highborne Lamp', '', 'Looting', '', 1, 1689, 254193, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

REPLACE INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(254156, 354068, 0, 100.0000, 0, 1, 0, 1, 1, 'AscensionWorldforged Ancient Furbolg Totem | client cache entry 254156 | pin Ammen Vale on Area 52 - Free-Pick'),
(254193, 354096, 0, 100.0000, 0, 1, 0, 1, 1, 'AscensionWorldforged Broken Highborne Lamp | client cache entry 254193 | pin Azuremyst Isle on Area 52 - Free-Pick');

-- Every recorded position the CoA-only pass dropped.
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6920001, 254156, 530, 0, 0, 1, 1, -3755.100, -13331.100, 84.326, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Ancient Furbolg Totem | client cache entry 254156 | Ammen Vale on Area 52 - Free-Pick'),
(6920002, 254193, 530, 0, 0, 1, 1, -2948.800, -12216.700, 15.365, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Broken Highborne Lamp | client cache entry 254193 | Azuremyst Isle on Area 52 - Free-Pick'),
(6920003, 1345000, 1, 0, 0, 1, 1, -1791.800, -4150.200, -1.189, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Affray Cuirras | recorded position the CoA-only pass dropped | The Barrens on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920004, 1345018, 1, 0, 0, 1, 1, -4079.100, -4060.500, 95.258, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Brackish Spellweave Robe | recorded position the CoA-only pass dropped | Dustwallow Marsh on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920005, 1345048, 0, 0, 0, 1, 1, 2245.200, 743.700, 35.752, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Empty Satchel | recorded position the CoA-only pass dropped | Tirisfal Glades on Area 52 - Free-Pick|Bronzebeard - Warcraft Reborn|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920006, 1345089, 90, 0, 0, 1, 1, -424.000, 565.100, -273.068, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Melika''s Ring | recorded position the CoA-only pass dropped | Gnomeregan on Bronzebeard - Warcraft Reborn'),
(6920007, 1345091, 189, 0, 0, 1, 1, 948.000, 1015.100, 22.627, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Minervia''s Pendant of Atonement | recorded position the CoA-only pass dropped | Scarlet Monastery on Bronzebeard - Warcraft Reborn'),
(6920008, 1345107, 530, 0, 0, 1, 1, 12927.200, -7185.100, 7.592, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Plague Purger | recorded position the CoA-only pass dropped | Isle of Quel''Danas on Bronzebeard - Warcraft Reborn'),
(6920009, 1345117, 0, 0, 0, 1, 1, -829.000, -3278.000, 78.024, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Rough Weathered Ring | recorded position the CoA-only pass dropped | Arathi Highlands on Area 52 - Free-Pick|Bronzebeard - Warcraft Reborn|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920010, 254163, 0, 0, 0, 1, 1, 1953.800, 1579.600, 81.916, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Abandoned Hammer | recorded position the CoA-only pass dropped | Deathknell on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard'),
(6920011, 254163, 0, 0, 0, 1, 1, 1883.700, 1687.200, 94.747, 0.618034, 0, 0, 0.304122, 0.952633, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Abandoned Hammer | recorded position the CoA-only pass dropped | Deathknell on Dawnrise - Season 10 Freepick'),
(6920012, 254194, 0, 0, 0, 1, 1, -8355.600, -1529.600, 184.006, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Spare Hunting Boots | recorded position the CoA-only pass dropped | Burning Steppes on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920013, 254255, 0, 0, 0, 1, 1, -9718.100, -432.800, 53.131, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Arkonite Orb | recorded position the CoA-only pass dropped | Elwynn Forest on Area 52 - Free-Pick'),
(6920014, 254255, 0, 0, 0, 1, 1, -5893.100, -33.200, 369.380, 0.618034, 0, 0, 0.304122, 0.952633, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Arkonite Orb | recorded position the CoA-only pass dropped | Dun Morogh on Area 52 - Free-Pick'),
(6920015, 254255, 0, 0, 0, 1, 1, -6088.000, 50.600, 408.375, 1.236068, 0, 0, 0.579434, 0.815019, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Arkonite Orb | recorded position the CoA-only pass dropped | Coldridge Pass on Area 52 - Free-Pick'),
(6920016, 254255, 530, 0, 0, 1, 1, -3935.900, -13684.100, 73.491, 1.854102, 0, 0, 0.799853, 0.600195, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Arkonite Orb | recorded position the CoA-only pass dropped | Ammen Vale on Area 52 - Free-Pick'),
(6920017, 254255, 530, 0, 0, 1, 1, -2948.800, -12216.700, 15.365, 2.472136, 0, 0, 0.944500, 0.328513, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Arkonite Orb | recorded position the CoA-only pass dropped | Azuremyst Isle on Area 52 - Free-Pick'),
(6920018, 254303, 1, 0, 0, 1, 1, -1226.900, 2580.200, 101.576, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Stormpiercer | recorded position the CoA-only pass dropped | Desolace on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920019, 254309, 1, 0, 0, 1, 1, -1231.800, 2979.300, 63.955, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Greataxe of Kolk | recorded position the CoA-only pass dropped | Maraudon on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920020, 254425, 1, 0, 0, 1, 1, 9841.800, 1652.900, 1341.350, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Heavy Furbolg Basket | recorded position the CoA-only pass dropped | Teldrassil on Bronzebeard - Warcraft Reborn'),
(6920021, 254449, 1, 0, 0, 1, 1, 4203.300, -6400.600, -16.349, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Reclaimed Circlet | recorded position the CoA-only pass dropped | Azshara on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920022, 254455, 1, 0, 0, 1, 1, 2817.100, -5172.200, 111.005, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Ancient Ring | recorded position the CoA-only pass dropped | Azshara on Bronzebeard - Warcraft Reborn'),
(6920023, 254463, 1, 0, 0, 1, 1, 3519.000, -5866.200, -19.871, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Warbanner | recorded position the CoA-only pass dropped | Azshara on Bronzebeard - Warcraft Reborn'),
(6920024, 254647, 0, 0, 0, 1, 1, -7997.600, -2550.000, 132.768, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Tattered Fabric | recorded position the CoA-only pass dropped | Burning Steppes on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920025, 515519, 1, 0, 0, 1, 1, -4979.700, -1408.900, -51.947, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Stray Pack Kodo Satchel | recorded position the CoA-only pass dropped | Thousand Needles on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920026, 515596, 47, 0, 0, 1, 1, 2133.600, 1628.500, 81.189, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Dangerously Loose Machine Part | recorded position the CoA-only pass dropped | Razorfen Kraul on Bronzebeard - Warcraft Reborn'),
(6920027, 515596, 90, 0, 0, 1, 1, -557.200, 234.700, -193.723, 0.618034, 0, 0, 0.304122, 0.952633, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Dangerously Loose Machine Part | recorded position the CoA-only pass dropped | Gnomeregan on Bronzebeard - Warcraft Reborn'),
(6920028, 515596, 129, 0, 0, 1, 1, 2363.800, 1025.500, 51.928, 1.236068, 0, 0, 0.579434, 0.815019, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Dangerously Loose Machine Part | recorded position the CoA-only pass dropped | Razorfen Downs on Bronzebeard - Warcraft Reborn'),
(6920029, 515773, 1, 0, 0, 1, 1, -8909.200, -3495.500, 11.783, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Disturbed Sand Pile | recorded position the CoA-only pass dropped | Tanaris on Bronzebeard - Warcraft Reborn'),
(6920030, 515797, 1, 0, 0, 1, 1, -8618.000, -3697.700, 14.746, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Sun Ritual Necklace | recorded position the CoA-only pass dropped | Tanaris on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920031, 515798, 1, 0, 0, 1, 1, -8654.800, -3987.500, 22.993, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Abandoned Trader Crate | recorded position the CoA-only pass dropped | Tanaris on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920032, 515827, 1, 0, 0, 1, 1, -7861.300, -5071.500, 6.842, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Wooden Plank | recorded position the CoA-only pass dropped | Tanaris on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920033, 515903, 1, 0, 0, 1, 1, -7115.200, -4768.600, 10.046, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged High Seas Axe | recorded position the CoA-only pass dropped | Tanaris on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920034, 515904, 1, 0, 0, 1, 1, -8463.000, -3350.600, 17.387, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Unfortunate Shoulderpad | recorded position the CoA-only pass dropped | Tanaris on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920035, 515918, 0, 0, 0, 1, 1, 443.400, -3969.700, 103.455, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Tiki Shield | recorded position the CoA-only pass dropped | The Hinterlands on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920036, 517317, 36, 0, 0, 1, 1, -50.700, -658.700, 7.403, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Syndicate Boots | recorded position the CoA-only pass dropped | The Deadmines on Bronzebeard - Warcraft Reborn'),
(6920037, 517330, 0, 0, 0, 1, 1, -486.000, -1490.000, 89.638, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Floating Debris | recorded position the CoA-only pass dropped | Hillsbrad Foothills on Bronzebeard - Warcraft Reborn'),
(6920038, 518045, 0, 0, 0, 1, 1, -6824.300, -3597.300, 244.945, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Gareks Personal Belongings | recorded position the CoA-only pass dropped | Badlands on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920039, 518051, 0, 0, 0, 1, 1, -6679.400, -3412.300, 260.036, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Lit Lantern | recorded position the CoA-only pass dropped | Badlands on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920040, 518098, 0, 0, 0, 1, 1, -6810.800, -3176.500, 261.128, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Scorched Knife | recorded position the CoA-only pass dropped | Badlands on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920041, 518135, 1, 0, 0, 1, 1, -949.500, -3699.400, 5.186, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Accumulated Moonlight | recorded position the CoA-only pass dropped | The Barrens on Bronzebeard - Warcraft Reborn'),
(6920042, 518568, 1, 0, 0, 1, 1, 7989.700, -3943.400, 694.836, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Frostsaber Halberd | recorded position the CoA-only pass dropped | Winterspring on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920043, 518586, 1, 0, 0, 1, 1, 5904.800, -4098.900, 596.385, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Icy Blade | recorded position the CoA-only pass dropped | Winterspring on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920044, 520069, 1, 0, 0, 1, 1, -108.800, -4443.400, -39.126, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Disciple Bow | recorded position the CoA-only pass dropped | Sinister Lair on Bronzebeard - Warcraft Reborn'),
(6920045, 686868, 1, 0, 0, 1, 1, -6970.800, 517.800, 8.684, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Excavator''s Pick | recorded position the CoA-only pass dropped | Silithus on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920046, 686880, 1, 0, 0, 1, 1, -6793.800, 1627.800, 5.864, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Cursed Ritual Carver | recorded position the CoA-only pass dropped | Silithus on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920047, 735902, 1, 0, 0, 1, 1, 6635.500, -3558.600, 682.223, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Primitive Offering Box | recorded position the CoA-only pass dropped | Winterspring on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920048, 90239, 0, 0, 0, 1, 1, -9707.000, 76.600, 48.351, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged The One Candle | recorded position the CoA-only pass dropped | Elwynn Forest on Bronzebeard - Warcraft Reborn'),
(6920049, 90244, 0, 0, 0, 1, 1, -10581.900, 1976.100, -2.557, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Peculiar Gold Nugget | recorded position the CoA-only pass dropped | Westfall on Bronzebeard - Warcraft Reborn'),
(6920050, 90304, 1, 0, 0, 1, 1, -1069.100, -1668.900, 135.116, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Stylish Cloak | recorded position the CoA-only pass dropped | The Barrens on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920051, 90320, 0, 0, 0, 1, 1, -91.200, 958.100, 69.308, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Thule''s Curse Parchment | recorded position the CoA-only pass dropped | Silverpine Forest on Bronzebeard - Warcraft Reborn'),
(6920052, 90383, 1, 0, 0, 1, 1, 3235.900, -296.800, 122.384, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Thistlefur Fur Shroud | recorded position the CoA-only pass dropped | Ashenvale on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920053, 90489, 0, 0, 0, 1, 1, 2388.800, -5100.600, 79.624, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Sack of Relics | recorded position the CoA-only pass dropped | Eastern Plaguelands on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920054, 90532, 0, 0, 0, 1, 1, 2598.700, -4598.800, 83.667, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Encrusted Spear | recorded position the CoA-only pass dropped | Eastern Plaguelands on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920055, 90569, 1, 0, 0, 1, 1, -5355.400, 3500.100, -5.260, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Glinting Ring | recorded position the CoA-only pass dropped | Feralas on Bronzebeard - Warcraft Reborn'),
(6920056, 90583, 1, 0, 0, 1, 1, -1973.500, 394.200, 134.949, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Rough Axe | recorded position the CoA-only pass dropped | Mulgore on Bronzebeard - Warcraft Reborn'),
(6920057, 90636, 1, 0, 0, 1, 1, -2837.700, -59.800, 22.262, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Forgotten Sack | recorded position the CoA-only pass dropped | Mulgore on Bronzebeard - Warcraft Reborn'),
(6920058, 95508, 0, 0, 0, 1, 1, -5617.000, -561.500, 392.986, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Warm Mug | recorded position the CoA-only pass dropped | Dun Morogh on Area 52 - Free-Pick|Bronzebeard - Warcraft Reborn|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920059, 95603, 0, 0, 0, 1, 1, -8997.600, -378.300, 73.514, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Sword in a Board | recorded position the CoA-only pass dropped | Northshire Valley on Area 52 - Free-Pick'),
(6920060, 95612, 0, 0, 0, 1, 1, -11275.000, 1555.900, 71.457, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Travel Sack | recorded position the CoA-only pass dropped | Westfall on Bronzebeard - Warcraft Reborn'),
(6920061, 95728, 43, 0, 0, 1, 1, -288.700, -161.900, -62.750, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Witchdoctor Effigy | recorded position the CoA-only pass dropped | Wailing Caverns on Bronzebeard - Warcraft Reborn'),
(6920062, 95746, 90, 0, 0, 1, 1, -765.300, 498.300, -303.937, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Kurzen Eviscerator | recorded position the CoA-only pass dropped | Gnomeregan on Bronzebeard - Warcraft Reborn'),
(6920063, 95779, 0, 0, 0, 1, 1, -9887.600, 1394.200, 45.665, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Storage Crate | recorded position the CoA-only pass dropped | Westfall on Area 52 - Free-Pick'),
(6920064, 95780, 0, 0, 0, 1, 1, -9729.200, 1379.200, 44.844, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Gnoll Cleaver | recorded position the CoA-only pass dropped | Westfall on Area 52 - Free-Pick'),
(6920065, 95788, 0, 0, 0, 1, 1, 427.000, -3679.400, 117.130, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Partially Digested Corpse | recorded position the CoA-only pass dropped | The Hinterlands on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920066, 95792, 0, 0, 0, 1, 1, -18.200, -4319.700, 127.546, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Shadowpounce Cowl | recorded position the CoA-only pass dropped | The Hinterlands on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920067, 95794, 0, 0, 0, 1, 1, 313.900, -3983.600, 125.032, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Idol of the Aerie | recorded position the CoA-only pass dropped | The Hinterlands on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920068, 95812, 0, 0, 0, 1, 1, -11275.000, 1555.900, 71.457, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Travel Sack | recorded position the CoA-only pass dropped | Westfall on Bronzebeard - Warcraft Reborn'),
(6920069, 95845, 0, 0, 0, 1, 1, -1387.500, -2376.600, 63.407, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Rather Large Ring | recorded position the CoA-only pass dropped | Arathi Highlands on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920070, 95884, 0, 0, 0, 1, 1, 217.900, -2651.500, 167.400, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Drinkin'' Pants | recorded position the CoA-only pass dropped | The Hinterlands on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920071, 95927, 1, 0, 0, 1, 1, -8057.800, -1381.600, -267.395, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Fallen Axe | recorded position the CoA-only pass dropped | Un''Goro Crater on Bronzebeard - Warcraft Reborn'),
(6920072, 96101, 1, 0, 0, 1, 1, -4139.900, -296.100, 47.987, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Abandoned Supplies | recorded position the CoA-only pass dropped | Feralas on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920073, 96134, 1, 0, 0, 1, 1, -2931.300, 2794.800, 71.282, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Ancient Bag of Scrolls | recorded position the CoA-only pass dropped | Feralas on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920074, 96151, 1, 0, 0, 1, 1, -3251.700, -2788.700, 35.617, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Dropped Polearm | recorded position the CoA-only pass dropped | Dustwallow Marsh on Bronzebeard - Warcraft Reborn'),
(6920075, 96173, 1, 0, 0, 1, 1, -6359.000, -2024.500, -259.247, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Jane''s Hat | recorded position the CoA-only pass dropped | Un''Goro Crater on Area 52 - Free-Pick|Bronzebeard - Warcraft Reborn|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick'),
(6920076, 96234, 1, 0, 0, 1, 1, 6828.600, -3219.900, 615.729, 0.000000, 0, 0, 0.000000, 1.000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Chest of Warm Clothes | recorded position the CoA-only pass dropped | Winterspring on Area 52 - Free-Pick|Darkmoon - Season 10 Wildcard|Dawnrise - Season 10 Freepick');

COMMIT;
