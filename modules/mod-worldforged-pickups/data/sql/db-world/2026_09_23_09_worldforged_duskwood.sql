-- ----------------------------------------------------------------------------
-- Worldforged pickups: Duskwood, judged against the realm map marker by marker
-- ----------------------------------------------------------------------------
-- Each marker on the zone's realm map page is given the object it means: the object of that
-- name in this world; the object whose loot row carries that name as its item (the map names
-- some markers after the item, e.g. 'Lohgan's Best Bag' for the object 'Spare Bag'); or the
-- object the archive's loot pin at that spot names.
--
-- A pickup of that object within 3 yd means the marker stands.  Farther out the nearest pickup
-- is moved onto the marker - unless it already honours a marker of its own object (usually on a
-- neighbouring zone's page) while standing exactly where the realm itself recorded the object,
-- in which case the two markers are one placement the map recorded twice and nothing moves.
-- There are nine such markers in this zone: Darkest Night Loop (3.6 yd), Raven Hill Backscratcher
-- (3.5), Honed Steel Axe (4.8), Ruby Skeletal Ring (4.2), Venom Sample (5.4), The Jitters (6.2),
-- Nightshot (6.4), Vul'Gol Torch (7.3) and Poisoned Pendant (15.6).
--
-- Four markers have no object behind them in this world: the realm's own dump carries them as
-- worldforged chests, but their loot tables exist in no source held here, and their own items
-- name them as the realm's scroll family - Omen of Doom (whose item is Mystic Scroll: Omen of
-- Doom), Whispering Book, Arcane Crystal and Scroll of Curses.  Nothing is invented for them.
--
-- One marker, 'Discarded Junk', is a worldforged chest the realm recorded as its own entry
-- (254693, display 1010201).  This world carries the same placement as entry 1345067 (named
-- after the item it hands out, Haren's Tankard, display 184947) standing 1.8 yd from the marker
-- and handing out exactly the item the pins recorded there, so the marker stands; the entry and
-- display it uses are the ones this world has always had.
--
-- Idempotent.  Apply to acore_world.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Murloc Voodoo Toy (90228): was -9929.4 -1170.6, 10.1 yd off the marker
--   height from the realm's own recorded height (2 yd from here)
UPDATE `gameobject` SET `position_x` = -9924.8000, `position_y` = -1161.6000, `position_z` = 23.0430 WHERE `guid` = 6940788;

-- Dark Scythe (254494): was -10449.5 -1733.0, 13.0 yd off the marker
--   height from the realm's own recorded height (1 yd from here)
UPDATE `gameobject` SET `position_x` = -10452.2000, `position_y` = -1720.3000, `position_z` = 85.7820 WHERE `guid` = 6940115;

COMMIT;
