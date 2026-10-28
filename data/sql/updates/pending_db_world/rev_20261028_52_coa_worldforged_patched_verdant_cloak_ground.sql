-- Worldforged Patched Verdant Cloak (#9102): the Hanged Pelt pickup (guid 6942022) stands at the
-- realm-map marker XY in Teldrassil, 1.40 yd under the terrain there. Restore its stored height to
-- the terrain.
UPDATE `gameobject` SET `position_z` = 1323.52
WHERE `guid` = 6942022 AND `id` = 90551 AND `map` = 1
  AND `position_x` BETWEEN 10031.7 AND 10032.7 AND `position_y` BETWEEN 300.7 AND 301.7
  AND ABS(`position_z` - 1322.12) < 0.01;
