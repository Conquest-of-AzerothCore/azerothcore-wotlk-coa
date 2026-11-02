-- Worldforged Volkmar's Enchanting Rod (#10625, guid 6970008) was placed at the terrain height under the
-- Deadwood Pass house by the LootCollector alignment; the house floor above it is at 48.294.
UPDATE `gameobject` SET `position_z` = 48.294
WHERE `guid` = 6970008 AND `id` = 9900012 AND `map` = 0
  AND `position_x` BETWEEN -11113.9 AND -11112.9 AND `position_y` BETWEEN -2083.8 AND -2082.8
  AND `position_z` BETWEEN 47.0 AND 47.2;
