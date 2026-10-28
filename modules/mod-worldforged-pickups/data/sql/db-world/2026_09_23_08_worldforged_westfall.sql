-- ----------------------------------------------------------------------------
-- Worldforged pickups: Westfall, judged against the realm map marker by marker
-- ----------------------------------------------------------------------------
-- Every marker the map plots in this zone is paired with a pickup of the same object,
-- one marker to one pickup, by nearest standing.  A pickup more than half a yard off its
-- marker is moved onto it; a pickup that pairs with no marker of any page is a stray
-- placing and is removed.  Nothing was missing: every Westfall marker with an object of
-- ours behind it already had a pickup, after these moves.
--
-- Heights: the height the client recorded for that object at that spot, else the realm's
-- own recorded height when the ground agrees, else the floor the realm's own props share,
-- else the server's own terrain.  Nothing is chosen by hand.
--
-- The map also plots seven book/scroll/crystal fixtures of the realm's scroll family and
-- six "Worldforge Drops (N items)" cluster labels in this zone.  The fixtures' objects are
-- in the realm's own dump, but their loot tables exist in no source held here, so nothing
-- is invented for them; cluster labels are labels over drops, not placements.
--
-- Where the map plots an object on two pages (a zone label and its neighbour) with
-- coordinates that disagree by more than a few yards, and the realm's own record agrees
-- with one of them, the recorded spot is kept - Rower's Jerkin (marker 11.5 yd off) and
-- Madness Cursed Notes (marker 18.4 yd off) are the two in this zone.
--
-- Idempotent.  Apply to acore_world.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Skeleton Hand (90279): was -10562.5 266.2, 3.5 yd off the marker
--   height from its own height, unchanged (moved 3.5 yd)
UPDATE `gameobject` SET `position_x` = -10564.2000, `position_y` = 269.3000, `position_z` = 29.6310 WHERE `guid` = 6940931;

-- Sharp Bone Necklace (90285): was -10358.1 131.3, 15.6 yd off the marker
--   height from the server's own terrain.  The realm's recorded height for this object is
--   1.8, but that is 31 yd under the ground the rest of Raven Hill Cemetery stands on and
--   no source carries its x/y, so it is not used.
UPDATE `gameobject` SET `position_x` = -10372.9000, `position_y` = 136.3000, `position_z` = 33.3400 WHERE `guid` = 6940905;

-- Darkest Night Ring (90288): was -10313.1 363.6, 3.6 yd off the marker
--   height from its own height, unchanged (moved 3.6 yd)
UPDATE `gameobject` SET `position_x` = -10314.5000, `position_y` = 360.3000, `position_z` = 61.3220 WHERE `guid` = 6940309;

-- Forgotten Shipment (Soldier's Mail, 95807): was -9897.5 806.3, 5.4 yd off the marker
--   height from its own height, unchanged (moved 5.4 yd)
UPDATE `gameobject` SET `position_x` = -9902.3000, `position_y` = 808.8000, `position_z` = 23.3350 WHERE `guid` = 6940500;

-- People's Militia Stolen Badge (6940879): was -9842.7 1404.6, 2.1 yd off the marker
--   height from its own height, unchanged; the client recorded this object at exactly this
--   height within a yard of the marker
UPDATE `gameobject` SET `position_x` = -9843.3000, `position_y` = 1406.5000, `position_z` = 40.3400 WHERE `guid` = 6940879;

-- Drowned Man's Necklace (6940152): was -11518.7 607.2, 2.0 yd off the marker
--   height from its own height, unchanged (moved 2.0 yd)
UPDATE `gameobject` SET `position_x` = -11518.4000, `position_y` = 605.2000, `position_z` = 48.4700 WHERE `guid` = 6940152;

-- Discarded Junk (Haren's Tankard, 6940361): was -11019.5 180.0, 1.8 yd off the marker
--   height from its own height, unchanged (moved 1.8 yd)
UPDATE `gameobject` SET `position_x` = -11019.1000, `position_y` = 181.8000, `position_z` = 27.9600 WHERE `guid` = 6940361;

-- Rugged Leather Runners (254354): was -11355.8 -249.8, 1.3 yd off the marker
--   height from its own height, unchanged (moved 1.3 yd)
UPDATE `gameobject` SET `position_x` = -11355.1000, `position_y` = -248.6000, `position_z` = 47.6700 WHERE `guid` = 6940983;

-- Field Boots (95778): was -9830.5 919.6, 1.3 yd off the marker
--   height from its own height, unchanged (moved 1.3 yd)
UPDATE `gameobject` SET `position_x` = -9831.6000, `position_y` = 920.1000, `position_z` = 31.4300 WHERE `guid` = 6940470;

-- Misplaced Pitchfork (515224): no marker of any page plots it at -9876.2 1440.3.  Its
-- object already stands at every spot the map records for it, so this is a second placing.
DELETE FROM `gameobject` WHERE `guid` = 6940755;

-- Quarry Sledge (95785): no marker of any page plots it at -10468.5 1944.0.  Same.
DELETE FROM `gameobject` WHERE `guid` = 6940915;

COMMIT;
