-- ----------------------------------------------------------------------------
-- Worldforged pickups: Burning Steppes, judged against the realm map marker by marker
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
-- The page lists 78 markers: 74 real placements and, of the rest, two names nothing in any
-- source in hand holds and two cluster labels.  Three placements stood a few yards off their
-- marker and are snapped onto it, one is kept where the realm's own record puts it, and three
-- rows stand on no marker of any page and go.
--
--   * Half Buried Chest (guid 6940493) is a placement the map records twice: its Burning Steppes
--     page plots 'Half Buried Chest' at -7481.9 -2272.4 and its Badlands page plots the same
--     chest as the item it hands out, 'Focusing Spirit Band', 5.7 yd away.  The realm's own dump
--     sees that chest at -7481.6 -2271.9 - 0.7 yd from the Burning Steppes marker and 6.1 yd
--     from the Badlands one - so the pickup stands where the realm had it, and the Badlands
--     page's twin listing is left to that zone's own pass.
--   * Forgewright's Scepter (6940234) and Obsidian Axe (6940424) stood 3.8 and 3.3 yd off their
--     markers, while the realm's own dumps see those chests 0.6 and 0.8 yd from the markers'
--     own spots, so both are snapped on.
--   * Obsidian Boltthrower's pickup stands 5.2 yd off its marker and the realm's own record for
--     that chest agrees with the pickup rather than with the marker (3.4 yd off it), so it is
--     kept where it stands.
--   * Blackbreach Handaxe (6940123), Darkest Night Ring (6940310) and Taskmaster's Blade
--     (6941041) stand 127.7, 85.6 and 120.7 yd from the nearest marker of any page, and each is
--     a second spawn of an entry whose other spawn stands on the realm's own recorded spot
--     (1.2, 1.1 and 4.4 yd from it), so they are removed and no documented placement is lost.
--   * two markers name nothing in any source in hand: 'Charred Corpse' (no object of that name,
--     no loot pin, and nothing of the realm's own within 60 yd at all) and 'Burning Heat' (no
--     object of that name; its own Conquest of Azeroth pin 2.0 yd away names Mystic Scroll:
--     Cataclysmic Sundering).  Nothing is invented for either.
--   * two cluster labels, Worldforge Drops (2 items), over the Firegut camp at -7714.2 -2872.8.


START TRANSACTION;

-- Obsidian Axe (254658): was -7595.8 -1089.0, 3.3 yd off the marker
--   height from its own height, unchanged (moved 3.3 yd)
UPDATE `gameobject` SET `position_x` = -7597.1000, `position_y` = -1092.0000, `position_z` = 269.4150 WHERE `guid` = 6940424;

-- Forgewright's Scepter (254659): was -7598.8 -1111.8, 3.8 yd off the marker
--   height from its own height, unchanged (moved 3.8 yd)
UPDATE `gameobject` SET `position_x` = -7595.1000, `position_y` = -1112.5000, `position_z` = 252.7670 WHERE `guid` = 6940234;

-- Half Buried Chest (518086): was -7480.7 -2278.0, 5.7 yd off the marker
--   height from its own height, unchanged (moved 5.7 yd)
UPDATE `gameobject` SET `position_x` = -7481.9000, `position_y` = -2272.4000, `position_z` = 233.5570 WHERE `guid` = 6940493;

-- Blackbreach Handaxe (686898): no marker of any page plots it at -7467.5 -1117.5
DELETE FROM `gameobject` WHERE `guid` = 6940123;

-- Darkest Night Ring (90288): no marker of any page plots it at -7505.8 -881.4
DELETE FROM `gameobject` WHERE `guid` = 6940310;

-- Taskmaster's Blade (254660): no marker of any page plots it at -7422.4 -1010.6
DELETE FROM `gameobject` WHERE `guid` = 6941041;

COMMIT;
