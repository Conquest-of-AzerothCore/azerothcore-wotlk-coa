-- Worldforged Ringo's Star (#11226, guid 6942091) hovered 2.62 yd above the Fire Plume Ridge cave floor; the ground
-- under it is -232.354.
UPDATE `gameobject` SET `position_z` = -232.354
WHERE `guid` = 6942091 AND `id` = 95935 AND `map` = 1
  AND `position_x` BETWEEN -7201.8 AND -7201.6 AND `position_y` BETWEEN -1394.3 AND -1394.1
  AND `position_z` BETWEEN -229.8 AND -229.6;
