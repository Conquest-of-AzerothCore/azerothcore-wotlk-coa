-- Worldforged Silky Spaulders (Duskwood, guid 6941083) was hand-authored in game inside the Naraxis cave at
-- (-10569.523438, -1504.900391, 95.118439), then rev_20261014_95_worldforged_lootcollector_alignment.sql
-- lifted it to z 124.023, 29 yd above the cave floor. Restore the authored, in-game verified spot (#9317).
UPDATE `gameobject` SET `position_x` = -10569.523438, `position_y` = -1504.900391, `position_z` = 95.118439
WHERE `guid` = 6941083 AND `id` = 95823 AND `map` = 0
  AND ABS(`position_x` + 10562.6) < 0.01 AND ABS(`position_y` + 1495.61) < 0.01
  AND ABS(`position_z` - 124.023) < 0.01;
