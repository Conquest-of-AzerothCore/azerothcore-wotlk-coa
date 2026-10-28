-- ----------------------------------------------------------------------------
-- Worldforged pickups: eight spawns standing where the object was never recorded
-- ----------------------------------------------------------------------------
-- The worldforge map lists each of these objects elsewhere, and the realm already stands
-- every one of them at exactly that recorded spot. The spawns removed here are a second
-- placing of the same object inside Elwynn Forest / Northshire, at a spot no record of the
-- object names (several of them left hanging high on a hillside):
--
--   Crystallized Shield            (95747)   keeps its place in Stranglethorn Vale
--   Gareks Personal Belongings     (518045)  keeps its places in the Badlands and the
--                                            Blasted Lands
--   Tattered Goblin Cargo Sack     (97131)   keeps its place in Stranglethorn Vale
--   Ancient Relic                  (518054)  keeps its places in the Blasted Lands and
--                                            the Badlands
--   Glinting Silt-Encrusted
--     Necklace                     (95729)   keeps its place in Stranglethorn Vale
--   Shoulderguards of the
--     Ancient Prophet              (254374)  keeps its place in the Swamp of Sorrows
--   Cursed Branch                  (254491)  keeps its places in the Deadwind Pass, the
--                                            Swamp of Sorrows and Mulgore
--   The Rock Binder                (518000)  keeps its places in the Blasted Lands and the
--                                            Badlands
--
-- Idempotent: keyed by guid. Apply to acore_world.
-- ----------------------------------------------------------------------------

START TRANSACTION;

DELETE FROM `gameobject` WHERE `guid` IN
  (6940283, 6940524, 6941096, 6941161, 6940181, 6940677, 6940874, 6941218);

COMMIT;
