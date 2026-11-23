-- #12556: Worldforged pickup guid 6942210: the pickup floated 1.33 yd above the ground (measured spawn_ground_gap);
-- lower it to the ground
UPDATE `gameobject` SET `position_z` = 812.135
WHERE `guid` = 6942210 AND `id` = 518562 AND `map` = 1
  AND `position_x` BETWEEN 6118.15 AND 6118.25
  AND `position_y` BETWEEN -5082.95 AND -5082.85
  AND `position_z` BETWEEN 813.416 AND 813.516;
