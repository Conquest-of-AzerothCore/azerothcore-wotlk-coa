-- Worldforged Owlbeast Pantaloons (Cenarion Crate, pickup 6942016, Hidden Grove, Winterspring) sat 1.68 yd under
-- the ground at its x/y, 0.03 yd from a model (#11360). The ground the reporter stood on at
-- (7693.353, -4797.419) measures 697.28, so move the crate there.
UPDATE `gameobject` SET `position_x` = 7693.353, `position_y` = -4797.419, `position_z` = 697.28
WHERE `guid` = 6942016 AND `id` = 96225 AND `map` = 1
  AND `position_x` BETWEEN 7690.9 AND 7691.1 AND `position_y` BETWEEN -4794.1 AND -4793.9
  AND `position_z` BETWEEN 697 AND 697.04;
