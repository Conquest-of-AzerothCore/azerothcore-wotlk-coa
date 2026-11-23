-- #13135: remove the Vermin Cane copy in Searing Gorge (moved there by rev_20261016_90 from a LootCollector find),
-- keep 6941297 in the Loch Modan kobold mine
DELETE FROM `gameobject`
WHERE `guid` = 6941298 AND `id` = 517342 AND `map` = 0
  AND `position_x` BETWEEN -6570.550 AND -6570.450
  AND `position_y` BETWEEN -913.750 AND -913.650;
