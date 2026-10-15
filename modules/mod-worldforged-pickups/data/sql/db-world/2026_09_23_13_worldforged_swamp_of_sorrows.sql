-- ----------------------------------------------------------------------------
-- Worldforged pickups: Swamp of Sorrows, judged against the realm map marker by marker
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
-- Two things this pass found and left alone:
--
--   * the page's marker 'Paladin Corpse' names a chest the realm really had 0.7 yd from
--     it (object 93024, six sightings, filed under DeadwindPass and SwampOfSorrows) but
--     which this world does not carry, and Ascension's own record of it is the invisible
--     placeholder model with no loot pin naming anything it held.  Nothing is invented.
--   * the marker 'Travel Cloak' names nothing in any source in hand: no object, no loot
--     pin, and no item of that name is handed out by any object, creature or reference
--     table in this world.
--
-- As in the zone before it, the map lists some of its markers on two pages and each page
-- projects its own spot for them: eleven of this zone's pickups are the second listing -
-- six across the Deadwind Pass border about 1,320 yd north, three in the Badlands some
-- 5,100 yd east, one in Westfall 4,410 yd away and one in Mulgore 9,154 yd away.  The
-- realm's own pins corroborate the other listing in each case; the map plots both, so
-- both stand.  Two pickups (Arcane Tinged Water, Sentinel Wrap) have no corroboration at
-- either end and stand because the page plots them.

START TRANSACTION;

COMMIT;
