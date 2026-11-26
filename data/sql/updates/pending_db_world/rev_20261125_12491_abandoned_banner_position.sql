-- Worldforged Abandoned Banner (object 95628, guid 6942059), Echo Isles, Durotar (#12491): the realm-map pass moved
-- the pickup 14.5 yd off the Stranglethornruins06.m2 ruins onto the low beach (-799.8, -5399.2), and
-- rev_20261006_65 then dropped its z to bare ground (0.0208), sinking the hanging cloak/banner into the sand.
-- Restore first-pass row 6901076 (2026_09_16_00, the realm dump spot) with its recorded height.
UPDATE `gameobject` SET `position_x` = -794.285, `position_y` = -5385.820, `position_z` = 4.801
WHERE `guid` = 6942059 AND `id` = 95628 AND `map` = 1
  AND `position_x` BETWEEN -799.85 AND -799.75
  AND `position_y` BETWEEN -5399.25 AND -5399.15
  AND `position_z` BETWEEN 0.01 AND 0.03;
