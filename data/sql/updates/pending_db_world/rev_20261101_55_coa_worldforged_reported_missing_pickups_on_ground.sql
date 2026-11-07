-- Worldforged pickups reported missing or under the ground, set on the ground the server finds above them (Map::GetHeight from above, the nearby_gameobject_ground_offset metric).
-- Gorlash's Seaweed Salad and Markri Turret go back to its 2026_09_23_05_worldforged_map height, which 2026_09_23_06_worldforged_recorded_heights had lowered 7.5 and 7.7 yd under that surface.
UPDATE `gameobject` SET `position_z` = -52.149 WHERE `guid` = 6941608 AND `id` = 515509 AND ABS(`position_z` - -53.102) < 0.01;  -- Darkcloud Braid (#10337), was 0.95 yd under the ground
UPDATE `gameobject` SET `position_z` = 80.660 WHERE `guid` = 6940538 AND `id` = 90508 AND ABS(`position_z` - 79.515) < 0.01;  -- Ghoulbane Gauntlets (#10305), was 1.14 yd under the ground
UPDATE `gameobject` SET `position_z` = 123.173 WHERE `guid` = 6940158 AND `id` = 95798 AND ABS(`position_z` - 121.606) < 0.01;  -- Bloodthread Leggings (#10250), was 1.57 yd under the ground
UPDATE `gameobject` SET `position_z` = 256.446 WHERE `guid` = 6941957 AND `id` = 517223 AND ABS(`position_z` - 254.658) < 0.01;  -- Minstrel's Magic (#10368), was 1.79 yd under the ground
UPDATE `gameobject` SET `position_z` = 29.366 WHERE `guid` = 6942420 AND `id` = 254558 AND ABS(`position_z` - 26.646) < 0.01;  -- Wild Longbow (#10139), was 2.72 yd under the ground
UPDATE `gameobject` SET `position_z` = 12.446 WHERE `guid` = 6940562 AND `id` = 254350 AND ABS(`position_z` - 4.959) < 0.01;  -- Gorlash's Seaweed Salad (#10154), was 7.49 yd under the ground
UPDATE `gameobject` SET `position_z` = -56.014 WHERE `guid` = 6941718 AND `id` = 515502 AND ABS(`position_z` - -56.299) < 0.01;  -- Failed Parachute (#10316), was 0.29 yd under the ground
UPDATE `gameobject` SET `position_z` = 17.364 WHERE `guid` = 6940910 AND `id` = 95725 AND ABS(`position_z` - 15.491) < 0.01;  -- Pristine Tethis Feather (#10002), was 1.87 yd under the ground
UPDATE `gameobject` SET `position_z` = -197.886 WHERE `guid` = 6942005 AND `id` = 95934 AND ABS(`position_z` - -198.349) < 0.01;  -- One Ring to Flame Them All (#10026), was 0.46 yd under the ground
UPDATE `gameobject` SET `position_z` = 92.370 WHERE `guid` = 6941951 AND `id` = 254458 AND ABS(`position_z` - 84.636) < 0.01;  -- Markri Turret (#10037), was 7.73 yd under the ground
UPDATE `gameobject` SET `position_z` = 108.029 WHERE `guid` = 6942315 AND `id` = 97112 AND ABS(`position_z` - 106.887) < 0.01;  -- Thornweaver Mace (#10076), was 1.14 yd under the ground
