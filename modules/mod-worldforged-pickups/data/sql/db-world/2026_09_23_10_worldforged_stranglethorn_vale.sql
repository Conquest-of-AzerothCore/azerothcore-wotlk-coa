-- ----------------------------------------------------------------------------
-- Worldforged pickups: Stranglethorn Vale, judged against the realm map marker by marker
-- ----------------------------------------------------------------------------
-- Each marker on the zone's realm map page is given the object it means: the object of that
-- name in this world; the object whose loot row carries that name as its item (the map names
-- some markers after the item, e.g. 'Thunder Fur Cloak' for the object 'Gregan Tanning Rack');
-- or the object the archive's loot pin at that spot names.
--
-- Of the page's 98 markers: 90 are real placements, 4 are the realm's worldforged scroll chests
-- (Priestess Cache, Beating Heart, Armed Trap, Mysterious Pirate Cache) whose objects are held
-- here but whose loot is a Mystic Scroll - left out, like every other scroll chest; 3 name
-- nothing in this world (Mysterious Cauldron, Demonic Skull, Skull Crusher - the last of which
-- is likewise a scroll chest, its loot being Mystic Scroll: Skull Crusher); and 1 is the
-- 'Worldforge Drops' cluster label.  Nothing is invented for them.
--
-- 89 of the 90 placements already stand on their marker.  One did not.  Idempotent.  Apply to
-- acore_world.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Ancient Sea-dweller Charm (515598): was 1845.4 1614.3 95.6, 14719.9 yd off the marker.
--   The realm's own sightings of this chest put it in the water off Booty Bay
--   (-12809.6 421.7, recorded height 7.2), which is 20.9 yd from the map's marker and 9 yd above
--   the sea floor the terrain reader finds there, so the recorded height is not used; the marker
--   at (-12827.1 433.6) takes the terrain, 2.4 yd under the surface.  The archive's own loot pin
--   for the item (9 records across 6 realms) sits 4.7 yd from that marker.
UPDATE `gameobject` SET `position_x` = -12827.1000, `position_y` = 433.6000, `position_z` = -2.4149 WHERE `guid` = 6940742;

-- Rugged Leather Runners (254354): a second placing with nothing behind it.
--   The realm recorded this object at one spot only, -11354.7 -248.7 at height 47.7, and the
--   map carries the matching marker on its Duskwood and Westfall pages.  Both are already served
--   by guid 6940983.  This spawn at -11338.2 -268.2 stands 22.8 yd away at height 83 with no
--   marker of its name anywhere on the map and no record in any source held, so it goes.
DELETE FROM `gameobject` WHERE `guid` = 6940942;

COMMIT;
