-- Worldforged Forbidding Locker (pickup 6941077, Swamp of Sorrows, #11726) floated 0.59 yd over the ground: the
-- realm-map pass moved its x/y 4.4 yd and kept the first-pass height. New z: the server's ground height there.
UPDATE `gameobject` SET `position_z` = 2.313
WHERE `guid` = 6941077 AND `id` = 254386 AND `map` = 0
  AND `position_x` BETWEEN -11100.11 AND -11100.09
  AND `position_y` BETWEEN -3834.91 AND -3834.89
  AND `position_z` BETWEEN 2.89 AND 2.91;
