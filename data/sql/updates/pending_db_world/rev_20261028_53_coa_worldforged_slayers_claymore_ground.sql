-- Worldforged Slayer's Claymore (#9151): the Stuck Sword pickup (guid 6942199) kept the realm
-- sighting's own stored height, 1.14 yd above the stock terrain in the Valley of Trials. Restore
-- the terrain height so the sword stands in the ground, not hovering above it.
UPDATE `gameobject` SET `position_z` = 56.38
WHERE `guid` = 6942199 AND `id` = 254520 AND `map` = 1
  AND `position_x` BETWEEN -363.7 AND -362.7 AND `position_y` BETWEEN -4289.4 AND -4288.4
  AND ABS(`position_z` - 57.522) < 0.01;
