-- Worldforged Butchery Blade (Tirisfal Glades, guid 6940210) was hand-authored in game at
-- (2485.38, 21.7031, 27.6361), a torch-and-skeleton scene 0.59 yd above terrain, then
-- rev_20261014_95_worldforged_lootcollector_alignment.sql overwrote it with a terrain-fallback spot
-- 13.2 yd away in a ditch. Restore the authored, in-game verified spot (#9373).
UPDATE `gameobject` SET `position_x` = 2485.38, `position_y` = 21.7031, `position_z` = 27.6361
WHERE `guid` = 6940210 AND `id` = 95805 AND `map` = 0
  AND `position_x` BETWEEN 2480.8 AND 2481.8 AND `position_y` BETWEEN 9.3 AND 10.3
  AND ABS(`position_z` - 20.165) < 0.01;
