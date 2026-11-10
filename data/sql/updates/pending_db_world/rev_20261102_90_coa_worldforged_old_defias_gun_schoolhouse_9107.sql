-- Worldforged Old Defias Gun (Moonbrook Schoolhouse, guid 6940829) was placed in game on the schoolhouse
-- floor at (-10949.214844, 1568.400391, 46.866566), then
-- rev_20261014_95_worldforged_lootcollector_alignment.sql moved it 8.7 yd to (-10952.1, 1576.51, 45.975),
-- onto terrain 1 yd below the schoolhouse floor, with no floor or roof over it. Restore the in-game placement
-- (#9107).
UPDATE `gameobject` SET `position_x` = -10949.214844, `position_y` = 1568.400391, `position_z` = 46.866566
WHERE `guid` = 6940829 AND `id` = 90253 AND `map` = 0
  AND `position_x` BETWEEN -10952.6 AND -10951.6 AND `position_y` BETWEEN 1576.0 AND 1577.0
  AND ABS(`position_z` - 45.975) < 0.01;
