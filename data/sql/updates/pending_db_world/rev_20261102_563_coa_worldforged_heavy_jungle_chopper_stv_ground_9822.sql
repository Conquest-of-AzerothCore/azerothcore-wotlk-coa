-- Heavy Jungle Chopper pickup (guid 6940671, Stranglethorn) was 1.26 yd under the ground (#9822).
UPDATE `gameobject` SET `position_z` = 32.357
WHERE `guid` = 6940671 AND `id` = 95743 AND `map` = 0
  AND `position_x` BETWEEN -11678.51 AND -11678.49 AND `position_y` BETWEEN -651.01 AND -650.99
  AND ABS(`position_z` - 31.098) < 0.01;
