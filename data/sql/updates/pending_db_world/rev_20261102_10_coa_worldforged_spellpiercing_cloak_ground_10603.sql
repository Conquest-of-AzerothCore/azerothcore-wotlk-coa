-- Worldforged Spellpiercing Cloak crate (#10603, guid 6941125) floated 0.69 yd above the Badlands terrain
-- after the recorded-height pass; the terrain under it is 244.555.
UPDATE `gameobject` SET `position_z` = 244.555
WHERE `guid` = 6941125 AND `id` = 518055 AND `map` = 0
  AND `position_x` BETWEEN -7166.2 AND -7165.2 AND `position_y` BETWEEN -3347.9 AND -3346.9
  AND `position_z` BETWEEN 245.2 AND 245.3;
