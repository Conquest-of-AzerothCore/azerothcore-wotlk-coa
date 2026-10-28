-- Worldforged Venture Co. Boots (Barrens, guid 6942379) stands at the realm-map terrain fallback,
-- 19.8 yd below the Abandonedorcgreathall.wmo tower floor the reporter says it is in ("in a box in
-- the tower"). Move it onto the tower's upper floor near the LootCollector pin (#9299).
UPDATE `gameobject` SET `position_x` = 1349.0, `position_y` = -3648.0, `position_z` = 111.642
WHERE `guid` = 6942379 AND `id` = 1345156 AND `map` = 1
  AND `position_x` BETWEEN 1341.3 AND 1342.3 AND `position_y` BETWEEN -3660.3 AND -3659.3
  AND ABS(`position_z` - 91.799) < 0.01;
