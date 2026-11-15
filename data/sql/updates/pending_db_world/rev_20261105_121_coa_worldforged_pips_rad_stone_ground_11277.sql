-- Worldforged Pip's Rad Stone (#11277, #11171, guid 6942028) sat 4.68 yd under the mound it stands on in the
-- Shimmering Flats crater; the ground under it is -92.011.
UPDATE `gameobject` SET `position_z` = -92.011
WHERE `guid` = 6942028 AND `id` = 515531 AND `map` = 1
  AND `position_x` BETWEEN -5793.1 AND -5792.9 AND `position_y` BETWEEN -3904.3 AND -3904.1
  AND `position_z` BETWEEN -96.7 AND -96.6;
