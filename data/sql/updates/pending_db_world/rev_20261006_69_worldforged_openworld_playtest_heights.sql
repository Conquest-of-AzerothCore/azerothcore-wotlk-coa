-- ----------------------------------------------------------------------------
-- Worldforged pickups: second playtest pass on open-world heights (#4984)
-- ----------------------------------------------------------------------------
-- In-game retest of 2026_10_06_68 flagged six pins. This file is additive; _65.._68 stay as shipped.
-- Five UPDATEs: four Z only, and Spare Boots also moves XY onto the flat ledge above its slope.
-- Orientation and entry are untouched.
--
-- Not changed (no authored or neighbour evidence for a move, see PLAYTEST_REPASS2_SUMMARY.txt):
--   6941751 Fragment of K'aresh: Z already sits on the ADT; the Mulgore scaffolds and Spirit Healer are ~45 yd away.
--   Deserter's Last Resort stays where it is in XY: stock guards stand at the same floor height on the surrounding
--   platform, and the nearest stair is ~20 yd away with nothing tying the pickup to it.
START TRANSACTION;

-- 6941652 Dropped Shield: 121.053 -> 122.000. Still merged into the wooden bridge planks; ADT under-reads the deck (116.05).
UPDATE `gameobject` SET `position_z` = 122.000 WHERE `guid` = 6941652;

-- 6941950 Spare Boots: (1103.2, -4976.2, 18.603) -> (1107.0, -4971.5, 21.280). Pin sat in the steep face below the ledge
-- the player stands on. The ADT is a flat 21.2-21.3 plateau (3 yd ring slope 0.2) about 5.5 yd up-slope.
UPDATE `gameobject` SET `position_x` = 1107.000, `position_y` = -4971.500, `position_z` = 21.280 WHERE `guid` = 6941950;

-- 6942271 Sunchaser Blade: 17.156 -> 16.650. Floated over the grass; ADT here is 16.63, flat.
UPDATE `gameobject` SET `position_z` = 16.650 WHERE `guid` = 6942271;

-- 6942141 Scarlet Blunderbuss: 1332.250 -> 1330.900. Rack base stood at chest height; ADT is 1331.51 but the nearest stock
-- creatures stand at 1330.8-1330.9, so the rack is dropped below the ADT reading to land on the grass.
UPDATE `gameobject` SET `position_z` = 1330.900 WHERE `guid` = 6942141;

-- 6941629 Deserter's Last Resort: 46.544 -> 46.300. Slightly floating. 46.58 is the platform floor (a dozen stock guards stand
-- at 46.47-46.58 around it); the necklace model pivot sits above the floor, so it is lowered a quarter yard.
UPDATE `gameobject` SET `position_z` = 46.300 WHERE `guid` = 6941629;

COMMIT;
