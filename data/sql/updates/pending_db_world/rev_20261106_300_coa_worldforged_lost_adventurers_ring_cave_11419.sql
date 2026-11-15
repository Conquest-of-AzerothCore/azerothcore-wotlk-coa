-- Worldforged Lost Adventurer's Ring (pickup 6940718, Coldridge Valley troll cave) floated 1.27 yd above the floor
-- the server measures at its x/y (#11419).
-- Move it to the reporter's position in the cave, where the server measures the floor at z 382.20.
UPDATE `gameobject` SET `position_x` = -6521.28, `position_y` = 303.625, `position_z` = 382.2
WHERE `guid` = 6940718 AND `id` = 95502 AND `map` = 0
  AND `position_x` BETWEEN -6519.81 AND -6519.79
  AND `position_y` BETWEEN 305.09 AND 305.11
  AND `position_z` BETWEEN 382.838 AND 382.858;
