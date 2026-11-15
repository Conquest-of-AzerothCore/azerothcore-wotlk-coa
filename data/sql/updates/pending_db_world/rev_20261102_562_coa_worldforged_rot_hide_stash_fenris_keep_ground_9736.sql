-- Rot Hide Stash (guid 6942550, Fenris Keep) was 2.4 yd under the walkable surface at its spot (#9736).
UPDATE `gameobject` SET `position_z` = 61.6614
WHERE `guid` = 6942550 AND `id` = 90313 AND `map` = 0
  AND `position_x` BETWEEN 992.92 AND 992.94 AND `position_y` BETWEEN 692.13 AND 692.15
  AND ABS(`position_z` - 59.264) < 0.01;
