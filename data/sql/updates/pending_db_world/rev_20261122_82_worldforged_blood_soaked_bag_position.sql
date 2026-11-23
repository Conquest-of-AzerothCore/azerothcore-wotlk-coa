-- #11969: restore the first-pass object position (row 6900233, 2026_09_16_00)
UPDATE `gameobject` SET `position_x` = -11103.0, `position_y` = -2454.68
WHERE `guid` = 6940145 AND `id` = 254496 AND `map` = 0
  AND `position_x` BETWEEN -11100.45 AND -11100.35
  AND `position_y` BETWEEN -2451.55 AND -2451.45
  AND `position_z` BETWEEN 116.75 AND 116.85;
