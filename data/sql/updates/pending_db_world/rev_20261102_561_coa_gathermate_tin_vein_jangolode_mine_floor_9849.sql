-- Tin Vein 12006694 (Jangolode Mine) hung at z 45.88 against the ceiling; the mine floor under it is z 39.01 (#9849).
UPDATE `gameobject` SET `position_z` = 39.0087
WHERE `guid` = 12006694 AND `id` = 1732 AND `map` = 0
  AND `position_x` BETWEEN -9929.60 AND -9929.58 AND `position_y` BETWEEN 1448.44 AND 1448.46
  AND ABS(`position_z` - 45.88) < 0.01;
