-- Worldforged Dunemaul Crate (pickup 6941658, Dunemaul Compound, Tanaris) floated 1.22 yd above the ground at its
-- x/y (#11612). The ground there measures 11.282, so lower the pickup onto it.
UPDATE `gameobject` SET `position_z` = 11.282
WHERE `guid` = 6941658 AND `id` = 515772 AND `map` = 1
  AND `position_x` BETWEEN -8278.6 AND -8278.4 AND `position_y` BETWEEN -2909.1 AND -2908.9
  AND `position_z` BETWEEN 12.4 AND 12.6;
