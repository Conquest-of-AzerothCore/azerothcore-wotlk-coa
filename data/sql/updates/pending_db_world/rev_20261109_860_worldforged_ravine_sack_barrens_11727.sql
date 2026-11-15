-- The Pillaged Sack (Ravine Sack pickup, object 95644) also stood in the Barrens at (-346.9, -2342.7), the
-- same map coordinates (49, 29) as its Durotar spawn. The Ascension sidekick snapshot lists Durotar only (#11727).
-- Remove the Barrens copy, guid 6942067; the Durotar spawn 6942068 stays.
DELETE FROM `gameobject`
WHERE `guid` = 6942067 AND `id` = 95644 AND `map` = 1
  AND `position_x` BETWEEN -346.91 AND -346.89
  AND `position_y` BETWEEN -2342.71 AND -2342.69;
