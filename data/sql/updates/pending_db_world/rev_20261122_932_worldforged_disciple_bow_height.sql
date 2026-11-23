-- #12909: Worldforged pickup guid 6941641: the pickup floated 3.11 yd above the tower floor (measured
-- spawn_ground_gap); lower it to the floor
UPDATE `gameobject` SET `position_z` = 1438.05
WHERE `guid` = 6941641 AND `id` = 520069 AND `map` = 1
  AND `position_x` BETWEEN 10744.650 AND 10744.750
  AND `position_y` BETWEEN 589.540 AND 589.640
  AND `position_z` BETWEEN 1441.100 AND 1441.200;
