-- #11968: restore the first-pass object position (row 6901011, 2026_09_16_00)
UPDATE `gameobject` SET `position_x` = 3257.9, `position_y` = -3368.8
WHERE `guid` = 6940416 AND `id` = 90618 AND `map` = 0
  AND `position_x` BETWEEN 3266.65 AND 3266.75
  AND `position_y` BETWEEN -3374.25 AND -3374.15
  AND `position_z` BETWEEN 145.50 AND 145.60;
