-- #12403: Brynja's Water Pouch (guid 6942484, entry 90640) floated 1.03 yd above bare ground beside the barrel in Coldridge Valley.
-- Place it on the top surface of Westfallbarrel01.m2 (z = 401.065), clear of Generallantern01.m2 on the same barrel.
UPDATE `gameobject`
SET `position_x` = -6161.09, `position_y` = 360.18, `position_z` = 401.065
WHERE `guid` = 6942484 AND `id` = 90640 AND `map` = 0
  AND `position_x` BETWEEN -6162.10 AND -6161.90
  AND `position_y` BETWEEN 359.20 AND 359.40
  AND `position_z` BETWEEN 401.05 AND 401.25;
