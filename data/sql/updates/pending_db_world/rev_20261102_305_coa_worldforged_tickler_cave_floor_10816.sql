-- The Tickler pickup (guid 6942304) stood 1.55 yd under its cave floor, so only its sparkles showed (#10816).
-- Set it on the floor height measured by the harness at its position.
UPDATE `gameobject` SET `position_z` = 14.88
WHERE `guid` = 6942304 AND `id` = 515571 AND `map` = 1
  AND `position_x` BETWEEN -5614.7 AND -5614.5
  AND `position_y` BETWEEN -1608.8 AND -1608.6
  AND ABS(`position_z` - 13.326) < 0.01;
