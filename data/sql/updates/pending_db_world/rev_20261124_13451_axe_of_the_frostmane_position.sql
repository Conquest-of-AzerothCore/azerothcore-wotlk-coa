-- #13451: the Axe of the Frostmane floated 1.53 yd above the Frostmane Hold floor at a single-record map pin.
-- Restore first-pass row 6901034 (2026_09_16_00, the realm dump spot) with its height.
UPDATE `gameobject` SET `position_x` = -5584.57, `position_y` = 745.622, `position_z` = 394.065
WHERE `guid` = 6940511 AND `id` = 95514 AND `map` = 0
  AND `position_x` BETWEEN -5584.250 AND -5584.150 AND `position_y` BETWEEN 727.050 AND 727.150 AND `position_z` BETWEEN 392.043 AND 392.143;
