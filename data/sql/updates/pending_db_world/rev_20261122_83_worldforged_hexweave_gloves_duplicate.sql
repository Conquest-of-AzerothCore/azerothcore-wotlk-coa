-- #12149: remove the coarse duplicate pin of the Hexweave Gloves pickup, keep 6970045
DELETE FROM `gameobject`
WHERE `guid` = 6970044 AND `id` = 9900039 AND `map` = 1
  AND `position_x` BETWEEN -7866.1 AND -7865.1
  AND `position_y` BETWEEN -1501.95 AND -1500.95;
