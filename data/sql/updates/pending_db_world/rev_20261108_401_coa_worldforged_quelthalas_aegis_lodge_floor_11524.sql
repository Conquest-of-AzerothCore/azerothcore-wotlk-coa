-- Worldforged Quel'thalas Commander Aegis (pickup 6940920, Quel'Lithien Lodge, Eastern Plaguelands) stood at the
-- terrain height 156.189, 2.64 yd under the Lodge floor model (#11524). The floor at its x/y measures 159.12.
UPDATE `gameobject` SET `position_z` = 159.12
WHERE `guid` = 6940920 AND `id` = 90531 AND `map` = 0
  AND `position_x` BETWEEN 3329.7 AND 3329.9 AND `position_y` BETWEEN -4226.4 AND -4226.2
  AND `position_z` BETWEEN 156.1 AND 156.3;
