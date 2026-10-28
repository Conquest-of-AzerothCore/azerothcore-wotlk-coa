-- ----------------------------------------------------------------------------
-- Worldforged pickups: Barrel Smasher, one placement and not two
-- ----------------------------------------------------------------------------
-- Elwynn Forest stood the Rock Smasher - the object that hands out Barrel Smasher - twice: the
-- placement the realm map records for it, guid 6940108 at (-9003.9, 112.3, 195.0), and the one the
-- realm's own author placed by hand in the map editor, guid 6960008 at (-9067.1, 156.6, 114.8),
-- 77 yd away and 80 yd lower.  The hand-placed one is the placement that is final, and the map
-- pass's is removed here:
--
--   * 6960008 (entry 95655) stands where the author put it, with the position and rotation the
--     editor itself emitted, and keeps its loot row - it is the zone's Barrel Smasher.
--   * 6940108 (entry 95655) is deleted.  The object, its template and its loot row are untouched;
--     this file only takes the second placement out of the world.
--
-- Idempotent: one DELETE keyed on the guid.
-- ----------------------------------------------------------------------------

START TRANSACTION;

DELETE FROM `gameobject` WHERE `guid` = 6940108;

COMMIT;
