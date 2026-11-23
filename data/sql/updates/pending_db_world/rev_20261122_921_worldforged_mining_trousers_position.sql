-- #12735: Worldforged pickup guid 6940695: the pickup stood on the hill above Azurelode Mine instead of inside it;
-- restore the first-pass position (row 6900407, 2026_09_16_00), measured on the mine floor
UPDATE `gameobject` SET `position_x` = -826.527, `position_y` = 156.338, `position_z` = 17.519
WHERE `guid` = 6940695 AND `id` = 515376 AND `map` = 0
  AND `position_x` BETWEEN -804.75 AND -804.65
  AND `position_y` BETWEEN 166.75 AND 166.85
  AND `position_z` BETWEEN 55.542 AND 55.642;
