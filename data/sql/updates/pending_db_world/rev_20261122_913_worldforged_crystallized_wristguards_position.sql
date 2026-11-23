-- #12408: Worldforged pickup guid 6940284: the pickup stood high on an unreachable hillside; restore the first-pass
-- position (row 6901180, 2026_09_16_00), measured on the ground
UPDATE `gameobject` SET `position_x` = -13333.104, `position_y` = -428.459, `position_z` = 18.122
WHERE `guid` = 6940284 AND `id` = 95757 AND `map` = 0
  AND `position_x` BETWEEN -13380.15 AND -13380.05
  AND `position_y` BETWEEN -395.85 AND -395.75
  AND `position_z` BETWEEN 62.785 AND 62.885;
