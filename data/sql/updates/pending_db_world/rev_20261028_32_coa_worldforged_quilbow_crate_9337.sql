-- Worldforged Quilbow (Durotar, guid 6942054) kept the dump sighting's z after the realm-map pass moved
-- its xy 6.4 yd up a steep slope, so the crate ended up 1.92 yd under the Orccrate02 top it stands on
-- (#9337). Restore it to the crate top, confirmed as real ground by the harness's own height probe.
UPDATE `gameobject` SET `position_z` = 59.375
WHERE `guid` = 6942054 AND `id` = 95625 AND `map` = 1
  AND `position_x` BETWEEN 88.5 AND 89.5 AND `position_y` BETWEEN -4544.6 AND -4543.6
  AND ABS(`position_z` - 57.451) < 0.01;
