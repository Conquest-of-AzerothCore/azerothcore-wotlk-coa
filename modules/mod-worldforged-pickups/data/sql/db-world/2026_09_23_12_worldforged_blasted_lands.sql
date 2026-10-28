-- ----------------------------------------------------------------------------
-- Worldforged pickups: Blasted Lands, judged against the realm map marker by marker
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
-- Two things this pass found and left alone, both of them properties of the realm map
-- rather than of this world:
--
--   * the map lists 202 of its markers on two zone pages, with the same top/left on both,
--     so each page projects its own world spot for them.  Twenty of this zone's pickups
--     are that second listing - an object whose other listing stands in the Badlands some
--     5,000 yd east (14 of them), across the Deadwind Pass border about 1,300 yd north (4),
--     or in Mulgore, the Western Plaguelands and Teldrassil (1 each).  The realm's own
--     loot pins corroborate one of the two spots for each; the map plots both, so both
--     stand, and nothing here moves them.
--   * three of the page's markers name objects the realm has and this world does not
--     (Hanging Ogre Scraps, Monolith of Earth, Charred Staff) and two name nothing in any
--     source in hand (Capacitor Totem, Arrow of Binding).  Each of the three realm objects
--     was recorded by the realm in the Badlands, and the page lists two of them at the very
--     same top/left its Badlands page uses, so no pickup is invented for them here.

START TRANSACTION;

COMMIT;
