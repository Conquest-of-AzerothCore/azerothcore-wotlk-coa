-- #12619: Worldforged pickup guid 6942009: the pickup floated 1.2 yd above the ground beside the stone table; restore
-- the first-pass x/y (row 6900073, 2026_09_16_00), where the same height rests on the table
UPDATE `gameobject` SET `position_x` = -359.033, `position_y` = 2486.326, `position_z` = 76.92
WHERE `guid` = 6942009 AND `id` = 254283 AND `map` = 1
  AND `position_x` BETWEEN -361.15 AND -361.05
  AND `position_y` BETWEEN 2481.65 AND 2481.75
  AND `position_z` BETWEEN 76.87 AND 76.97;
