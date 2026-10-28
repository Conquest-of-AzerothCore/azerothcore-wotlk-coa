-- Worldforged Salvaged Cannon (#9128): the Discarded Hand Cannon pickup (guid 6940999) stands at
-- the realm-map marker XY in Dun Morogh, 0.52 yd under the terrain there. Restore its stored height
-- to the terrain.
UPDATE `gameobject` SET `position_z` = 415.04
WHERE `guid` = 6940999 AND `id` = 95617 AND `map` = 0
  AND `position_x` BETWEEN -6044.3 AND -6043.3 AND `position_y` BETWEEN -217.3 AND -216.3
  AND ABS(`position_z` - 414.517) < 0.01;
