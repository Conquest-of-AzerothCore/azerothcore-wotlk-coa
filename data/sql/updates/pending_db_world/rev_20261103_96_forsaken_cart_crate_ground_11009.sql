-- Forsaken Cart Crate (#11009, guid 6940804) floated 2.19 yd above the floor of The Grizzled Den; the floor under it
-- is 353.796.
UPDATE `gameobject` SET `position_z` = 353.796
WHERE `guid` = 6940804 AND `id` = 517352 AND `map` = 0
  AND `position_x` BETWEEN -5514.6 AND -5513.6 AND `position_y` BETWEEN -300.0 AND -299.0
  AND `position_z` BETWEEN 355.9 AND 356.1;
