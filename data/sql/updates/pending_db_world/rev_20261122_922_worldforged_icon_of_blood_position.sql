-- #12743: Worldforged pickup guid 6940640: the pickup stood inside a pillar; restore the first-pass position (row
-- 6900146, 2026_09_16_00), measured on the ground
UPDATE `gameobject` SET `position_x` = -10630.305, `position_y` = -3839.508, `position_z` = 24.471
WHERE `guid` = 6940640 AND `id` = 254370 AND `map` = 0
  AND `position_x` BETWEEN -10627.45 AND -10627.35
  AND `position_y` BETWEEN -3844.15 AND -3844.05
  AND `position_z` BETWEEN 23.507 AND 23.607;
