-- #13039: remove the duplicate Stolen Belt on top of Dreadmaul Rock, keep 6941146 in the lower cavern (first-pass row
-- 6900301)
DELETE FROM `gameobject`
WHERE `guid` = 6940943 AND `id` = 254648 AND `map` = 0
  AND `position_x` BETWEEN -7928.950 AND -7928.850
  AND `position_y` BETWEEN -2609.250 AND -2609.150;
