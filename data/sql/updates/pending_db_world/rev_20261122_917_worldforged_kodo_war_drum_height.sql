-- #12616: Worldforged pickup guid 6941893: the pickup floated 1.07 yd above the ground (measured spawn_ground_gap);
-- lower it to the ground
UPDATE `gameobject` SET `position_z` = -50.933
WHERE `guid` = 6941893 AND `id` = 515533 AND `map` = 1
  AND `position_x` BETWEEN -5863.45 AND -5863.35
  AND `position_y` BETWEEN -3425.05 AND -3424.95
  AND `position_z` BETWEEN -49.911 AND -49.811;
