-- #13121: remove the duplicate Partially Digested Corpse down the hill, keep 6940866 by the slimes (first-pass row
-- 6901200)
DELETE FROM `gameobject`
WHERE `guid` = 6941101 AND `id` = 95788 AND `map` = 0
  AND `position_x` BETWEEN 443.950 AND 444.050
  AND `position_y` BETWEEN -3650.550 AND -3650.450;
