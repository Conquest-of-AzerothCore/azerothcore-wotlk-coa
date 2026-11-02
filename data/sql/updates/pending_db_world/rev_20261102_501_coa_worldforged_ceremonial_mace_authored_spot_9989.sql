-- Worldforged Ceremonial Mace (Tirisfal Glades, guid 6940229) was verified in game at
-- (2043.62, -521.955, 44.1577) beside Invincible's Gravestone (2026_09_26_63_worldforged_tirisfal_final.sql),
-- then rev_20261014_95_worldforged_lootcollector_alignment.sql overwrote it with a spot 10.4 yd from the gravestone.
-- Restore the verified spot (#9989).
UPDATE `gameobject` SET `position_x` = 2043.62, `position_y` = -521.955, `position_z` = 44.1577
WHERE `guid` = 6940229 AND `id` = 515372 AND `map` = 0
  AND `position_x` BETWEEN 2034.7 AND 2035.7 AND `position_y` BETWEEN -528.3 AND -527.3
  AND ABS(`position_z` - 44.25) < 0.01;
