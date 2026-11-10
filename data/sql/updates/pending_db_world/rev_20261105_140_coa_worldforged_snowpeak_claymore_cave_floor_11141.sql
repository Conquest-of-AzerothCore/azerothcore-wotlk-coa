-- Worldforged Snowpeak Claymore (#11141, guid 6942208) floated 9.15 yd above the Winterspring cave floor; the ground
-- under it is 595.049.
UPDATE `gameobject` SET `position_z` = 595.049
WHERE `guid` = 6942208 AND `id` = 518586 AND `map` = 1
  AND `position_x` BETWEEN 5851.2 AND 5851.4 AND `position_y` BETWEEN -4086.2 AND -4086.0
  AND `position_z` BETWEEN 604.1 AND 604.3;
