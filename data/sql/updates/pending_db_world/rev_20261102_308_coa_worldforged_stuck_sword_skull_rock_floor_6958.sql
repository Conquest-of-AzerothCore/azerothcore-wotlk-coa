-- The Stuck Sword pickup in Skull Rock (guid 6942196) floated 3.39 yd above the cave floor (#6958).
-- Set it on the floor height measured by the harness at its position.
UPDATE `gameobject` SET `position_z` = 1.52
WHERE `guid` = 6942196 AND `id` = 95646 AND `map` = 1
  AND `position_x` BETWEEN 1465.2 AND 1465.4
  AND `position_y` BETWEEN -4702.0 AND -4701.8
  AND ABS(`position_z` - 4.909) < 0.01;
