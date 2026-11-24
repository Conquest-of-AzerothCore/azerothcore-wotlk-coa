-- #11964: restore the first-pass object position (row 6900974, 2026_09_16_00)
UPDATE `gameobject` SET `position_x` = 1815.2, `position_y` = -5200.05
WHERE `guid` = 6941323 AND `id` = 90530 AND `map` = 0
  AND `position_x` BETWEEN 1819.95 AND 1820.05
  AND `position_y` BETWEEN -5195.05 AND -5194.95
  AND `position_z` BETWEEN 148.90 AND 149.00;
