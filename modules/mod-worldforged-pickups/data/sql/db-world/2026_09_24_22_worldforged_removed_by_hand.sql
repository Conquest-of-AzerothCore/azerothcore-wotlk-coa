-- ----------------------------------------------------------------------------
-- Worldforged pickups: the placements deleted by hand
-- ----------------------------------------------------------------------------
-- Walking the Elwynn and Northshire sheets row by row, the realm's own author deleted three rows
-- from the workbook.  Two of them are already gone from the world, because the same saves that
-- produced the rest of the final pass deleted those guids in the editor
-- (`2026_09_24_20_worldforged_authored_in_game_final.sql`):
--
--   * The Wanderer's Stirring Rod, guid 6941224 (the object's other placings stand: 6941223 in
--     Westfall and 6942480 in Eversong Woods);
--   * Thunder Falls Finest Gun Selection, guid 6941243 (the duplicate of 6941240, which stands).
--
-- The third was a placement no authored save ever touched, and it is removed here:
--
--   * **Loose Stone, guid 6940971** at (-10006.6, 321.8) - the object that hands out Robe of Woven
--     Dreams (entry 254398, item 354263), standing on the Westfall side of the border the realm
--     map files under its Westfall page while the server's own area table calls the spot the
--     Stonefield Farm, which is why it was listed on the Elwynn sheet.  The item keeps its other
--     placings: the same object stands in the Swamp of Sorrows (6940970, -10017.8 -3988.4) and on
--     Sunstrider Isle (6942474, 10556.0 -6615.3), so no item loses its carrier.
--
-- Nothing else moves: this file only takes these placements out of the world.
--
-- Idempotent: one DELETE keyed on the guid.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Loose Stone (254398), Robe of Woven Dreams' own object, on the Westfall side of the border
DELETE FROM `gameobject` WHERE `guid` = 6940971;

COMMIT;
