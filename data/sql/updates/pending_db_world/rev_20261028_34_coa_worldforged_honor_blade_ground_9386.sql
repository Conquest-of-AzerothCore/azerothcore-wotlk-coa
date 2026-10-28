-- Worldforged Honor Blade (The Barrens, guid 6941840) floats 1.14 yd above the terrain; the earlier
-- open-world float-height pass only snapped rows more than 2 yd off, leaving this one midair (#9386).
UPDATE `gameobject` SET `position_z` = 91.83
WHERE `guid` = 6941840 AND `id` = 90302 AND `map` = 1
  AND `position_x` BETWEEN -45.5 AND -44.5 AND `position_y` BETWEEN -1414.1 AND -1413.1
  AND ABS(`position_z` - 92.973) < 0.01;
